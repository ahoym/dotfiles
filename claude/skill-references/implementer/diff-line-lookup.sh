#!/bin/bash
# Map diff lines to file:line:content for line number verification
# Usage: bash diff-line-lookup.sh <mr_number> [search_token]
#   Without search_token: prints all new lines as file:line: content
#   With search_token: filters to lines containing the token
#
# Used by review agents to verify inline comment line numbers against actual diff content.
# The newLine parameter in GitLab's createDiffNote must match file line numbers exactly.
#
# Examples:
#   bash diff-line-lookup.sh 73                    # all lines
#   bash diff-line-lookup.sh 73 "String reserved"  # find specific code
#   bash diff-line-lookup.sh 73 "@JsonNaming"      # find annotation line
#
# Platform: works with both glab (GitLab) and gh (GitHub) — auto-detects.

set -e

MR="${1:?Usage: diff-line-lookup.sh <mr_number> [search_token]}"
TOKEN="${2:-}"

# Auto-detect platform
if command -v glab >/dev/null 2>&1 && [ -f .gitlab-ci.yml ]; then
    DIFF_CMD="glab mr diff $MR"
elif command -v gh >/dev/null 2>&1; then
    DIFF_CMD="gh pr diff $MR"
else
    echo "Neither glab nor gh found" >&2
    exit 1
fi

$DIFF_CMD 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        "--- "*)  ;;
        "+++ "*)  current_file="${line#+++ }" ;;
        "@@"*)
            new_start=$(echo "$line" | sed 's/.*+\([0-9]*\).*/\1/')
            current_line=$((new_start - 1))
            ;;
        "+"*)
            current_line=$((current_line + 1))
            content="${line#+}"
            if [ -z "$TOKEN" ]; then
                echo "$current_file:$current_line: $content"
            else
                case "$content" in
                    *"$TOKEN"*) echo "$current_file:$current_line: $content" ;;
                esac
            fi
            ;;
        "-"*) ;;
        *)
            current_line=$((current_line + 1))
            ;;
    esac
done
