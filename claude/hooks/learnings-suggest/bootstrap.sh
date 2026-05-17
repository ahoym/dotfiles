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

BINS=(learnings-suggest learnings-read-log learnings-index-build)

case "$OS-$ARCH" in
  Darwin-arm64)   SUFFIX=aarch64-darwin ;;
  Darwin-x86_64)  SUFFIX=x86_64-darwin ;;
  Linux-x86_64)   SUFFIX=x86_64-linux-gnu ;;
  Linux-aarch64)  SUFFIX=aarch64-linux-gnu ;;
  *) echo "Unsupported platform: $OS-$ARCH — skipping hook build" >&2; exit 0 ;;
esac

mkdir -p "$BIN_DIR"

any_stale() {
  # Returns 0 (true in bash) when any binary is missing or older than source/manifest/lockfile.
  # `|| return 0` short-circuits at the first stale condition; `return 1` only fires after
  # every binary passes every freshness check.
  local bin
  for b in "${BINS[@]}"; do
    bin="$BIN_DIR/$b-$1"
    [ -x "$bin" ] || return 0
    [ "$bin" -nt "$DIR/Cargo.toml" ] || return 0
    [ "$bin" -nt "$DIR/Cargo.lock" ] || return 0
    [ -z "$(find "$DIR/src" -type f -newer "$bin" -print -quit 2>/dev/null)" ] || return 0
  done
  return 1
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

stage_binaries() {
  # $1 = suffix, $2 = target release dir (defaults to target/release)
  local suffix="$1"
  local rel_dir="${2:-$DIR/target/release}"
  local b
  for b in "${BINS[@]}"; do
    cp "$rel_dir/$b" "$BIN_DIR/$b-$suffix"
    echo "ok  $b-$suffix"
  done
}

build_native() {
  if ! any_stale "$SUFFIX"; then
    echo "ok  binaries up to date ($SUFFIX)"
    return 0
  fi
  ensure_cargo
  echo "build $SUFFIX"
  (cd "$DIR" && cargo build --release --quiet)
  stage_binaries "$SUFFIX"
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
    "aarch64-apple-darwin:aarch64-darwin"
    "x86_64-apple-darwin:x86_64-darwin"
    "x86_64-unknown-linux-gnu:x86_64-linux-gnu"
    "aarch64-unknown-linux-gnu:aarch64-linux-gnu"
  )
  for entry in "${targets[@]}"; do
    local triple="${entry%%:*}"
    local suffix="${entry##*:}"
    if ! any_stale "$suffix"; then
      echo "ok  binaries up to date ($suffix)"
      continue
    fi
    rustup target add "$triple" >/dev/null 2>&1 || true
    echo "build $suffix ($triple)"
    (cd "$DIR" && cargo zigbuild --release --target "$triple" --quiet)
    stage_binaries "$suffix" "$DIR/target/$triple/release"
  done
}

if [ "$1" = "--all-targets" ]; then
  build_all_targets
else
  build_native
fi
