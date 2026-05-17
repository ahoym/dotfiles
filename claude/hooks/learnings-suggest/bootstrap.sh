#!/bin/bash
# Build the learnings-suggest binary for the current platform.
# Idempotent: re-runs skip when the existing binary is newer than every source file.
# Installs Rust if missing (brew on macOS, rustup elsewhere).
#
# Usage:
#   bootstrap.sh                  # build for current platform only
#   bootstrap.sh --all-targets    # cross-build all supported targets via cargo-zigbuild

set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$DIR/bin"
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS-$ARCH" in
  Darwin-arm64)   NATIVE=learnings-suggest-aarch64-darwin ;;
  Darwin-x86_64)  NATIVE=learnings-suggest-x86_64-darwin ;;
  Linux-x86_64)   NATIVE=learnings-suggest-x86_64-linux-gnu ;;
  Linux-aarch64)  NATIVE=learnings-suggest-aarch64-linux-gnu ;;
  *) echo "Unsupported platform: $OS-$ARCH — skipping hook build" >&2; exit 0 ;;
esac

mkdir -p "$BIN_DIR"

binary_fresh() {
  local bin="$1"
  [ -x "$bin" ] || return 1
  [ "$bin" -nt "$DIR/Cargo.toml" ] || return 1
  [ -z "$(find "$DIR/src" -type f -newer "$bin" -print -quit 2>/dev/null)" ] || return 1
  return 0
}

ensure_cargo() {
  command -v cargo >/dev/null 2>&1 && return 0
  echo "Installing Rust toolchain..."
  if [ "$OS" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
    brew install rust
  else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --default-toolchain stable --profile minimal
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
}

build_native() {
  local bin="$BIN_DIR/$NATIVE"
  if binary_fresh "$bin"; then
    echo "ok  $NATIVE (up to date)"
    return 0
  fi
  ensure_cargo
  echo "build $NATIVE"
  (cd "$DIR" && cargo build --release --quiet)
  cp "$DIR/target/release/learnings-suggest" "$bin"
  echo "ok  $NATIVE"
}

build_all_targets() {
  ensure_cargo
  command -v zig >/dev/null 2>&1 || {
    if [ "$OS" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
      brew install zig
    else
      echo "zig not found — install it manually for --all-targets" >&2
      exit 1
    fi
  }
  cargo install --quiet cargo-zigbuild || true

  local targets=(
    "aarch64-apple-darwin:learnings-suggest-aarch64-darwin"
    "x86_64-apple-darwin:learnings-suggest-x86_64-darwin"
    "x86_64-unknown-linux-gnu:learnings-suggest-x86_64-linux-gnu"
    "aarch64-unknown-linux-gnu:learnings-suggest-aarch64-linux-gnu"
  )
  for entry in "${targets[@]}"; do
    local triple="${entry%%:*}"
    local bin_name="${entry##*:}"
    local out="$BIN_DIR/$bin_name"
    if binary_fresh "$out"; then
      echo "ok  $bin_name (up to date)"
      continue
    fi
    rustup target add "$triple" >/dev/null 2>&1 || true
    echo "build $bin_name ($triple)"
    (cd "$DIR" && cargo zigbuild --release --target "$triple" --quiet)
    cp "$DIR/target/$triple/release/learnings-suggest" "$out"
    echo "ok  $bin_name"
  done
}

if [ "$1" = "--all-targets" ]; then
  build_all_targets
else
  build_native
fi
