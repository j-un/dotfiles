#!/usr/bin/env python3
"""Cursor CLI status line: one glanceable row, width-adaptive, fail-soft."""
from __future__ import annotations

import json
import os
import re
import sqlite3
import subprocess
import sys
import time
import unicodedata
import urllib.error
import urllib.request
from hashlib import sha1
from typing import Any

RESET = "\033[0m"
DIM = "\033[2m"
BOLD = "\033[1m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
MAGENTA = "\033[35m"
WHITE = "\033[37m"
SEP = f"{DIM} · {RESET}"
ANSI_RE = re.compile(r"\033\[[0-9;]*m")
GIT_TIMEOUT_S = 0.12
GIT_CACHE_TTL_S = 1.2
USAGE_CACHE = "/tmp/cursor-sl-usage.json"
USAGE_LOCK = "/tmp/cursor-sl-usage.lock"
USAGE_TTL_S = 300
USAGE_STALE_S = 3600
USAGE_LOCK_STALE_S = 45
USAGE_URL = "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage"
EXCHANGE_URL = "https://api2.cursor.sh/auth/exchange_user_api_key"


def paint(code: str, text: str) -> str:
    return f"{code}{text}{RESET}"


def vis_len(s: str) -> int:
    n = 0
    for ch in ANSI_RE.sub("", s):
        n += 2 if unicodedata.east_asian_width(ch) in ("F", "W") else 1
    return n


def truncate(s: str, budget: int) -> str:
    if budget <= 0:
        return ""
    if vis_len(s) <= budget:
        return s
    out: list[str] = []
    width = 0
    i = 0
    budget -= 1
    while i < len(s) and width < budget:
        if s[i] == "\033":
            m = ANSI_RE.match(s, i)
            if m:
                out.append(m.group(0))
                i = m.end()
                continue
        ch = s[i]
        w = 2 if unicodedata.east_asian_width(ch) in ("F", "W") else 1
        if width + w > budget:
            break
        out.append(ch)
        width += w
        i += 1
    out.append("…")
    out.append(RESET)
    return "".join(out)


def _git_cache_path(cwd: str) -> str:
    h = sha1(os.path.abspath(cwd).encode()).hexdigest()[:16]
    return f"/tmp/cursor-sl-git-{h}"


def _load_git_cache(cwd: str) -> dict[str, Any] | None:
    try:
        with open(_git_cache_path(cwd), encoding="utf-8") as f:
            data = json.load(f)
        if time.time() - float(data.get("t", 0)) <= GIT_CACHE_TTL_S:
            return data
    except (OSError, json.JSONDecodeError, TypeError, ValueError):
        return None
    return None


def _store_git_cache(cwd: str, data: dict[str, Any]) -> None:
    path = _git_cache_path(cwd)
    tmp = f"{path}.{os.getpid()}"
    try:
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump({"t": time.time(), **data}, f)
        os.replace(tmp, path)
    except OSError:
        try:
            os.unlink(tmp)
        except OSError:
            pass


def git_root(cwd: str) -> str | None:
    """Return git root, ignoring a parent ~/ repo unless cwd itself is ~."""
    cur = os.path.abspath(cwd)
    home = os.path.abspath(os.path.expanduser("~"))
    while True:
        git_path = os.path.join(cur, ".git")
        if os.path.isdir(git_path) or os.path.isfile(git_path):
            if cur == home and os.path.abspath(cwd) != home:
                return None
            return cur
        parent = os.path.dirname(cur)
        if parent == cur:
            return None
        cur = parent


def git_info(cwd: str) -> dict[str, Any] | None:
    cached = _load_git_cache(cwd)
    if cached is not None:
        return cached if cached.get("ok") else None
    if not cwd or not os.path.isdir(cwd) or git_root(cwd) is None:
        return None
    env = os.environ.copy()
    env["GIT_OPTIONAL_LOCKS"] = "1"
    env["GIT_TERMINAL_PROMPT"] = "0"
    try:
        proc = subprocess.run(
            ["git", "-C", cwd, "status", "--porcelain=v1", "-uno", "-b"],
            capture_output=True,
            text=True,
            timeout=GIT_TIMEOUT_S,
            env=env,
        )
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        _store_git_cache(cwd, {"ok": False})
        return None
    if proc.returncode != 0 or not proc.stdout:
        _store_git_cache(cwd, {"ok": False})
        return None
    lines = proc.stdout.splitlines()
    header = lines[0] if lines else ""
    dirty = any(ln and not ln.startswith("##") for ln in lines)
    branch = ""
    if header.startswith("## "):
        rest = header[3:]
        if rest.startswith("HEAD"):
            branch = "detached"
        elif rest.startswith("No commits yet on "):
            branch = rest[len("No commits yet on ") :].split("...")[0].strip()
        else:
            branch = rest.split("...")[0].strip()
    ahead = behind = 0
    m = re.search(r"ahead (\d+)", header)
    if m:
        ahead = int(m.group(1))
    m = re.search(r"behind (\d+)", header)
    if m:
        behind = int(m.group(1))
    info = {
        "ok": True,
        "branch": branch,
        "dirty": dirty,
        "ahead": ahead,
        "behind": behind,
    }
    _store_git_cache(cwd, info)
    return info


