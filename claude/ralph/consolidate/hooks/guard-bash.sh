#!/bin/bash
# PreToolUse hook: selective git command allowlist for consolidation loops.
# Usage: guard-bash.sh <worktree_root>
#
# Allows specific git commands scoped to .claude/ within the worktree.
# All non-git and non-whitelisted commands are blocked.
# Exit 0 = allow, Exit 2 + stderr = block

WORKTREE_ROOT="$1"
if [ -z "$WORKTREE_ROOT" ]; then
  echo "BLOCKED: No worktree root specified for bash guard" >&2
  exit 2
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  echo "BLOCKED: Empty command" >&2
  exit 2
fi

# Strip leading whitespace
COMMAND=$(echo "$COMMAND" | sed 's/^[[:space:]]*//')

# Block compound commands — no &&, ||, ;, or | allowed
if echo "$COMMAND" | grep -qE '&&|\|\||;|\|'; then
  echo "BLOCKED: Compound commands not permitted — one git command per Bash call" >&2
  exit 2
fi

ALLOWED_PREFIX="$WORKTREE_ROOT/.claude/"

case "$COMMAND" in
  git\ rm\ *)
    # Extract path argument(s) — skip flags starting with -
    for arg in ${COMMAND#git rm }; do
      case "$arg" in
        -*) continue ;;
        *)
          case "$arg" in
            "$ALLOWED_PREFIX"*) ;;
            *)
              echo "BLOCKED: git rm path outside allowed scope: $arg (allowed: $ALLOWED_PREFIX)" >&2
              exit 2
              ;;
          esac
          ;;
      esac
    done
    exit 0
    ;;
  git\ add\ *)
    for arg in ${COMMAND#git add }; do
      case "$arg" in
        -*) continue ;;
        *)
          case "$arg" in
            "$ALLOWED_PREFIX"*) ;;
            *)
              echo "BLOCKED: git add path outside allowed scope: $arg (allowed: $ALLOWED_PREFIX)" >&2
              exit 2
              ;;
          esac
          ;;
      esac
    done
    exit 0
    ;;
  git\ mv\ *)
    # Both source and destination must be in .claude/
    PATHS=()
    for arg in ${COMMAND#git mv }; do
      case "$arg" in
        -*) continue ;;
        *) PATHS+=("$arg") ;;
      esac
    done
    for path in "${PATHS[@]}"; do
      case "$path" in
        "$ALLOWED_PREFIX"*) ;;
        *)
          echo "BLOCKED: git mv path outside allowed scope: $path (allowed: $ALLOWED_PREFIX)" >&2
          exit 2
          ;;
      esac
    done
    exit 0
    ;;
  git\ commit\ *|git\ commit)
    exit 0
    ;;
  git\ status|git\ status\ *)
    exit 0
    ;;
  git\ diff|git\ diff\ *)
    exit 0
    ;;
  *)
    echo "BLOCKED: Command not in consolidation allowlist: $COMMAND" >&2
    echo "Allowed: git rm, git add, git mv, git commit, git status, git diff (scoped to .claude/)" >&2
    exit 2
    ;;
esac
