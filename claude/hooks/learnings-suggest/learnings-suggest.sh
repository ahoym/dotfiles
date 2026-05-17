#!/bin/bash
# UserPromptSubmit wrapper: dispatches to the platform-appropriate prebuilt binary.
# Silent no-op on unsupported platforms or missing binary — never blocks a prompt.

DIR="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)   BIN="$DIR/bin/learnings-suggest-aarch64-darwin" ;;
  Darwin-x86_64)  BIN="$DIR/bin/learnings-suggest-x86_64-darwin" ;;
  Linux-x86_64)   BIN="$DIR/bin/learnings-suggest-x86_64-linux-gnu" ;;
  Linux-aarch64)  BIN="$DIR/bin/learnings-suggest-aarch64-linux-gnu" ;;
  *)              exit 0 ;;
esac

[ -x "$BIN" ] && exec "$BIN"
exit 0
