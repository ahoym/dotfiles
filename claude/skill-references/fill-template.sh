#!/bin/bash
# fill-template.sh — Assemble prompts from templates + data files
# No AI involved — pure string substitution.
#
# Usage: fill-template.sh <template> <data-dir> > prompt.txt
#
# Template syntax:
#   {KEY}        — replaced with value from <data-dir>/metadata.json
#   {@filename}  — replaced with contents of <data-dir>/filename
#                  Paths are relative to data-dir (e.g., {@../repo-summary.txt})
#
# File inclusions are iterative: included files may contain further
# {@filename} references (e.g., a preflight file that includes {@body.txt}).
# Max depth: 5 passes.
#
# macOS bash 3.x compatible. Requires: jq, awk.

set -euo pipefail

TEMPLATE="${1:?Usage: fill-template.sh <template> <data-dir>}"
DATA_DIR="${2:?Usage: fill-template.sh <template> <data-dir>}"
METADATA="$DATA_DIR/metadata.json"

[ -f "$TEMPLATE" ] || { echo "ERROR: template not found: $TEMPLATE" >&2; exit 1; }
[ -f "$METADATA" ] || { echo "ERROR: metadata.json not found: $METADATA" >&2; exit 1; }

WORK=$(mktemp)
KV=$(mktemp)
trap 'rm -f "$WORK" "$KV"' EXIT

# --- Phase 1: Expand {@filename} inclusions (iterative) ---
# Each pass resolves one level of file inclusions. Iterates until
# no {@...} patterns remain or max depth is reached.
cp "$TEMPLATE" "$WORK"

depth=0
max_depth=5
while grep -q '{@[^}]*}' "$WORK" && [ "$depth" -lt "$max_depth" ]; do
    NEXT=$(mktemp)
    awk -v data_dir="$DATA_DIR" '
    {
        line = $0
        while (match(line, /\{@[^}]+\}/)) {
            ref = substr(line, RSTART, RLENGTH)
            filename = substr(ref, 3, length(ref) - 3)
            filepath = data_dir "/" filename
            prefix = substr(line, 1, RSTART - 1)
            suffix = substr(line, RSTART + RLENGTH)
            printf "%s", prefix
            found = 0
            while ((getline fline < filepath) > 0) {
                if (found) printf "\n"
                printf "%s", fline
                found = 1
            }
            close(filepath)
            if (!found) {
                printf "{@%s}", filename  # preserve unresolvable refs
                printf "WARNING: file not found: %s\n", filepath > "/dev/stderr"
            }
            if (found) printf "\n"
            line = suffix
        }
        if (line != "" || NF == 0) print line
    }
    ' "$WORK" > "$NEXT"
    mv "$NEXT" "$WORK"
    depth=$((depth + 1))
done

# --- Phase 2: Substitute {KEY} from metadata.json ---
jq -r 'to_entries[] | select(.value != null) | "\(.key)\t\(.value | tostring)"' "$METADATA" > "$KV"

awk -F'\t' '
NR == FNR {
    keys["{" $1 "}"] = $2
    next
}
{
    for (pat in keys) {
        while (index($0, pat) > 0) {
            i = index($0, pat)
            $0 = substr($0, 1, i - 1) keys[pat] substr($0, i + length(pat))
        }
    }
    print
}
' "$KV" "$WORK"
