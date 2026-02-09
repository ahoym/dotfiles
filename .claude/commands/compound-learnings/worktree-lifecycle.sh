#!/usr/bin/env bash
set -euo pipefail

CMD="${1:?Usage: worktree-lifecycle.sh <create|attach|read|write|append|delete|commit|remove> ...}"
shift

case "$CMD" in
  create)
    # create <worktree-path> <branch-name>
    # Creates a new branch from origin/main in a worktree
    # Auto-removes stale worktree from a previous crashed run
    WORKTREE="${1:?Missing worktree path}"
    BRANCH="${2:?Missing branch name}"
    if [ -d "$WORKTREE" ]; then
      git worktree remove "$WORKTREE" --force 2>/dev/null || rm -rf "$WORKTREE"
    fi
    git worktree prune
    git branch -D "$BRANCH" 2>/dev/null || true
    git fetch origin main
    git worktree add -b "$BRANCH" "$WORKTREE" origin/main
    ;;

  attach)
    # attach <worktree-path> <branch-name>
    # Checks out an existing remote branch in a worktree
    # Auto-removes stale worktree from a previous crashed run
    WORKTREE="${1:?Missing worktree path}"
    BRANCH="${2:?Missing branch name}"
    if [ -d "$WORKTREE" ]; then
      git worktree remove "$WORKTREE" --force 2>/dev/null || rm -rf "$WORKTREE"
    fi
    git worktree prune
    git fetch origin "$BRANCH"
    git worktree add "$WORKTREE" "$BRANCH"
    ;;

  read)
    # read <worktree-path> <relative-file-path>
    # Outputs file content to stdout
    WORKTREE="${1:?Missing worktree path}"
    FILE_PATH="${2:?Missing file path}"
    cat "$WORKTREE/$FILE_PATH"
    ;;

  write)
    # write <worktree-path> <relative-file-path>
    # Reads content from stdin, writes to file (creating parent dirs)
    WORKTREE="${1:?Missing worktree path}"
    FILE_PATH="${2:?Missing file path}"
    FULL_PATH="$WORKTREE/$FILE_PATH"
    mkdir -p "$(dirname "$FULL_PATH")"
    cat > "$FULL_PATH"
    ;;

  append)
    # append <worktree-path> <relative-file-path>
    # Reads content from stdin, appends to file (creating parent dirs if new)
    WORKTREE="${1:?Missing worktree path}"
    FILE_PATH="${2:?Missing file path}"
    FULL_PATH="$WORKTREE/$FILE_PATH"
    mkdir -p "$(dirname "$FULL_PATH")"
    cat >> "$FULL_PATH"
    ;;

  delete)
    # delete <worktree-path> <relative-file-path> [<relative-file-path>...]
    # Removes files from the worktree (git rm)
    WORKTREE="${1:?Missing worktree path}"
    shift
    for FILE_PATH in "$@"; do
      git -C "$WORKTREE" rm -f "$FILE_PATH"
    done
    ;;

  commit)
    # commit <worktree-path> <message>
    # Stages all changes and commits
    WORKTREE="${1:?Missing worktree path}"
    MESSAGE="${2:?Missing commit message}"
    git -C "$WORKTREE" add -A
    git -C "$WORKTREE" commit -m "$MESSAGE"
    ;;

  remove)
    # remove <worktree-path>
    # Removes the worktree
    WORKTREE="${1:?Missing worktree path}"
    git worktree remove "$WORKTREE"
    ;;

  *)
    echo "Unknown command: $CMD" >&2
    echo "Usage: worktree-lifecycle.sh <create|attach|read|write|append|delete|commit|remove> ..." >&2
    exit 1
    ;;
esac
