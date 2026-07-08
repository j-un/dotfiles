---
description: Investigate and fix CI failures on the current branch
allowed-tools: Bash(gh run:*), Bash(gh pr checks:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git log:*), Bash(git push:*)
argument-hint: "[run id or PR number (omit to use the current branch's latest runs)]"
---

Investigate the CI failure and fix the root cause. Argument (may be empty): $ARGUMENTS

1. **Locate the failing run**
   - If `$ARGUMENTS` is a run id, use it directly. If it is a PR number, run `gh pr checks <number>` to find failing checks.
   - Otherwise: get the current branch with `git branch --show-current`, then `gh run list --branch <branch> --limit 10` and pick the most recent failed run. If everything is green, report that and stop.
2. **Get the failure logs**
   - `gh run view <run-id> --log-failed` — read only the failed steps' logs.
   - Identify the root cause (test failure, lint error, build error, flaky infra). Distinguish "code is wrong" from "CI config/environment is wrong".
3. **Fix locally**
   - Reproduce the failure locally when possible (run the same test/lint/build command) before and after the fix.
   - Keep the fix minimal and targeted at the root cause — do not disable tests, skip checks, or loosen lint rules to make CI pass.
4. **Verify and push**
   - Re-run the reproducing command locally to confirm the fix.
   - Commit (Conventional Commits, English) and push to the same branch.
   - Watch the new run with `gh run watch` or poll `gh run list --branch <branch> --limit 1` until it completes, and report the final status.
5. **If the failure is flaky/external** (network, runner outage): report the evidence instead of changing code, and re-run with `gh run rerun <run-id> --failed`.
