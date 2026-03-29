#!/bin/bash
# PreToolUse hook: blanket block for WebFetch and WebSearch.
# Consolidation is local-only — no web access needed.
#
# Exit 2 + stderr = block
echo "BLOCKED: Web access not permitted in unattended consolidation loops" >&2
exit 2
