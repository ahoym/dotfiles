#!/bin/bash
# gh-issues-fetch-state.sh
# Fetch current state, updatedAt, and latest-comment metadata for one or more
# GitHub issues. Designed for sweep:work-items watermark comparison.
#
# Usage:
#   bash ~/.claude/skill-references/gh-issues-fetch-state.sh <N> [<N> ...]
#
# Output: one JSON block per issue, separated by `===issue-<N>===` headers.
# Fields per issue:
#   state                 — OPEN / CLOSED
#   updatedAt             — issue updatedAt timestamp
#   last_comment_id       — latest comment node ID (null if none)
#   last_comment_author   — latest comment author login (null if none)
#   last_comment_body     — full body of latest comment (null if none)
#                           — caller inspects for `*Role:* Sweeper` /
#                             `*Role:* Sweeper-Confirm` to derive conversation stage

set -u

if [ $# -eq 0 ]; then
    echo "Usage: gh-issues-fetch-state.sh <N> [<N> ...]" >&2
    exit 1
fi

for n in "$@"; do
    printf '===issue-%s===\n' "$n"
    gh issue view "$n" --json state,updatedAt,comments --jq '{
        state,
        updatedAt,
        last_comment_id: (.comments[-1].id // null),
        last_comment_author: (.comments[-1].author.login // null),
        last_comment_body: (.comments[-1].body // null)
    }' 2>/dev/null || printf '{"error":"fetch failed for #%s"}\n' "$n"
done
