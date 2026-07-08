---
description: Status report — concise summary of in-progress work (no changes made)
argument-hint: "[optional angle or question]"
---

Report the current status concisely, in Japanese. This invocation must NOT modify any files or run any non-read-only commands — status only.

Optional extra angle (may be empty): $ARGUMENTS

**Fresh session guard**: if this is called at the start of a session with no in-progress task in the conversation, do NOT fabricate one and do NOT go digging through git log or recent files to invent work. Reply with a single line — e.g. 「進行中のタスクはありません。何から始めますか?」 — and stop. The four-point report below is only for sessions where there is actual in-progress work to summarize.

Cover these four points as a short bulleted list:

1. **進行中のタスクと目的** — what you are working on and why
2. **完了 / 未完了** — what is done, what remains
3. **直近の変更点** — files touched or actions taken in this session
4. **次のステップとブロッカー** — planned next step and any blockers

Grounding rules:

- If a task list is active in this session, treat it as the source of truth for 完了 / 未完了 — do not re-derive from memory.
- If session details are fuzzy (e.g. right after compaction), you may run ONE quick read-only check (`git status` or `git diff --stat`) to ground 直近の変更点. Nothing beyond that.
- If several tasks were handled in this session, report the one currently in progress and compress the rest into a single line.

If an extra angle is provided, address it in one or two sentences at the end.

No preamble, no sign-off. Just the facts.
