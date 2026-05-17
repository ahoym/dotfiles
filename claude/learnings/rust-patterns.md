Rust patterns and tooling gotchas for Claude-config hooks and other small Rust binaries.
- **Keywords:** rust, cargo, lib.rs, multi-binary crate, cross-compile, rustup, brew, cargo-zigbuild, manifest-path, schema-version
- **Related:** ~/.claude/learnings/bash-patterns.md

---

## Multi-Binary Crates Need `src/lib.rs` for Shared Resolution

When a Cargo workspace has multiple binaries that share data-source resolution (e.g., `main.rs` and `index-build.rs` both parsing the same config file), extract the shared logic to `src/lib.rs`. Without it, each `main()` duplicates the loader and the two implementations drift silently — one branch parses an optional field, the other forgets, and the asymmetry is invisible until a downstream feature (here: section-level vs file-level indexing) only fires for one binary.

**Signature for branching behavior:** expose a single function with an explicit flag (`providers(include_project_local: bool)`) over duplicating the loader. Each call site declares its intent at the call, not in a hidden copy.

## `brew install rust` Is Not `rustup`

The Homebrew `rust` formula ships a single toolchain with no `rustup` proxy. `rustup target add x86_64-unknown-linux-gnu` fails with `command not found` (not a target-missing error). Cross-compile paths require:

```bash
brew uninstall rust
brew install rustup
rustup default stable
rustup target add x86_64-unknown-linux-gnu
brew install zig    # cargo-zigbuild's linker
cargo install cargo-zigbuild
```

Bootstrap scripts that assume `rustup` is installed will fail at the first `rustup` invocation on a freshly-brewed-`rust` machine. If cross-build matters, document `brew install rustup` (not `rust`) as the install path.

## `cargo --manifest-path` Wants the File, Not the Directory

```bash
# Fails: "error: could not find `Cargo.toml`"
cargo zigbuild --manifest-path crates/foo/

# Works
cargo zigbuild --manifest-path crates/foo/Cargo.toml
```

Common slip when scripting builds across multiple crates in a workspace.
