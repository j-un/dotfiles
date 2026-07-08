---
description: Run code review using the Opus 4.8 subagent
allowed-tools: Agent
argument-hint: "[file path or scope (omit to review the whole branch diff from its base)]"
---

Delegate the following review to @opus-reviewer. Do NOT compute any diff yourself — the subagent obtains its own review target so the parent context stays lean.

Explicit review target argument (may be empty): $ARGUMENTS

- If `$ARGUMENTS` is non-empty, forward it as-is to @opus-reviewer as the review target.
- If `$ARGUMENTS` is empty, instruct @opus-reviewer to review the current branch diff from its merge base (the agent knows how to compute it). Pass along the current working directory so it runs git in the right repo.

Relay the subagent's full review result back to the user verbatim.
