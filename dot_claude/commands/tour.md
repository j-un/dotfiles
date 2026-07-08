---
description: Give a guided tour of the current project — what it is, how it's built, and how to work on it
argument-hint: "[optional focus area, e.g. 'auth flow' or 'build system']"
---

Give a concise guided tour of the current project so the user can start working on it. Respond in Japanese. Read-only investigation — do NOT modify any files.

Optional focus area (may be empty): $ARGUMENTS

## How to investigate (in this order, stop early once the picture is clear)

1. **README first** — README.md / README.rst / docs/index.* if present. This is usually the fastest source of truth for purpose and setup.
2. **Manifests** — package.json, go.mod, Cargo.toml, pyproject.toml, requirements.txt, Gemfile, etc. Read scripts, dependencies, and the toolchain version.
3. **Existing CLAUDE.md** — if the project has one, it is already auto-loaded into your context; do NOT re-read the file. Treat it as the maintainer's own summary and prioritize it over your inferences.
4. **Top-level layout** — one directory listing at the repo root; then descend only into directories that look load-bearing (src/, cmd/, app/, internal/, packages/, etc.).
5. **Entry points** — main.go / cmd/*, src/index.*, src/main.*, bin/*, or whatever the manifest points at. Skim the top of these files, don't read them fully.
6. **Config & CI** — .env.example, docker-compose.yml, Makefile, .github/workflows/*, deploy configs. Look for how it actually runs.
7. **Tests** — the test directory's shape (framework, structure) tells you a lot about conventions.
8. **Recent history** — `git log --oneline -15` (skip if not a git repo). Active areas, commit-message conventions, and cadence tell you what's alive and what's abandoned.

Sample, don't exhaustively read. If the repo is huge, prefer breadth over depth. If it is a monorepo/workspace, tour the root level and summarize each package in a line or two — descend into a package only when it is the focus area.

## Report format

Structure the tour as follows. Keep each section short — a few lines to a short paragraph. Omit sections that don't apply.

1. **これは何** — 1〜2文でプロジェクトの目的
2. **技術スタック** — 言語・主要フレームワーク・ランタイム/ツールチェーンのバージョン
3. **ディレクトリ構成** — 重要なディレクトリと役割(全部は列挙しない、load-bearing なものだけ)
4. **エントリポイント** — 実行がどこから始まるか、ファイルパス付き
5. **ビルド / 実行 / テスト** — 実際のコマンド(README や scripts から抜粋、推測しない)
6. **注目すべき慣習・パターン** — このプロジェクト独自のもの、または一般的でない選択
7. **依存関係・外部連携** — 外部サービス、API、DB、認証など
8. **最近の動き** — git log から見える活発な領域・開発の傾向(git リポジトリでなければ省略)
9. **気になった点** — 探索中に見つけた驚き・注意点・未解決の TODO など(なければ省略)

The whole tour should be readable in a minute or two. Depth belongs in follow-up questions, not the first report.

## When a focus area is provided

Give the general tour compressed, then expand the focus area with specifics: relevant files with paths, control flow, key functions.

## Guardrails

- Do not read entire files unless small; skim top/structure.
- Do not invent conventions from a single file — call it out as "1ファイルからの推測" if you must.
- If the repo looks like it's not actually a project (empty, just config files), say so and stop.
- No preamble like「調査します」— go straight to the report.
