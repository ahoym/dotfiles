# Director — Custom Mode

Loaded when CWD is not a git repo, when `$ARGUMENTS` contains `custom`, or when an existing manifest with `"waves"` is detected. Handles multi-repo features, plan-driven orchestration, and any non-sweep parallel work.

**Reference (lazy — read in their phases):** worktree setup, wave gating, permission pre-flight, and prompt quality patterns live in the director sub-cluster (`~/.claude/learnings/claude-code/multi-agent/director/runner-design.md` covers permissions + worktree setup; `observability.md` covers session monitoring; `failure-modes.md` covers retry/recovery). The bootstrap eager-loads only the sub-cluster index (`director/CLAUDE.md`); sub-cluster files are read on-demand when their domain surfaces below.

## Bootstrap (custom-specific)

1. **Locate or create the plan.** Look for:
   - Existing `manifest.json` in CWD or a path from `$ARGUMENTS`
   - An implementation plan (`.md` files with work items, parallelization maps, dependency graphs)
   - If neither: ask the operator what to orchestrate

2. **Identify repos.** Multi-repo features declare repos in the manifest. Single-repo custom work uses CWD or a specified path. Verify each repo exists and is a git repo:
   ```json
   "repos": {
     "service-a": "/path/to/service-a-repo",
     "dashboard": "/path/to/dashboard-repo"
   }
   ```

3. **Create session directory.** Compute timestamp, create at `tmp/claude-artifacts/director-sessions/<timestamp>/`. Initialize `session.json` and `decisions.md`.

4. **Read `~/.claude/skill-references/artifact-contract.md`** for the standard directory structure.

## Assess + Generate Artifacts (custom-specific)

The director builds the orchestration artifacts directly (unlike sweep mode which delegates to sweep skills). This is the correct pattern for custom orchestration — there's no generic "custom-work skill" to invoke.

### Manifest

Generate `manifest.json` following the artifact contract, extended with wave dependencies:

```json
{
  "created_at": "<ISO>",
  "run_dir": "<session_dir>",
  "source_skill": "manual-director",
  "concurrency": 5,
  "repos": { ... },
  "waves": [
    { "id": "wave-1", "items": ["1a", "2a", "3b"] },
    { "id": "wave-2", "items": ["1b", "1c", "2b"] }
  ],
  "items": [
    { "id": "1a", "label": "SDK client beans", "repo": "lms", "branch": "feat/ab-1a-sdk-beans", "base": "main", "mr_target": "main" }
  ]
}
```

### Item directories

For each item, create `item-<id>/` with a `prompt.md` (not `prompt.txt` — custom prompts are authored, not generated from templates).

### Prompt quality

Each prompt should include:
- **Persona** — "You are a senior [tech stack] engineer" with domain context
- **"Read existing code first"** — forces pattern matching before writing
- **Scope** — explicit about what to build and what NOT to build
- **Tests required** — specific test class names and scenario lists
- **Quality bar** — 3-4 bullets on what good looks like
- **Full agency** — "keep what's good, rewrite what's not"
- **After implementation** — compile/lint, commit message, push + MR creation with proper description

### Runner script

Generate `let-it-rip.sh` with wave-based execution. Read these sub-cluster files when entering this phase:
- Worktree setup (`git worktree add ... >&2`, settings symlink, `mise trust`) — `~/.claude/learnings/claude-code/multi-agent/director/runner-design.md` (worktree-related sections: "Worktree Creation From Checked-Out Branch", "Stale Branch Blocks Worktree Creation on Relaunch", "Worktree EXIT Trap Destroys Uncommitted Implementer Work")
- Agent launch with `mise exec --` when `mise.toml` present — `~/.claude/learnings/claude-code/multi-agent/coordination.md` § "Mise Exec Wrap"
- Wave gating via `kill -0` polling (not `wait` — subshell PIDs aren't waitable) — pattern lives in the runner template itself; see also `~/.claude/learnings/claude-code/multi-agent/parallel-plans.md` for wave-pattern context
- Heartbeat monitoring via worktree `git status` mtime — `~/.claude/learnings/claude-code/multi-agent/director/observability.md` (output-format buffering sections)

**Skip completed items** by checking `item-<id>/status.md` for `milestone: completed`.

### Permissions audit

Before launching, verify each repo's `.claude/settings.local.json` has: `Edit`/`Write`, build commands (`yarn *`, `mvn *`, etc.), git commit/push, MR creation (`glab mr*` or `gh pr*`). Read `~/.claude/learnings/claude-code/multi-agent/director/runner-design.md` § "Permissions for Sweep Sessions" and § "`claude -p` Skill Tool Requires Scoped Permission" for the full checklist when entering this phase. Surface missing permissions to the operator before launch.

## Launch (uses shared Phase 3)

Launch `let-it-rip.sh` via `Bash(run_in_background: true)`. The runner handles wave gating internally.

## Monitor additions (custom-specific)

- **Wave completion**: runner logs wave transitions. On runner completion, read all `item-*/state.md` for the unified view.
- **Errored items**: items with `state: errored` + `escalation: needs-director` need investigation. Read `live.md` and `output.log`. Common causes: permission denial, worktree setup failure, inactivity timeout on long-running agents.
- **Re-run failed items**: clear `state.md` and `status.md` for the item, then re-launch with a targeted script. Don't re-run the full runner for 1-2 failures.

## Convergence (custom-specific)

- **Converged**: all items `state: completed` with MRs created.
- **Partial**: some items completed, others errored. Present status table, offer targeted re-run.
- **2c pattern**: some items can only run after earlier items are merged to main. These are declared as later waves and noted in the manifest. Convergence for these requires operator action (merge upstream MRs) before re-run.
