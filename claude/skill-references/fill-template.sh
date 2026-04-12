#!/bin/bash
# fill-template.sh — Assemble prompts/scripts from templates + data files
# No AI involved — pure string substitution.
#
# Usage: fill-template.sh <template> <data-dir> > output
#
# Template syntax (two brace styles — use single for prose, double for shell):
#   {KEY}          — replaced with value from <data-dir>/metadata.json
#   {{KEY}}        — same, but double-brace (avoids collision with shell ${var})
#   {@filename}    — replaced with contents of <data-dir>/filename
#                    Paths are relative to data-dir (e.g., {@../repo-summary.txt})
#   {{#KEY}}       — block conditional open (must be on its own line)
#   {{/KEY}}       — block conditional close (must be on its own line)
#                    Block is kept when KEY is non-empty in metadata, stripped otherwise.
#
# Brace style is auto-detected per template: if the template contains any
# {{KEY}} patterns (double-brace), single-brace substitution is skipped to
# avoid corrupting shell ${var} references. Prompt/markdown templates use
# single-brace only; shell script templates use double-brace only.
#
# Security: Templates are trusted input — {@...} paths resolve without
# boundary checks (e.g., {@../../anything} is valid). Only use with
# templates you control.
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
NEXT=$(mktemp)
trap 'rm -f "$WORK" "$KV" "$NEXT"' EXIT

cp "$TEMPLATE" "$WORK"

# --- Generate KV pairs early (used by multiple phases) ---
jq -r 'to_entries[] | select(.value != null) | "\(.key)\t\(.value | tostring)"' "$METADATA" > "$KV"

# --- Phase 1: Block conditionals {{#KEY}}...{{/KEY}} ---
# Runs FIRST so stripped blocks don't trigger file-not-found warnings
# from {@file} inclusions inside dead blocks.
awk -F'\t' '
NR == FNR {
    vals[$1] = $2
    next
}
{
    if (match($0, /^[[:space:]]*\{\{#[^}]+\}\}[[:space:]]*$/)) {
        tag = $0
        gsub(/^[[:space:]]*\{\{#/, "", tag)
        gsub(/\}\}[[:space:]]*$/, "", tag)
        in_block = 1
        keep = (tag in vals && vals[tag] != "")
        next
    }
    if (match($0, /^[[:space:]]*\{\{\/[^}]+\}\}[[:space:]]*$/)) {
        in_block = 0
        next
    }
    if (in_block && !keep) next
    print
}
' "$KV" "$WORK" > "$NEXT"
mv "$NEXT" "$WORK"

# --- Phase 2: Expand {@filename} inclusions (iterative) ---
# Each pass resolves one level of file inclusions. Iterates until
# no {@...} patterns remain or max depth is reached.
depth=0
max_depth=5
while grep -q '{@[^}]*}' "$WORK" && [ "$depth" -lt "$max_depth" ]; do
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
            # Check existence first — empty files should produce empty output,
            # not preserve the raw {@filename} placeholder
            exists = (system("test -f " filepath) == 0)
            if (!exists) {
                printf "{@%s}", filename  # preserve unresolvable refs
                printf "WARNING: file not found: %s\n", filepath > "/dev/stderr"
            } else {
                found = 0
                while ((getline fline < filepath) > 0) {
                    if (found) printf "\n"
                    printf "%s", fline
                    found = 1
                }
                close(filepath)
                if (found) printf "\n"
            }
            line = suffix
        }
        if (line != "" || NF == 0) print line
    }
    ' "$WORK" > "$NEXT"
    mv "$NEXT" "$WORK"
    depth=$((depth + 1))
done

# --- Phase 3: Substitute keys from metadata.json ---
# Auto-detect brace style: if the template uses {{KEY}} (double-brace),
# skip single-brace to avoid corrupting shell ${var} references.
if grep -q '{{[A-Z_][A-Z_0-9]*}}' "$WORK"; then
    # Double-brace mode (shell script templates)
    awk -F'\t' '
    NR == FNR {
        keys["{{" $1 "}}"] = $2
        next
    }
    {
        for (pat in keys) {
            out = ""
            rest = $0
            while ((i = index(rest, pat)) > 0) {
                out = out substr(rest, 1, i - 1) keys[pat]
                rest = substr(rest, i + length(pat))
            }
            $0 = out rest
        }
        print
    }
    ' "$KV" "$WORK"
else
    # Single-brace mode (prose/markdown templates)
    awk -F'\t' '
    NR == FNR {
        keys["{" $1 "}"] = $2
        next
    }
    {
        for (pat in keys) {
            out = ""
            rest = $0
            while ((i = index(rest, pat)) > 0) {
                out = out substr(rest, 1, i - 1) keys[pat]
                rest = substr(rest, i + length(pat))
            }
            $0 = out rest
        }
        print
    }
    ' "$KV" "$WORK"
fi