def _home() -> str:
    return os.path.expanduser("~")


def _read_json_file(path: str) -> dict[str, Any] | None:
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else None
    except (OSError, json.JSONDecodeError, TypeError):
        return None


def _keychain_secret(service: str) -> str | None:
    try:
        proc = subprocess.run(
            [
                "security",
                "find-generic-password",
                "-s",
                service,
                "-a",
                "cursor-user",
                "-w",
            ],
            capture_output=True,
            text=True,
            timeout=2.0,
        )
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return None
    if proc.returncode != 0:
        return None
    secret = proc.stdout.strip()
    return secret or None


def _sqlite_auth_token() -> str | None:
    db = os.path.join(
        _home(),
        "Library",
        "Application Support",
        "Cursor",
        "User",
        "globalStorage",
        "state.vscdb",
    )
    if not os.path.isfile(db):
        return None
    try:
        conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True, timeout=0.2)
        try:
            row = conn.execute(
                "SELECT value FROM ItemTable WHERE key = ?",
                ("cursorAuth/accessToken",),
            ).fetchone()
        finally:
            conn.close()
    except sqlite3.Error:
        return None
    if not row:
        return None
    val = str(row[0]).strip()
    return val or None


def _auth_file_tokens() -> tuple[str | None, str | None]:
    for path in (
        os.path.join(_home(), ".cursor", "auth.json"),
        os.path.join(_home(), ".config", "cursor", "auth.json"),
    ):
        data = _read_json_file(path)
        if not data:
            continue
        access = str(data.get("accessToken") or "").strip() or None
        api_key = str(data.get("apiKey") or "").strip() or None
        if access or api_key:
            return access, api_key
    return None, None


def _exchange_api_key(api_key: str) -> str | None:
    req = urllib.request.Request(
        EXCHANGE_URL,
        data=b"{}",
        method="POST",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            body = json.loads(resp.read().decode("utf-8"))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, ValueError):
        return None
    token = str((body or {}).get("accessToken") or "").strip()
    return token or None


def load_access_token() -> str | None:
    env = (
        os.environ.get("CURSOR_ACCESS_TOKEN")
        or os.environ.get("CURSOR_SESSION_TOKEN")
        or ""
    ).strip()
    if env:
        return env
    access, api_key = _auth_file_tokens()
    if access:
        return access
    kc = _keychain_secret("cursor-access-token")
    if kc:
        return kc
    sqlite_tok = _sqlite_auth_token()
    if sqlite_tok:
        return sqlite_tok
    env_key = (os.environ.get("CURSOR_API_KEY") or "").strip()
    key = api_key or env_key or _keychain_secret("cursor-api-key")
    if key:
        return _exchange_api_key(key)
    return None


def _dig(data: Any, *keys: str) -> Any:
    cur = data
    for key in keys:
        if not isinstance(cur, dict) or key not in cur:
            return None
        cur = cur[key]
    return cur


def extract_cursor_models_pct(payload: Any) -> float | None:
    """Spending page 'Cursor Models' bar = autoPercentUsed."""
    if not isinstance(payload, dict):
        return None
    candidates = (
        _dig(payload, "planUsage", "autoPercentUsed"),
        _dig(payload, "plan_usage", "auto_percent_used"),
        _dig(payload, "individualUsage", "plan", "autoPercentUsed"),
        _dig(payload, "individual_usage", "plan", "auto_percent_used"),
        payload.get("autoPercentUsed"),
    )
    for raw in candidates:
        if raw is None:
            continue
        try:
            val = float(raw)
        except (TypeError, ValueError):
            continue
        if val == val and abs(val) != float("inf"):
            return val
    return None


