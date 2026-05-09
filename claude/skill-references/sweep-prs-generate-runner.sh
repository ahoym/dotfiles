#!/bin/bash
# sweep-prs-generate-runner.sh
# Consolidates artifact-generation steps for sweep:review-prs and sweep:address-prs
# into a single auto-approved bash invocation, mirroring work-items-generate-runner.sh.
# Avoids per-command permission prompts when the LLM orchestrates a sweep.
#
# Dependencies: fill-template.sh, parallel-claude-runner-template.sh
#               commands/sweep/review-prs/reviewer-prompt.md   (mode=review)
#               commands/sweep/address-prs/addresser-prompt.md (mode=address)
#
# Usage:
#   bash ~/.claude/skill-references/sweep-prs-generate-runner.sh <RUN_DIR>
#
# Required inputs (LLM writes via Write tool before invocation):
#   manifest.json        — eligible[].number listing PRs to process
#   metadata.json        — runner config; MODE must be "review" or "address"
#                          plus the runner schema fields per sweep-scaffold.md
#   pr-<N>/metadata.json — per-PR template metadata (one file per eligible PR)
#
#   Address mode additionally requires:
#     branch-cases.txt        — case-statement body for branch_for() (template @-include)
#     worktree-cases.txt      — case-statement body for worktree_for() (template @-include)
#     new-worktree-items.txt  — space-separated PR numbers needing new worktrees
#
# Outputs (overwritten on each run — re-runnable):
#   pr-<N>/prompt.txt
#   let-it-rip.sh

set -euo pipefail

RUN_DIR="${1:?Usage: sweep-prs-generate-runner.sh <RUN_DIR>}"

[ -d "$RUN_DIR" ] || { echo "ERROR: run dir not found: $RUN_DIR" >&2; exit 1; }
[ -f "$RUN_DIR/manifest.json" ] || { echo "ERROR: manifest.json missing in $RUN_DIR" >&2; exit 1; }
[ -f "$RUN_DIR/metadata.json" ] || { echo "ERROR: runner metadata.json missing in $RUN_DIR" >&2; exit 1; }

SKILL_REFS="$HOME/.claude/skill-references"

# Derive mode + prompt template
MODE=$(jq -r '.MODE // empty' "$RUN_DIR/metadata.json")
case "$MODE" in
    review)
        prompt_template="$HOME/.claude/commands/sweep/review-prs/reviewer-prompt.md"
        ;;
    address)
        prompt_template="$HOME/.claude/commands/sweep/address-prs/addresser-prompt.md"
        # Address mode requires per-PR worktree case statements
        for f in branch-cases.txt worktree-cases.txt new-worktree-items.txt; do
            [ -f "$RUN_DIR/$f" ] || {
                echo "ERROR: address mode requires $RUN_DIR/$f — write it before invoking" >&2
                exit 1
            }
        done
        ;;
    *)
        echo "ERROR: metadata.json MODE must be 'review' or 'address', got '$MODE'" >&2
        exit 1
        ;;
esac

[ -f "$prompt_template" ] || { echo "ERROR: prompt template not found: $prompt_template" >&2; exit 1; }

# 1. For each eligible PR: assemble prompt
prs_processed=0
while IFS= read -r number; do
    pr_dir="$RUN_DIR/pr-$number"
    [ -d "$pr_dir" ] || { echo "ERROR: $pr_dir missing — run init-sweep-pr-dir.sh first" >&2; exit 1; }
    [ -f "$pr_dir/metadata.json" ] || {
        echo "ERROR: $pr_dir/metadata.json missing — write it before invoking this script" >&2
        exit 1
    }

    bash "$SKILL_REFS/fill-template.sh" "$prompt_template" "$pr_dir" > "$pr_dir/prompt.txt"

    prs_processed=$((prs_processed + 1))
    printf "  pr %s (%s) — prompt=%s lines\n" \
        "$number" "$MODE" \
        "$(wc -l < "$pr_dir/prompt.txt")"
done < <(jq -r '.eligible[].number' "$RUN_DIR/manifest.json")

# 2. Assemble runner from the generic parallel template
OUT="$RUN_DIR/let-it-rip.sh"
bash "$SKILL_REFS/fill-template.sh" \
    "$SKILL_REFS/parallel-claude-runner-template.sh" \
    "$RUN_DIR" > "$OUT"
chmod +x "$OUT"

# 3. Validate syntax — catches placeholder leaks and template assembly bugs early
if ! bash -n "$OUT" 2>/tmp/sweep-prs-syntax-err; then
    echo "ERROR: generated runner failed bash -n syntax check:" >&2
    cat /tmp/sweep-prs-syntax-err >&2
    rm -f /tmp/sweep-prs-syntax-err
    exit 1
fi
rm -f /tmp/sweep-prs-syntax-err

echo ""
echo "Generated artifacts in $RUN_DIR (mode=$MODE):"
echo "  pr-<N>/prompt.txt — $prs_processed files"
echo "  let-it-rip.sh     — $(wc -l < "$OUT") lines"
echo ""
echo "To launch:"
echo "  bash $OUT"
