#!/usr/bin/env bash
# PostToolUse hook on ExitPlanMode: fires when a plan is approved.
# Injects a reminder to persist durable design decisions to GophDrive.
cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"Plan approved. If this plan settled a durable design decision (chosen approach, rejected alternatives, constraints), record it via the gophdrive-memory skill on your own judgment once execution starts - do not ask first, but mention the saved note title in one line. Skip anything recoverable from code or git history."}}
EOF