def fetch_cursor_models_pct() -> float | None:
    token = load_access_token()
    if not token:
        return None
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Connect-Protocol-Version": "1",
    }

    def _post() -> Any:
        req = urllib.request.Request(USAGE_URL, data=b"{}", method="POST", headers=headers)
        with urllib.request.urlopen(req, timeout=8) as resp:
            return json.loads(resp.read().decode("utf-8"))

    try:
        body = _post()
    except urllib.error.HTTPError as exc:
        if exc.code != 401:
            return None
        _access, api_key = _auth_file_tokens()
        key = (
            api_key
            or (os.environ.get("CURSOR_API_KEY") or "").strip()
            or _keychain_secret("cursor-api-key")
        )
        if not key:
            return None
        token = _exchange_api_key(key)
        if not token:
            return None
        headers["Authorization"] = f"Bearer {token}"
        try:
            body = _post()
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, ValueError):
            return None
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, ValueError):
        return None
    return extract_cursor_models_pct(body)


def _usage_lock_fresh() -> bool:
    try:
        age = time.time() - os.stat(USAGE_LOCK).st_mtime
    except OSError:
        return False
    return age < USAGE_LOCK_STALE_S


def _try_lock_refresh() -> bool:
    try:
        fd = os.open(USAGE_LOCK, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        os.close(fd)
        return True
    except FileExistsError:
        if _usage_lock_fresh():
            return False
        try:
            os.unlink(USAGE_LOCK)
            fd = os.open(USAGE_LOCK, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
            os.close(fd)
            return True
        except OSError:
            return False


def kick_usage_refresh() -> None:
    if not _try_lock_refresh():
        return
    try:
        subprocess.Popen(
            [sys.executable, os.path.abspath(__file__), "--refresh-usage"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError:
        try:
            os.unlink(USAGE_LOCK)
        except OSError:
            pass


def write_usage_cache(pct: float | None) -> None:
    tmp = f"{USAGE_CACHE}.{os.getpid()}"
    try:
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump({"t": time.time(), "pct": pct}, f)
        os.replace(tmp, USAGE_CACHE)
    except OSError:
        try:
            os.unlink(tmp)
        except OSError:
            pass


def refresh_usage_cache() -> int:
    try:
        pct = fetch_cursor_models_pct()
        write_usage_cache(pct)
        return 0 if pct is not None else 1
    finally:
        try:
            os.unlink(USAGE_LOCK)
        except OSError:
            pass


def cursor_models_pct() -> float | None:
    cached = _read_json_file(USAGE_CACHE)
    now = time.time()
    age = None
    has_pct = False
    pct: float | None = None
    if cached is not None:
        try:
            age = now - float(cached.get("t", 0))
        except (TypeError, ValueError):
            age = None
        if "pct" in cached:
            has_pct = True
            raw = cached["pct"]
            if raw is not None:
                try:
                    pct = float(raw)
                except (TypeError, ValueError):
                    pct = None
                    has_pct = False
    if age is not None and age <= USAGE_TTL_S and has_pct:
        return pct
    kick_usage_refresh()
    if age is not None and age <= USAGE_STALE_S:
        return pct
    return None


_GENERIC_DIRS = frozenset(
    {"src", "lib", "app", "cmd", "internal", "pkg", "packages", "bin", "testdata"}
)


def short_path(cwd: str) -> str:
    home = os.path.abspath(os.path.expanduser("~"))
    abs_cwd = os.path.abspath(cwd)
    if abs_cwd == home:
        return "~"
    parts = [p for p in abs_cwd.split(os.sep) if p]
    base = parts[-1] if parts else abs_cwd
    if base.lower() in _GENERIC_DIRS and len(parts) >= 2:
        return parts[-2] + "/" + base
    if abs_cwd.count(os.sep) == 1:
        return abs_cwd
    if abs_cwd.startswith(home + os.sep):
        rel = abs_cwd[len(home) + 1 :]
        if os.sep not in rel:
            return "~/" + rel
    return base


def model_name(model: dict[str, Any]) -> str:
    name = str(model.get("display_name") or model.get("id") or "model")
    if name.startswith("Cursor ") and len(name) > 7:
        name = name[7:]
    return name


def model_params(model: dict[str, Any]) -> str:
    params = str(model.get("param_summary") or "").strip()
    if params.startswith("(") and params.endswith(")"):
        params = params[1:-1]
    return params


def short_model(name: str) -> str:
    parts = name.split()
    if len(parts) >= 2 and parts[1][:1].isdigit():
        return parts[0] + " " + parts[1]
    return parts[0] if parts else name


def ctx_color(pct: float) -> str:
    if pct >= 85:
        return RED
    if pct >= 60:
        return YELLOW
    return GREEN


def ctx_bar(pct: float, width: int) -> str:
    width = max(4, width)
    filled = int(round(max(0.0, min(100.0, pct)) * width / 100.0))
    filled = min(width, filled)
    return ("█" * filled) + ("░" * (width - filled))


def join(parts: list[str]) -> str:
    return SEP.join(p for p in parts if p)


def render(payload: dict[str, Any]) -> str:
    width = max(20, int(payload.get("render_width_chars") or 80))

    model = payload.get("model") or {}
    name = model_name(model)
    params = model_params(model)
    if params and params.lower() in name.lower():
        params = ""
    max_mode = bool(model.get("max_mode"))
    cwd = (
        (payload.get("workspace") or {}).get("current_dir")
        or payload.get("cwd")
        or ""
    )
    worktree = payload.get("worktree") or {}
    wt_name = worktree.get("name") if isinstance(worktree, dict) else None
    session = payload.get("session_name")
    autorun = bool(payload.get("autorun"))
    vim = payload.get("vim") or {}
    vim_mode = vim.get("mode") if isinstance(vim, dict) else None
    cw = payload.get("context_window") or {}
    try:
        pct = None if cw.get("used_percentage") is None else float(cw["used_percentage"])
    except (TypeError, ValueError):
        pct = None
    usage_pct = cursor_models_pct()

    loc = str(wt_name) if wt_name else (short_path(cwd) if cwd else "")
    git = git_info(cwd) if cwd else None

    git_txt = ""
    if git and git.get("branch"):
        g = str(git["branch"])
        if git.get("ahead"):
            g += f"↑{git['ahead']}"
        if git.get("behind"):
            g += f"↓{git['behind']}"
        if git.get("dirty"):
            g += "*"
            git_txt = paint(YELLOW, g)
        else:
            git_txt = paint(GREEN, g)

    flags: list[str] = []
    if max_mode:
        flags.append(paint(f"{BOLD}{YELLOW}", "MAX"))
    if vim_mode:
        short_vim = {"NORMAL": "NOR", "INSERT": "INS", "VISUAL": "VIS"}.get(
            str(vim_mode), str(vim_mode)[:3]
        )
        flags.append(paint(MAGENTA, short_vim))

    show_session = bool(session)
    show_params = bool(params)
    show_git = bool(git_txt)
    show_loc = bool(loc)
    show_bar = pct is not None
    show_usage = usage_pct is not None
    bar_w = 10
    loc_cap: int | None = None
    model_full = True

    def assemble() -> str:
        bits: list[str] = []
        if autorun:
            bits.append(paint(f"{BOLD}{RED}", "AUTO"))
        if show_session:
            bits.append(paint(DIM, str(session)))
        shown = name if model_full else short_model(name)
        model_s = paint(CYAN, shown)
        if show_params:
            model_s += " " + paint(DIM, params)
        bits.append(model_s)
        if show_loc:
            loc_s = loc if loc_cap is None else truncate(loc, loc_cap)
            bits.append(paint(WHITE, loc_s))
        if show_git:
            bits.append(git_txt)
        if pct is not None:
            color = ctx_color(pct)
            n = f"{pct:.0f}%"
            bits.append(paint(color, f"{ctx_bar(pct, bar_w)} {n}" if show_bar else n))
        if show_usage and usage_pct is not None:
            bits.append(paint(ctx_color(usage_pct), f"cm {int(usage_pct)}%"))
        if flags:
            bits.append(" ".join(flags))
        return join(bits)

    line = assemble()
    for drop in (
        "session",
        "params",
        "bar_shrink",
        "loc_shrink",
        "git",
        "loc",
        "usage",
        "bar_off",
        "model_short",
    ):
        if vis_len(line) <= width:
            break
        if drop == "session":
            show_session = False
        elif drop == "params":
            show_params = False
        elif drop == "bar_shrink":
            bar_w = 6
        elif drop == "loc_shrink":
            loc_cap = 16
        elif drop == "git":
            show_git = False
        elif drop == "loc":
            show_loc = False
        elif drop == "usage":
            show_usage = False
        elif drop == "bar_off":
            show_bar = False
        elif drop == "model_short":
            model_full = False
        line = assemble()

    if vis_len(line) > width:
        line = truncate(line, width)
    return line


def main() -> int:
    if "--refresh-usage" in sys.argv:
        return refresh_usage_cache()
    raw = sys.stdin.buffer.read()
    if not raw.strip():
        return 1
    try:
        payload = json.loads(raw.decode("utf-8"))
        if not isinstance(payload, dict):
            raise ValueError("payload")
        print(render(payload), end="")
        return 0
    except Exception:
        sys.stdout.write(f"{DIM}—{RESET}")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
