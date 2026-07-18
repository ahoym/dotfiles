#!/bin/bash
# epic-advance-generate-runner.sh
# Consolidates runner assembly for /sweep:epic-advance into a single
# auto-approved bash invocation, mirroring sweep-prs-generate-runner.sh and
# work-items-generate-runner.sh. Avoids a per-step permission prompt when the
# LLM orchestrates an epic dispatch.
#
# Dependencies: fill-template.sh, epic-advance-runner-template.sh
#
# Usage:
#   bash ~/.claude/skill-references/epic-advance-generate-runner.sh \
#       <RUN_DIR> <EPIC_KEY> <ISO_TS> <ALWAYS_CLARIFY> <CONVERGE>
#
# Args (epic-advance passes the flag values directly — unlike the sibling
# wrappers, whose LLM writes metadata.json before invocation):
#   RUN_DIR        — epic-advance run dir (already holds manifest.json + per-item dirs)
#   EPIC_KEY       — e.g. PROJ-101
#   ISO_TS         — run start timestamp (ISO 8601), baked into the runner header
#   ALWAYS_CLARIFY — literal "true"/"false" (from --always-clarify; default false)
#   CONVERGE       — literal "true"/"false" (from --converge/--no-converge; default true)
#
# Required inputs in <RUN_DIR> before invocation (LLM writes these via Write tool):
#   manifest.json  — tranche structure + active[] per epic-advance Phase 7
#   <TICKET_KEY>/  — per-item dirs with metadata.json + status.md
#
# Outputs (overwritten on each run — re-runnable):
#   metadata.json  — runner substitutions (EPIC_KEY, ISO_TS, ALWAYS_CLARIFY, CONVERGE)
#   let-it-rip.sh  — assembled runner (chmod +x, bash -n validated)

set -euo pipefail

USAGE="Usage: epic-advance-generate-runner.sh <RUN_DIR> <EPIC_KEY> <ISO_TS> <ALWAYS_CLARIFY> <CONVERGE>"
RUN_DIR="${1:?$USAGE}"
EPIC_KEY="${2:?$USAGE}"
ISO_TS="${3:?$USAGE}"
ALWAYS_CLARIFY="${4:?$USAGE}"
CONVERGE="${5:?$USAGE}"

[ -d "$RUN_DIR" ] || { echo "ERROR: run dir not found: $RUN_DIR" >&2; exit 1; }
[ -f "$RUN_DIR/manifest.json" ] || { echo "ERROR: manifest.json missing in $RUN_DIR" >&2; exit 1; }

SKILL_REFS="$HOME/.claude/skill-references"

# 1. Materialize the runner substitutions into metadata.json (consumed by
#    fill-template.sh's double-brace substitution).
jq -n \
    --arg epic "$EPIC_KEY" \
    --arg ts "$ISO_TS" \
    --arg clarify "$ALWAYS_CLARIFY" \
    --arg converge "$CONVERGE" \
    '{EPIC_KEY: $epic, ISO_TS: $ts, ALWAYS_CLARIFY: $clarify, CONVERGE: $converge}' \
    > "$RUN_DIR/metadata.json"

# 2. Assemble the runner from the epic-advance template
OUT="$RUN_DIR/let-it-rip.sh"
bash "$SKILL_REFS/fill-template.sh" \
    "$SKILL_REFS/epic-advance-runner-template.sh" \
    "$RUN_DIR" > "$OUT"
chmod +x "$OUT"

# 3. Validate syntax — catches placeholder leaks and template assembly bugs early.
SYNTAX_ERR="$RUN_DIR/.syntax-err"
if ! bash -n "$OUT" 2>"$SYNTAX_ERR"; then
    echo "ERROR: generated runner failed bash -n syntax check:" >&2
    cat "$SYNTAX_ERR" >&2
    exit 1
fi
rm -f "$SYNTAX_ERR"

echo ""
echo "Generated runner in $RUN_DIR:"
echo "  metadata.json  — EPIC_KEY=$EPIC_KEY CONVERGE=$CONVERGE ALWAYS_CLARIFY=$ALWAYS_CLARIFY"
echo "  let-it-rip.sh  — $(wc -l < "$OUT") lines"
echo ""
echo "To preview:  bash $OUT --dry-run"
echo "To launch:   bash $OUT"
