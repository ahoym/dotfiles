#!/bin/bash
# PreToolUse hook: blanket block for Task (subagent) tool.
# Subagents inherit --dangerously-skip-permissions but bypass PreToolUse hooks,
# breaking the security boundary established by other consolidation guards.
#
# Exit 2 + stderr = block
echo "BLOCKED: Task tool not permitted in unattended consolidation loops" >&2
exit 2
