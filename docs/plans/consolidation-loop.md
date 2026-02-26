# Autonomous Consolidation Loop

## Problem

End-of-day learnings curation is a manual multi-step process: run `/learnings:compound` throughout the day, then manually invoke `/learnings:consolidate` (which requires user approval for MEDIUM-confidence items). This takes significant time and attention.

## Solution

A ralph-style autonomous loop that runs the full consolidation pipeline unattended — applying HIGHs automatically, judging MEDIUMs autonomously with full decision logging, and surfacing true blockers for morning review. Runs in a worktree for safe isolation with git-based rollback.

## Design Decisions (from planning session)

### Convergence: 2 consecutive clean sweeps
A single LOWs-only sweep isn't sufficient — the agent might miss patterns that a fresh invocation catches. Require 2 consecutive clean sweeps before declaring a content type converged.

### Safety: single iteration cap only
No per-content-type caps, no phase-cycle caps. Just `max_iterations` (default 20). When hit, the loop stops and surfaces state as a blocker for human review. Simpler, and the stalled-vs-progressing detection handles diagnosis.

### Two-pass progression
LEARNINGS → SKILLS → GUIDELINES → LEARNINGS → SKILLS → GUIDELINES. The second pass catches cross-content-type regressions (e.g., guideline changes that affect learnings).

### LOWs → lows.md for /learnings:curate
LOWs are written to `lows.md`, formatted so `/learnings:curate` can pick them up as starting points for interactive human-in-the-loop review.

### Full persona autonomy
Auto-apply enrichment, creation, and restructuring of personas. The worktree diff + decisions.md give full visibility; user can revert anything in the PR review.

### Stalled detection
When max iterations is hit, wiggum.sh checks whether the last N iterations produced actions. Reports either "PROGRESSING" (corpus needs more iterations) or "STALLED" (agent may be thrashing).

### Spec is a template (not editable mid-run)
The canonical spec lives in `templates/spec.md`. Init copies it fresh each run. Methodology improvements go into the template for the next run, not mid-run patching.

## Directory Structure

```
~/.claude/ralph/consolidate/           # Runner infrastructure
  wiggum.sh                            # Outer loop runner
  .gitignore                           # Ignore logs/
  hooks/
    lib-hooks.sh                       # Hook injection/removal
    guard-bash.sh                      # Blanket Bash block
    guard-web.sh                       # Blanket WebFetch/WebSearch block
    guard-write-scope.sh               # Write/Edit scoped to .claude/ in worktree
  templates/
    spec.md                            # Consolidation methodology (piped to claude each iteration)
    progress.md                        # State tracking template
    decisions.md                       # Decision log template
    blockers.md                        # Human-needed items template
    report.md                          # Cumulative summary template
    lows.md                            # Low-confidence items for /learnings:curate

~/.claude/commands/ralph/consolidate/   # Skills
  init/SKILL.md                        # /ralph:consolidate:init
  resume/SKILL.md                      # /ralph:consolidate:resume
```

## Worktree Mechanics

```
dotfiles repo (main) ← ~/.claude symlinks here
  └── .claude/
      ├── learnings/          ← LIVE content
      ├── commands/
      ├── guidelines/
      └── worktrees/
          └── consolidate-2026-02-25/    ← WORKTREE (branch: consolidate/2026-02-25)
              └── .claude/
                  ├── learnings/         ← COPY being modified
                  ├── commands/
                  ├── guidelines/
                  └── consolidate-output/  ← loop state files
                      ├── spec.md
                      ├── progress.md
                      ├── decisions.md
                      ├── blockers.md
                      ├── report.md
                      └── lows.md
```

Changes happen in the worktree. User reviews `git diff main`, merges to main. Since `~/.claude` points to main, changes take effect on merge.

## spec.md Structure (~300 lines)

The core methodology file piped to `claude --print` each iteration. Stateless — no conversation history between iterations. All continuity is through files on disk.

### 1. Role + Constraints
- You are a consolidation agent. One sweep per iteration.
- No Bash, no web. Read progress.md first, update all output files before exiting.

### 2. File Layout
- Corpus paths: `.claude/learnings/`, `.claude/guidelines/`, `.claude/commands/`, `.claude/commands/set-persona/`
- Output paths: `consolidate-output/{progress,decisions,blockers,lows,report}.md`

### 3. Methodology References (read on first iteration only, when SWEEP_COUNT=0)
- `.claude/commands/learnings/curate/classification-model.md`
- `.claude/commands/learnings/compound/content-type-decisions.md`
- `.claude/commands/learnings/curate/persona-design.md`
- `.claude/commands/learnings/curate/curation-insights.md`
- `.claude/commands/learnings/curate/SKILL.md` (analysis methodology only)

