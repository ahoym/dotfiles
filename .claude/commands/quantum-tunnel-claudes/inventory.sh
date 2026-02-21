#!/usr/bin/env bash
# quantum-tunnel-claudes inventory script
# Usage: inventory.sh <source> <target>
# Outputs structured inventory + classification + git history + diffs

set -euo pipefail

SOURCE="${1:?Usage: inventory.sh <source> <target>}"
TARGET="${2:?Usage: inventory.sh <source> <target>}"
EXCLUDES="personas/|lab/|worktrees/|settings\.json|settings\.local\.json|README\.md"

# Verify paths exist
[[ -d "$SOURCE" ]] || { echo "ERROR: Source not found: $SOURCE"; exit 1; }
[[ -d "$TARGET" ]] || { echo "ERROR: Target not found: $TARGET"; exit 1; }

# List files in each repo
src_files=$(cd "$SOURCE" && find .claude/commands .claude/guidelines .claude/learnings docs/claude-learnings -name '*.md' 2>/dev/null | grep -Ev "$EXCLUDES" | sort)
tgt_files=$(cd "$TARGET" && find .claude/commands .claude/guidelines .claude/learnings docs/claude-learnings -name '*.md' 2>/dev/null | grep -Ev "$EXCLUDES" | sort)

# Bucket files
only_source=$(comm -23 <(echo "$src_files") <(echo "$tgt_files"))
only_target=$(comm -13 <(echo "$src_files") <(echo "$tgt_files"))
comm -12 <(echo "$src_files") <(echo "$tgt_files") > /tmp/qtc-common.txt

echo "=== ONLY IN SOURCE ==="
echo "$only_source"
echo ""

echo "=== ONLY IN TARGET ==="
echo "$only_target"
echo ""

# Classify common files
echo "=== COMMON FILES CLASSIFICATION ==="
identical=0
while IFS= read -r f; do
  if diff -q "$SOURCE/$f" "$TARGET/$f" >/dev/null 2>&1; then
    identical=$((identical + 1))
  else
    s_only=$(diff "$TARGET/$f" "$SOURCE/$f" | grep -c '^> ' || true)
    t_only=$(diff "$TARGET/$f" "$SOURCE/$f" | grep -c '^< ' || true)
    if [[ "$s_only" -gt 0 && "$t_only" -eq 0 ]]; then
      echo "SUPERSET:source|$f|source +${s_only}"
    elif [[ "$s_only" -eq 0 && "$t_only" -gt 0 ]]; then
      echo "SUPERSET:target|$f|target +${t_only}"
    else
      echo "BOTH_UNIQUE|$f|source +${s_only}, target +${t_only}"
    fi
  fi
done < /tmp/qtc-common.txt

echo ""
echo "IDENTICAL: $identical"
echo "ONLY_SOURCE_COUNT: $(echo "$only_source" | grep -c '.' || true)"
echo "ONLY_TARGET_COUNT: $(echo "$only_target" | grep -c '.' || true)"

# Git history check for source-only files
echo ""
echo "=== GIT HISTORY CHECK ==="
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  hist=$(cd "$TARGET" && git log --all --oneline -- "$f" 2>/dev/null || true)
  if [[ -n "$hist" ]]; then
    echo "PREVIOUSLY_REMOVED: $f"
    echo "  $hist"
  else
    echo "GENUINELY_NEW: $f"
  fi
done <<< "$only_source"

# Extract source-unique content from BOTH_UNIQUE files
echo ""
echo "=== SOURCE-UNIQUE DIFFS ==="
while IFS= read -r f; do
  if ! diff -q "$SOURCE/$f" "$TARGET/$f" >/dev/null 2>&1; then
    s_only=$(diff "$TARGET/$f" "$SOURCE/$f" | grep -c '^> ' || true)
    t_only=$(diff "$TARGET/$f" "$SOURCE/$f" | grep -c '^< ' || true)
    if [[ "$s_only" -gt 0 ]]; then
      echo ""
      echo "--- $f (source +${s_only}, target +${t_only}) ---"
      diff "$TARGET/$f" "$SOURCE/$f" | grep '^> ' | head -30 || true
    fi
  fi
done < /tmp/qtc-common.txt

rm -f /tmp/qtc-common.txt
