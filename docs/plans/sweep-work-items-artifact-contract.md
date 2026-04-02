# Refactor sweep-work-items to Standard Artifact Contract

## Problem

`/sweep-work-items` uses the `Agent` tool directly for parallelism — spawning in-memory subagents that are invisible to the director. This means:
- No `live.md` observability during execution
- No directive channel for mid-session steering
- No kill + retry for hung agents
- Can't be managed by `/director`

Other sweep skills (`sweep-review-prs`, `sweep-address-prs`) produce the standard artifact contract (manifest.json + item directories + runner script) and get full director integration.

## Goal

Refactor `/sweep-work-items` to produce the standard artifact contract so it can be launched and monitored by `/director`. Implementations must still run in isolated worktrees.

## Design Decisions

### Artifact structure

```
tmp/sweep-work-items/<timestamp>/
├── manifest.json
├── let-it-rip.sh
├── directives.md              # global directives from director
└── item-<issue#>/
    ├── prompt.txt             # filled from implementer-prompt.md or clarifier-prompt.md
    ├── directives.md          # per-item directives
    ├── status.md              # watermark + milestone (written by session)
    ├── result.md              # completion report (written by session)
    ├── session.pid            # written by runner
    ├── live.md                # written by stream-monitor.sh
    └── raw.jsonl              # full event stream
```

### manifest.json schema

```json
{
  "created_at": "<ISO>",
  "run_dir": "<path>",
  "concurrency": 5,
  "owner_repo": "owner/repo",
  "default_branch": "main",
  "repo_summary": "<compressed repo context from Phase 4>",
  "items": [
    {
      "id": "53",
      "label": "#53 — Consolidate tmp artifact paths",
      "decision": "implement",
      "issue_url": "https://github.com/...",
      "branch": "sweep/53-consolidate-tmp-artifact-paths",
      "worktree": "<path or null for clarifiers>"
    }
  ],
  "skipped": [
    { "id": "32", "label": "#32 — GitLab parity", "reason": "Awaiting reply" }
  ]
}
```

### Runner script: two session types

The runner needs to handle implementers (need worktrees) and clarifiers (no worktrees) in the same run. Use the existing `{{#WORKTREES}}` template pattern:

- **Implementers**: worktree setup at `<run_dir>/worktrees/item-<issue#>/`, branch `sweep/<issue#>-<slug>`. The `claude -p` session runs with CWD set to the worktree.
- **Clarifiers**: no worktree. The `claude -p` session runs from project root. Only needs Bash(gh) and Write(tmp/) permissions.

The runner's `process_item()` function checks the decision type from manifest and adjusts CWD accordingly:
```bash
if [ "$decision" = "implement" ]; then
    cd "$worktree_path"
fi
cat "${item_dir}/prompt.txt" | sh -c '...' | stream-monitor.sh "$item_dir" | tee "$item_dir/raw.jsonl"
```

### Prompt generation

The existing `implementer-prompt.md` and `clarifier-prompt.md` templates stay as-is. The skill fills placeholders at artifact generation time (Phase 5), writing the result to `item-<issue#>/prompt.txt`. The repo summary (Phase 4) is embedded inline in each prompt.

Key additions to the prompt templates for `claude -p` compatibility:
- Add status.md watermark write at end (so the director knows the session completed)
- Add result.md append with the completion report
- Remove Agent-specific framing ("You are an autonomous implementer agent" stays, but remove references to being a subagent)

### Convergence strategy

Work items are one-shot — unlike review/address sweeps, there's no rerun cycle. Convergence is simply: all sessions completed (or timed out). The director marks the run as converged when the runner finishes.

If a session fails, the director can:
1. Read `live.md` to understand what happened
2. Write a directive with instructions
3. Relaunch the runner (it skips completed items via status.md watermark)

### Permission handling

No `--dangerously-skip-permissions`. Sessions inherit from `settings.json`/`settings.local.json`. The skill's prerequisites section (Phase 0) verifies required patterns before generating artifacts — same as today.

## Implementation Steps

### Step 1: Update SKILL.md phases

