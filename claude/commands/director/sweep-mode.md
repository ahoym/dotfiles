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
3. Compute timestamp via separate `Bash` call: `date +%Y-%m-%d-%H%M`.
4. Bootstrap the session directory + initial files via the helper:
   ```bash
   bash ~/.claude/skill-references/director-bootstrap.sh <timestamp>
   ```
   Creates `tmp/claude-artifacts/director-sessions/<timestamp>/` with:
   - `session.json` — append-only item-centric index. Indexed by item (`pr-69`, `issue-56`), not by run. Each item maps to an ordered list of run_dirs. Append-only — never update or remove entries. To check status: read the last run_dir's `<item-dir>/status.md`.
   - `decisions.md` — append-only decision log per the playbook's Decision Framework, seeded with a `# Director Decisions — <timestamp>` header.

   The helper validates the timestamp format and atomic-creates the dir (fails loudly on a parallel-invocation race).

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

- **Conflicts** (routine — auto-decide): conflict resolution is handled inline by the addresser when `RESOLVE_CONFLICTS=true`. On `mergeable: CONFLICTING`, regenerate the address artifacts with `RESOLVE_CONFLICTS: "true"` in the PR's `metadata.json`, then re-assemble the prompt via `fill-template.sh`. Only regenerate when no address session is in-flight for the PR (`status.md` milestone != `addressing`/`pushing`); if one is running, write a directive for the next cycle instead of regenerating mid-flight. The addresser checks for conflicts at runtime — its Step 6 invokes `git:resolve-conflicts` before addressing comments, so rebase + address completes in a single `claude -p` run and no conflict state goes in metadata. Do not ask operator. Do not rebase yourself.
- **Compound auto-relaunch**: after every runner completion, run this decision tree automatically — do not prompt the operator unless escalation is needed. Offset cadence follows `~/.claude/skill-references/director-playbook.md`'s Loop Setup — event-driven is the standard; the 3-min offset is the cron-scheduled legacy fallback.
  - Address runner completes → read review `results.md` for last cycle's findings. Findings > 0 this cycle → relaunch review runner to verify resolution. All findings resolved (or review already converged) → check address convergence rules.
  - Review runner completes → read `results.md`. New findings posted (inline comments > 0 or thread replies > 0) → relaunch address runner. Review skipped or 0 findings → review loop is converging; start the 30m skip window.

## Convergence (sweep-specific)

- **Review loop**: converged when all sessions skip for 30m wall-clock. Auto-cancel after 30m all-skip.
- **Address loop**: converged when all PRs terminal (MERGED/CLOSED). Not converged while any open PR exists.
- **Never merge PRs.** Merging is the operator's review checkpoint.
