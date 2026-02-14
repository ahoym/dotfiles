#!/usr/bin/env bash
set -euo pipefail

CMD="${1:?Usage: file-io.sh <read|write|append|list> <relative-path>}"
shift

BASE="$HOME/.claude"

case "$CMD" in
  read)
    # read <relative-path>
    # Outputs file content to stdout
    FILE_PATH="${1:?Missing relative path}"
    cat "$BASE/$FILE_PATH"
    ;;

  write)
    # write <relative-path>
    # Reads content from stdin, writes to file (creating parent dirs)
    FILE_PATH="${1:?Missing relative path}"
    FULL_PATH="$BASE/$FILE_PATH"
    mkdir -p "$(dirname "$FULL_PATH")"
    cat > "$FULL_PATH"
    ;;

  append)
    # append <relative-path>
    # Reads content from stdin, appends to file (creating parent dirs if new)
    FILE_PATH="${1:?Missing relative path}"
    FULL_PATH="$BASE/$FILE_PATH"
    mkdir -p "$(dirname "$FULL_PATH")"
    cat >> "$FULL_PATH"
    ;;

  list)
    # list [<relative-dir>]
    # Lists files under ~/.claude/ or a subdirectory
    DIR_PATH="${1:-.}"
    find "$BASE/$DIR_PATH" -type f -name '*.md' 2>/dev/null | sed "s|$BASE/||" | sort
    ;;

  *)
    echo "Unknown command: $CMD" >&2
    echo "Usage: file-io.sh <read|write|append|list> <relative-path>" >&2
    exit 1
    ;;
esac