### 4. Two-Pass Content Type Progression
- Pass 1: LEARNINGS → SKILLS → GUIDELINES
- Pass 2: LEARNINGS → SKILLS → GUIDELINES (catches cross-type regressions)

### 5. Per-Iteration Workflow
1. Read progress.md → determine CONTENT_TYPE, PHASE, PASS
2. Execute one sweep (broad sweep for learnings, skill mode for skills, content mode for guidelines — per curate SKILL.md methodology)
3. Separate findings: HIGH / MEDIUM / LOW
4. Apply HIGHs automatically
5. Judge MEDIUMs autonomously, log all to decisions.md
6. Write LOWs to lows.md
7. Update progress.md, report.md, optionally blockers.md
8. Check convergence + phase transitions

### 6. MEDIUM Judgment Criteria (full autonomy)

| Judgment | When | Examples |
|----------|------|---------|
| **Auto-apply** | Reversible, no unique content lost | Compression, genericization, dedup, fold thin files, stale versions, persona enrichment/creation/restructuring |
| **Block** | Irreversible with unknown user preference | Deleting unique content with no clear target, ambiguous domain tradeoffs |

### 7. Persona Enrichment
When compressing/removing learnings, check if distilled knowledge should flow into a matching persona. Auto-apply for enrichment, creation, and restructuring. Log everything to decisions.md.

### 8. Convergence
- 2 consecutive clean sweeps (LOWs-only) → content type converged
- Reset CLEAN_SWEEP_STREAK when any HIGH or MEDIUM is found

### 9. Completion
- All three content types converged on both passes → write `WOOT_COMPLETE_WOOT` to progress.md
- If max iterations hit → write current state summary (wiggum.sh handles stalled vs progressing)

## Implementation Status

### Done

| File | Status | Notes |
|------|--------|-------|
| `ralph/consolidate/hooks/guard-bash.sh` | ✅ | Blanket Bash block |
| `ralph/consolidate/hooks/guard-web.sh` | ✅ | Blanket WebFetch/WebSearch block |
| `ralph/consolidate/hooks/guard-write-scope.sh` | ✅ | Scoped to `.claude/` in worktree |
| `ralph/consolidate/hooks/lib-hooks.sh` | ✅ | Injection/removal with WebSearch matcher |
| `ralph/consolidate/wiggum.sh` | ✅ | Runner with stalled detection |
| `ralph/consolidate/.gitignore` | ✅ | Ignore logs/ |
| `ralph/consolidate/templates/progress.md` | ✅ | State tracking template |
| `ralph/consolidate/templates/decisions.md` | ✅ | Decision log template |
| `ralph/consolidate/templates/blockers.md` | ✅ | Blocker format template |
| `ralph/consolidate/templates/report.md` | ✅ | Summary template |
| `ralph/consolidate/templates/lows.md` | ✅ | LOWs for curate pickup |

### Remaining

| File | Description |
|------|-------------|
| `ralph/consolidate/templates/spec.md` | Core consolidation methodology (~300 lines). See "spec.md Structure" above. |
| `commands/ralph/consolidate/init/SKILL.md` | Init skill: create worktree, scaffold output files, run pre-flight |
| `commands/ralph/consolidate/resume/SKILL.md` | Resume skill: read state, present status, collect blocker decisions, relaunch |
| `setup-claude.sh` | Add `ralph` to ITEMS array |
| `.claude/README.md` | Add consolidate skills + autonomous workflow section |
| `.claude/learnings/ralph-loop.md` | Add consolidation loop variant section |

### Verification (after implementation)

1. **Skill routing**: Check if `commands/ralph/consolidate/init/SKILL.md` is discovered as `/ralph:consolidate:init`. If three-level routing doesn't work, flatten to `commands/ralph/consolidate-init/SKILL.md`.
2. **Hooks**: Verify guards block Bash, WebFetch, WebSearch, and out-of-scope writes.
3. **Init skill**: Verify worktree created with correct branch, all 6 output files scaffolded, pre-flight populated.
4. **Runner**: Run `bash ~/.claude/ralph/consolidate/wiggum.sh 2` — verify hooks injected/removed, spec piped correctly, completion signal checked, logs written.
5. **Resume skill**: Verify it reads state and presents status correctly.
6. **Integration**: Verify `setup-claude.sh` symlinks `ralph/` correctly.
