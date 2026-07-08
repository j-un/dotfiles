---
description: Plan-first development with parallel implementer delegation (main model plans/reviews, Sonnet implements)
argument-hint: "<task description>"
---

Drive the following development task through the plan-first, delegated-implementation workflow. The main session (Fable/Opus) plans, orchestrates, reviews, and integrates — it does NOT write implementation code itself.

Task: $ARGUMENTS

## Phase 1 — Plan (in plan mode)

1. If not already in plan mode, call EnterPlanMode before doing anything else.
2. Explore the codebase as needed, then design an implementation plan with this structure:
   - Split the work into independent chunks wherever possible. Two chunks are independent only if they touch disjoint sets of files.
   - For each chunk, write a SELF-CONTAINED spec: purpose, target files, expected behavior, constraints, and the exact verification command(s). The spec must be executable by an agent that has no access to this conversation.
   - Declare dependencies explicitly: which chunks run in parallel, which must be serial.
   - Assign every chunk to the @implementer subagent, and record a model per chunk based on difficulty: `sonnet` (default) for routine, well-specified implementation; `opus` for complex algorithms, concurrency, subtle state, performance- or security-critical code, or chunks likely to need debugging judgment; `haiku` for trivial mechanical edits (renames, config tweaks). When in doubt between sonnet and opus, pick sonnet — the review step catches shortfalls and the chunk can be re-delegated to opus.
   - Escape hatch: if the task does not decompose into 2+ meaningful chunks, say so in the plan and propose direct implementation in the main session instead (still plan-first).
3. When presenting the plan, note that choosing auto-accept edits at the approval dialog keeps parallel agents from stalling on permission prompts.

## Phase 2 — Orchestrate (after approval)

1. Track chunks with the task list (TaskCreate / TaskUpdate).
2. Launch one @implementer per chunk, passing that chunk's full self-contained spec verbatim and setting the Agent tool's `model` parameter to the model recorded in the plan. Launch independent chunks in parallel in a single message; run dependent chunks serially. If parallel chunks could still collide in the working tree, use worktree isolation.
3. As each report returns, review the chunk's diff critically: correctness, spec compliance, and ~/.claude/TESTING.md adherence. For non-trivial fixes, send them back to the same agent via SendMessage instead of fixing in the main session.
4. If an agent escalates a design decision, decide it in the main session, update the spec, and re-delegate.

## Phase 3 — Integrate & verify

1. After all chunks land, run the project's full verification (build, tests, lint).
2. Review the combined diff for cross-chunk consistency, or suggest /opus-code-review for a deep pass.
3. Report to the user: what was built, per-chunk outcomes, verification results, and remaining follow-ups.

## Rules

- Keep the main context lean: do not read implementation files into the main session unless a review requires it — the implementer's report is the primary interface.
- Never let a subagent inherit the parent model implicitly; always use @implementer with an explicit model choice (its default is Sonnet). If a sonnet chunk comes back below the bar twice, re-delegate that chunk to opus rather than iterating a third time.
- Plan approval is a hard gate: no file modifications before the user approves the plan.