Modify `claude/commands/sweep-work-items/SKILL.md`:

- **Phases 1-4 stay mostly the same** (parse args, fetch issues, skip detection, repo summary)
- **Phase 5 (Decide & Dispatch)** → rename to **Phase 5 (Generate Artifacts)**:
  - Make implement/clarify decision per item (same logic)
  - Generate `manifest.json`
  - For each item: fill prompt template → write `item-<issue#>/prompt.txt`
  - For implementers: compute branch name, worktree path
  - Generate `let-it-rip.sh` from runner template
  - **Stop here** — don't launch. The director handles launch and monitoring.
- **Phase 6 (Results Summary)** → remove from skill. The director handles retro via playbook's monitoring table.
- **Add announce format** matching sweep-scaffold.md pattern:
  ```
  Artifacts written to <RUN_DIR>/
    manifest.json    — N eligible, K skipped
    let-it-rip.sh    — concurrency: 5
    item-<N>/        — M item directories with prompts
  ```

### Step 2: Create work-items runner template

Create `claude/skill-references/work-items-runner-template.sh` (or extend the existing parallel-claude-runner-template.sh with a `{{MODE}}` = "work-items" path):

Option A (separate template): cleaner, no risk of breaking existing sweep runners.
Option B (extend existing): DRY, but the existing template is already complex with review/address modes.

**Recommendation: Option A** — separate template. The work-items runner has different semantics (implement vs clarify, one-shot vs rerunnable) that would add too many conditionals to the shared template.

Template needs:
- `process_item()` function that checks decision type
- Worktree setup for implementers only
- CWD switching for implementer sessions
- Stream monitor pipeline integration
- Pre-flight skip via status.md (for reruns after directive-based fixes)

### Step 3: Update prompt templates

Modify `implementer-prompt.md` and `clarifier-prompt.md`:

Add to both (at the end of Instructions):
```markdown
N. **Write status.** After completing all steps, write a status file:
   Write to `status.md` in your current directory:
   ```
   milestone: done
   decision: implement|clarify
   result: success|error
   ```
```

Add to implementer only:
```markdown
N+1. **Write result.** Append your Completion Report to `result.md` in your current directory.
```

Add to clarifier:
```markdown
N+1. **Write result.** Append your Completion Report to `result.md` in your current directory.
```

Remove from implementer: the `tmp/sweep-work-items/pr-body-{ISSUE_NUMBER}.md` pattern — PR body can be written to the item directory instead.

### Step 4: Update director playbook

Add to `director-sweep-playbook.md` § Convergence Rules:

```markdown
### Work Items
- **Converged**: all sessions completed (status.md shows milestone: done for all items)
- **Not converged**: any session still running or errored without directive resolution
- **One-shot**: no automatic relaunch. Director reruns manually after writing directives for failed items.
```

### Step 5: Update director skill

Add to `claude/commands/director/SKILL.md` Phase 2:
```
- Work items: `skill="sweep-work-items"`, `args="<passthrough>"`
```

## Verification

1. Run `/sweep-work-items` standalone — should generate artifacts and announce, NOT launch
2. Run `/director` → "work items" → should invoke sweep-work-items, then launch runner and monitor
3. Verify `live.md` populated during implementer session
4. Verify worktree created for implementer, not for clarifier
5. Verify status.md and result.md written by sessions
6. Test directive + relaunch flow: kill a session, write directive, rerun runner

## Files to modify

| File | Change |
|------|--------|
| `claude/commands/sweep-work-items/SKILL.md` | Rewrite Phase 5-6 to generate artifacts |
| `claude/commands/sweep-work-items/implementer-prompt.md` | Add status.md/result.md writes |
| `claude/commands/sweep-work-items/clarifier-prompt.md` | Add status.md/result.md writes |
| `claude/skill-references/work-items-runner-template.sh` | New — runner with worktree support |
| `claude/skill-references/director-sweep-playbook.md` | Add work-items convergence rules |
| `claude/commands/director/SKILL.md` | Add work-items to Phase 2 |
