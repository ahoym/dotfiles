#!/bin/bash
# PreToolUse hook: blanket Bash block for unattended ralph loops.
# Research loops don't need shell access — Claude has dedicated tools
# for everything a research loop does (Read, Write, Edit, Glob, Grep,
# WebFetch, WebSearch). Blocking Bash entirely eliminates the full class
# of prompt injection risks without any pattern-matching complexity.
#
# Exit 2 + stderr = block
echo "BLOCKED: Bash not permitted in unattended ralph loops" >&2
exit 2
