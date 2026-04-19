#!/bin/bash
# work-items-generate-runner.sh
# Consolidates all mechanical artifact-generation steps for sweep:work-items
# into a single auto-approved bash invocation, avoiding per-command permission
# prompts when the LLM orchestrates a sweep.
#
# Usage:
#   bash ~/.claude/skill-references/work-items-generate-runner.sh <RUN_DIR>
#
# Required inputs in <RUN_DIR> before invocation (LLM writes these via Write tool):
#   manifest.json        — sweep manifest with .eligible[] entries
#                          each entry needs at minimum: number, role
#                          role is one of: clarify | confirm | implement
#   metadata.json        — runner config (MODE, MODE_LABEL, MODEL, RUN_DIR,
#                          CONCURRENCY, PRS, TIMESTAMP, BRANCHES, WORKTREES,
#                          PROJECT_ROOT) per sweep-scaffold.md
#   repo-summary.txt     — shared repo context (~50 lines)
#   issue-<N>/metadata.json — per-issue template metadata (one file per
#                              eligible issue, written by the LLM during
#                              assessment with persona, watermark, etc.)
#
# Outputs (overwritten on each run — re-runnable):
#   preflight.md         — copy of sweep-agent-preflight.md
#   issue-<N>/body.txt
#   issue-<N>/comments.txt
#   issue-<N>/prompt.txt
#   let-it-rip.sh        — assembled + patched for issue semantics

set -euo pipefail

RUN_DIR="${1:?Usage: work-items-generate-runner.sh <RUN_DIR>}"

[ -d "$RUN_DIR" ] || { echo "ERROR: run dir not found: $RUN_DIR" >&2; exit 1; }
[ -f "$RUN_DIR/manifest.json" ] || { echo "ERROR: manifest.json missing in $RUN_DIR" >&2; exit 1; }
[ -f "$RUN_DIR/metadata.json" ] || { echo "ERROR: runner metadata.json missing in $RUN_DIR" >&2; exit 1; }
[ -f "$RUN_DIR/repo-summary.txt" ] || { echo "ERROR: repo-summary.txt missing in $RUN_DIR" >&2; exit 1; }

SKILL_REFS="$HOME/.claude/skill-references"
WORK_ITEMS_DIR="$HOME/.claude/commands/sweep/work-items"

# Template lookup by role
template_for_role() {
    case "$1" in
        clarify) echo "$WORK_ITEMS_DIR/clarifier-prompt.md" ;;
        confirm|clarify-confirm) echo "$WORK_ITEMS_DIR/confirmer-prompt.md" ;;
        implement) echo "$WORK_ITEMS_DIR/implementer-prompt.md" ;;
        *) echo "ERROR: unknown role: $1" >&2; exit 1 ;;
    esac
}

# 1. Copy preflight
cp "$SKILL_REFS/sweep-agent-preflight.md" "$RUN_DIR/preflight.md"

# 2. For each eligible issue: fetch body/comments, assemble prompt
issues_processed=0
while IFS=$'\t' read -r number role; do
    issue_dir="$RUN_DIR/issue-$number"
    [ -d "$issue_dir" ] || mkdir -p "$issue_dir"
    [ -f "$issue_dir/metadata.json" ] || {
        echo "ERROR: $issue_dir/metadata.json missing — write it before invoking this script" >&2
        exit 1
    }

    gh issue view "$number" --json body --jq '.body' > "$issue_dir/body.txt"
    gh issue view "$number" --json comments --jq \
        '.comments[] | "=== Comment \(.id) by \(.author.login) at \(.createdAt) ===\n\n\(.body)\n"' \
        > "$issue_dir/comments.txt"

    template=$(template_for_role "$role")
    bash "$SKILL_REFS/fill-template.sh" "$template" "$issue_dir" > "$issue_dir/prompt.txt"

    issues_processed=$((issues_processed + 1))
    printf "  issue %s (%s) — body=%s lines, comments=%s lines, prompt=%s lines\n" \
        "$number" "$role" \
        "$(wc -l < "$issue_dir/body.txt")" \
        "$(wc -l < "$issue_dir/comments.txt")" \
        "$(wc -l < "$issue_dir/prompt.txt")"
done < <(jq -r '.eligible[] | [.number, .role] | @tsv' "$RUN_DIR/manifest.json")

# 3. Augment runner metadata with IMPLEMENT_ISSUES + PROJECT_ROOT, then assemble
#    via the dedicated work-items runner template (no sed-patching needed).
#
# IMPLEMENT_ISSUES: subset of eligible issues with role=implement. The runner
#   uses this to set up worktrees + cd into them before launching claude -p.
#
# PROJECT_ROOT: where to run `git worktree add` from. Defaults to git toplevel.
implement_issues=$(jq -r '[.eligible[] | select(.role == "implement") | .number] | join(" ")' "$RUN_DIR/manifest.json")
project_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Patch runner metadata.json in place — preserve existing fields, add/update
# IMPLEMENT_ISSUES and PROJECT_ROOT. Idempotent across reruns.
tmp_meta=$(mktemp)
jq --arg impl "$implement_issues" --arg root "$project_root" \
    '. + {IMPLEMENT_ISSUES: $impl, PROJECT_ROOT: (.PROJECT_ROOT // "" | if . == "" then $root else . end)}' \
    "$RUN_DIR/metadata.json" > "$tmp_meta"
mv "$tmp_meta" "$RUN_DIR/metadata.json"

# Assemble runner from the work-items-specific template
OUT="$RUN_DIR/let-it-rip.sh"
bash "$SKILL_REFS/fill-template.sh" \
    "$SKILL_REFS/work-items-runner-template.sh" \
    "$RUN_DIR" > "$OUT"
chmod +x "$OUT"

implementer_count=$(echo "$implement_issues" | wc -w | tr -d ' ')

echo ""
echo "Generated artifacts in $RUN_DIR:"
echo "  preflight.md          — copy of sweep-agent-preflight.md"
echo "  issue-<N>/body.txt    — $issues_processed files"
echo "  issue-<N>/comments.txt — $issues_processed files"
echo "  issue-<N>/prompt.txt  — $issues_processed files"
echo "  let-it-rip.sh         — $(wc -l < "$OUT") lines (work-items native template)"
echo "  metadata.json         — IMPLEMENT_ISSUES=\"$implement_issues\" ($implementer_count implementer(s))"
echo "                          PROJECT_ROOT=\"$project_root\""
echo ""
echo "To launch:"
echo "  bash $OUT"
