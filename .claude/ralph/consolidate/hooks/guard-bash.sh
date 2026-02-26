#!/bin/bash
# PreToolUse hook: blanket Bash block for unattended consolidation loops.
# Consolidation is file-manipulation only — Claude has dedicated tools
# for everything it needs (Read, Write, Edit, Glob, Grep).
# Blocking Bash entirely eliminates prompt injection risks.
#
# Exit 2 + stderr = block
echo "BLOCKED: Bash not permitted in unattended consolidation loops" >&2
exit 2
