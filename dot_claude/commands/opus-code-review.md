---
description: Run code review using the Opus 4.7 subagent
allowed-tools: Bash(git diff:*), Bash(git merge-base:*), Bash(git rev-parse:*), Agent
argument-hint: "[file path or scope (omit to review the whole branch diff from its base)]"
---

Delegate the following review to @opus-reviewer.

Explicit review target argument (may be empty): $ARGUMENTS

If `$ARGUMENTS` is non-empty, forward it as-is to @opus-reviewer without running any git commands.

If `$ARGUMENTS` is empty, compute the branch-base diff yourself using separate Bash tool calls (do NOT use `$(...)` command substitution), then pass the resulting diff to @opus-reviewer:

1. Determine the merge base: run `git merge-base HEAD @{u}` first. If it exits with an error (no upstream configured), run `git merge-base HEAD main` as a fallback.
2. Run `git diff <base>...HEAD` with the merge-base commit from step 1. This captures WIP commits and working-tree changes since the branch diverged.
3. Pass the full diff text to @opus-reviewer as the review target.
