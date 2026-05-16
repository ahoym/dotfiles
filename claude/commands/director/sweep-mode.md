# Director — Sweep Mode

Loaded when mode is `review`, `address`, or `review+address`. Handles PR-based sweep orchestration.

## Additional Prerequisites

- `gh auth status` or `glab auth status` succeeds (platform-dependent)
- Current branch is `main` (standard path avoids worktree conflicts)

## Bootstrap (sweep-specific)

1. Parse `$ARGUMENTS` for:
   - **Mode**: `review`, `address`, `review+address`
   - **Passthrough flags**: `--prs=...` forwarded to subordinate skills
   - **Offset**: `--offset=N` minutes between review/address launches (default 3)
   - **Convergence**: if the operator requests "run to convergence" or "converge", read `convergence-loop.md` from this skill's directory and enter convergence loop mode after Phase 3 launch
2. **Load sweep playbook**: read `~/.claude/skill-references/director-playbook.md` for monitoring table format, convergence rules, intervention triggers, and offset cadence.
3. Compute timestamp via separate `Bash` call: `date +%Y-%m-%d-%H%M`. Create session directory at `tmp/claude-artifacts/director-sessions/<timestamp>/`.
4. Initialize `session.json` (append-only item-centric index):
   ```json
   { "created_at": "<ISO>", "session_dir": "<path>", "items": {} }
   ```
   Indexed by item (`pr-69`, `issue-56`), not by run. Each item maps to an ordered list of run_dirs. Append-only. To check status: read the last run_dir's `<item-dir>/status.md`.
5. Initialize `decisions.md` with header.

## Assess + Generate Artifacts (sweep-specific)

Invoke the corresponding skill via `Skill` tool:
- `review` → `skill="sweep:review-prs"`, `args="<passthrough>"`
- `address` → `skill="sweep:address-prs"`, `args="<passthrough>"`

After each skill completes, read its generated `manifest.json` to get the `run_dir` and eligible items. Append to `session.json`.

**Compound mode**: assess review first, launch review runner immediately (background), then assess address while review runs.

**Never hand-write runner scripts.** Always use `parallel-claude-runner-template.sh` with placeholder substitution. Hand-written scripts introduce variable scoping bugs.

**Always invoke sweep skills for assessment — never generate artifacts directly.** Sweep skills handle platform detection, skip filtering, persona discovery, and the full metadata schema.

## Launch additions (sweep-specific)

- **Compound mode** (review+address): review runner is already running. Wait for completion before launching address:
  - **All review PRs reach `posted`/`done`** → launch address (min 3-min offset for API propagation)
  - **Any review PR `errored`** → surface to operator
  - **Timeout 20 minutes** → launch address anyway

## Monitor additions (sweep-specific)

- **Conflicts** (routine — auto-decide): `mergeable: CONFLICTING` → write directive to addresser. Do not ask operator. Do not rebase yourself.
- **Compound auto-relaunch**: Address completes → relaunch review if findings > 0. Review completes → relaunch address if new comments posted. Maintain 3-min offset.
- **Conflict resolution**: regenerate address artifacts with `RESOLVE_CONFLICTS: "true"` when no session in-flight.

## Convergence (sweep-specific)

- **Review loop**: converged when all sessions skip for 30m wall-clock. Auto-cancel after 30m all-skip.
- **Address loop**: converged when all PRs terminal (MERGED/CLOSED). Not converged while any open PR exists.
- **Never merge PRs.** Merging is the operator's review checkpoint.
