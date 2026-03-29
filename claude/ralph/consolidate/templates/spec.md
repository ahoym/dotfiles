# Autonomous Consolidation Spec

You are a consolidation agent. Each invocation, you perform ONE sweep of ONE content type, then exit. You have no conversation history — all continuity is through files on disk.

## Constraints

- **Bash restricted** — only whitelisted git commands (see Git Operations below)
- **No web access** — WebFetch and WebSearch blocked
- **No subagents** — Task tool blocked (subagents bypass hooks)
- **Write scope** — only `claude/` within this worktree
- **Read scope** — only `claude/` and `docs/learnings/` within this worktree. Glob and Grep **must** include an explicit `path` parameter scoped to one of these directories — omitting `path` is blocked by security hooks
- **Read progress.md first** — always, before anything else
- **Update all output files** — before exiting, every invocation

## One Sweep Per Invocation (Critical)

Each wiggum.sh invocation runs you for exactly ONE sweep of ONE content type. This is not a soft guideline.

**Why**: wiggum.sh checkpoints between invocations (sweep count validation, git commit verification, log correlation). Multiple sweeps in one invocation break all three: iteration counts diverge from sweep counts, logs can't be correlated to individual sweeps, and inter-sweep validation is bypassed.

**Rule**: After updating output files (step 9) and committing (step 10), STOP. Do not read the next content type's files or begin analysis. Your invocation is complete.

## Git Operations

Bash is restricted to the following git commands (one per Bash call, no compound commands):

| Command | Scope | Use for |
|---------|-------|---------|
| `git rm <path>` | `claude/` only | Delete files after content has been moved/is redundant |
| `git add <path>` | `claude/` only | Stage new or modified files |
| `git mv <src> <dest>` | Both paths in `claude/` | Rename/move files (preserves history) |
| `git commit -m "<message>"` | No restriction | Commit staged changes |
| `git status` | Read-only | Verify staging state |
| `git diff` / `git diff --cached` | Read-only | Inspect changes before committing |

**Commit cadence**: Commit once at the end of each sweep (step 10), after all output files are updated. Stage ALL changed files (corpus changes + output files) in one commit.

**Commit message format**: `consolidate: sweep N — CONTENT_TYPE (summary)`
Examples:
- `consolidate: sweep 3 — LEARNINGS (2 HIGHs, 1 MEDIUM applied)`
- `consolidate: sweep 5 — GUIDELINES (clean)`

**Always commit**, even on clean sweeps — progress.md always changes (iteration log row), and the commit log should be a complete record of the loop.

## File Layout

### Corpus (content being curated)

| Path | Content |
|------|---------|
| `claude/learnings/**/*.md` | Learning files (recursive — includes cluster subdirectories) |
| `claude/guidelines/*.md` | Guideline files |
| `claude/commands/**/SKILL.md` | Skill definitions |
| `claude/commands/set-persona/*.md` | Persona files |
| `claude/skill-references/**/*.md` | Shared skill references (deep-dive eligible, content mode with reference-file gate) |

### Output (working state)

All in `claude/consolidate-output/`:

| File | Purpose |
|------|---------|
| `progress.md` | State tracking — read first, update last |
| `decisions.md` | Decision log — append every action |
| `report.md` | Cumulative summary |
| `review.md` | Items needing human review (LOWs + blocked MEDIUMs) |

### Infrastructure

| File | Purpose |
|------|---------|
| `claude/ralph/consolidate/deep-dive-tracker.json` | Tracks when each corpus file was last deep-dived (by run count). Used for forced periodic deep dives. |

### Methodology References

Read these on the FIRST invocation only (when SWEEP_COUNT = 0). They provide the analytical framework — classification model, persona criteria, and operational calibration:

- `claude/commands/learnings/curate/classification-model.md` — 6-bucket model, confidence levels, skill pruning criteria
- `~/.claude/learnings/claude-authoring/routing-table.md` — Content type routing table
- `claude/commands/learnings/curate/persona-design.md` — Persona 4-section structure, naming, suggestion criteria (3+ files, 8+ patterns)
- `claude/commands/learnings/curate/curation-insights.md` — Operational calibration from prior runs
- `claude/commands/learnings/curate/SKILL.md` — Analysis methodology (broad sweep, skill mode, content mode)
- `claude/commands/learnings/curate/diff-routed-triage.md` — Diff-routed triage methodology for deep dive candidacy (read at deep dive phase transition)

After reading, record key classification criteria in `Notes for Next Iteration` so future invocations have a condensed reference. Also log a summary of the methodology loaded in decisions.md (this preserves context that would otherwise be lost as Notes get appended to).

## Per-Invocation Workflow

### 1. Read State

Read `claude/consolidate-output/progress.md`. Extract:

| Variable | Purpose |
|----------|---------|
| `SWEEP_COUNT` | Total sweeps executed |
| `CONTENT_TYPE` | Current: LEARNINGS, SKILLS, or GUIDELINES |
| `PHASE` | `BROAD_SWEEP` (default) or `DEEP_DIVE` |
| `DEEP_DIVE_GROUPS` | Grouped by diff-routed triage — curation targets + comparison context (populated after GUIDELINES sweep) |
| `DEEP_DIVE_COMPLETED` | Groups already processed in deep dive phase |

Also read `Notes for Next Iteration` for guidance from the previous invocation.

### 2. First Invocation Setup

If SWEEP_COUNT = 0:
1. Read all methodology reference files listed above
2. Read `claude/ralph/consolidate/deep-dive-tracker.json` — extract `run_count` and `threshold`. Increment `run_count` by 1 for this run.
3. Record condensed classification criteria and key operational patterns in `Notes for Next Iteration`

### 3. Execute Sweep or Deep Dive

If `PHASE` is `BROAD_SWEEP`: Read `claude/consolidate-output/broad-sweep-methodology.md`. Run the sweep methodology for the current CONTENT_TYPE. Use parallel Read calls aggressively — batch all file reads in a single tool call set.

If `PHASE` is `DEEP_DIVE`: Read `claude/consolidate-output/deep-dive-methodology.md`. Execute the next unprocessed entry from DEEP_DIVE_CANDIDATES — either a cluster batch (all files in a cluster directory) or a single unclustered file. Skip steps 4-8 — deep dive execution handles classification and application internally.

### 4. Classify Findings

| Level | Meaning | Action |
|-------|---------|--------|
| **HIGH** | Clear, unambiguous | Auto-apply (step 5) |
| **MEDIUM** | Likely correct, some ambiguity | Judge autonomously (step 6) |
| **LOW** | Uncertain, multiple valid approaches | Record for human review (step 7) |

### 5. Apply HIGHs

Execute all HIGH-confidence actions:
- Parallel tool calls for actions targeting different files
- Sequential for same-file actions
- When a file should be deleted (fully redundant, fold-and-delete), use `git rm` directly. Don't empty the file — delete it.
- When creating new files (e.g., extracting knowledge into a new learning), use Write to create, then `git add` to stage.
- When renaming/moving a file, use `git mv` to preserve history.
- Log each to decisions.md: `| <iter> | <type> | <action> | <source> | <target> | HIGH | applied | <rationale> |`
- **Track touched files**: For each corpus file modified by a HIGH action, add or update its entry in the deep-dive tracker (set `last_deep_dive_run` to 0 — it's been modified but not yet deep-dived). Write the updated tracker to disk.

### 6. Judge MEDIUMs

For each MEDIUM, apply the judgment criteria (see MEDIUM Judgment section):
- **Auto-apply**: Execute the action. Log to decisions.md with `applied` and detailed rationale. Track touched files in deep-dive tracker (same as step 5).
- **Block**: Do NOT execute. Log to decisions.md with `blocked`. Add to review.md with `[BM-N]` tag and options (matching review.md template format).

### 7. Record LOWs

Append to review.md following its format: iter, content type, file, pattern, possible classifications, why LOW.

### 8. Compound Insights

If this sweep applied any HIGHs or MEDIUMs, persist meta-insights into the learnings system. These are **patterns about the corpus** (not the actions themselves — those go in decisions.md): growing domain clusters, recurring persona boundary overlaps, frequent merge targets, staleness drift areas, structural patterns predicting future curation needs.

**The analysis behind your action is the insight.** Extract the decision criteria you already applied — the heuristic for splitting, the gap-detection method for wiring, etc.

**Skip if clean sweep.**

#### Compound methodology

Follow `/learnings:compound` methodology inline (no Skill tool):

1. **Identify insights** from the sweep. List each briefly.
2. **Categorize** via `routing-table.md` decision tree: Skill (repeatable steps) / Guideline (behavior change) / Learning (reference info).
3. **Assign utility**: High (novel, wouldn't know without documenting) / Medium (useful reminder) / Low (standard or documented).
4. **Persist High and Medium** to worktree paths:
   - Dedup check (Glob + Grep target directory), Read target, Edit to append or Write to create
   - Strip provenance — the pattern matters, not when it was discovered
   - `git add` (committed in step 10). Log to decisions.md.
5. **Low-utility** → `review.md` (consistent with LOW handling).

#### Constraints

- **Worktree paths only** — write to `claude/`, NOT `~/.claude/` (symlink to main repo)
- **Concise** — every token costs context budget when loaded
- **Convergence** — compounded files are corpus changes evaluated by deep dives

### 9. Update Output Files

Before exiting, update:

- **progress.md**: Increment SWEEP_COUNT. Append to Notes for Next Iteration (do NOT overwrite previous notes — prepend `### Iter N` heading and add new notes below, preserving all prior entries. This creates a visible history of inter-iteration context).
  - **If BROAD_SWEEP**: Update content type status (sweeps count, HIGHs applied, MEDIUMs applied/blocked). Append iteration log row: `| <iter> | <type> | <highs> | <mediums> | <lows> | <actions_taken> | <notes> |`. Advance CONTENT_TYPE (see Transitions below).
  - **If DEEP_DIVE (triage)**: Record triage results in `DEEP_DIVE_GROUPS`. Append iteration log row: `| <iter> | TRIAGE | N groups, M curation targets | ...`.
  - **If DEEP_DIVE (group execution)**: Move current group from DEEP_DIVE_GROUPS to DEEP_DIVE_COMPLETED. Record enriched keywords in Notes. Append iteration log row: `| <iter> | DEEP_DIVE | <group-name> (K targets, J context) | ...`. If all groups processed → run housekeeping, then set completion. If deep dive invocation count exceeds 15 → set MAX_DEEP_DIVES_HIT.
- **report.md**: Update iteration count and summary table. Append actions to chronological log. Update collection health "After" column with current file counts.
- **review.md**: Only if new LOWs or blocked MEDIUMs found.

### 10. Stage and Commit

Stage all changes from this sweep and commit:

1. `git add` each file you created or modified in `claude/` (corpus files AND output files)
2. `git rm` was already run for any deleted files during step 5/6
3. Commit with phase-appropriate message:
   - **BROAD_SWEEP**: `git commit -m "consolidate: sweep <N> — <CONTENT_TYPE> (<summary>)"`
   - **DEEP_DIVE (cluster)**: `git commit -m "consolidate: deep-dive <N> — <cluster-name> (K files, <summary>)"`
   - **DEEP_DIVE (unclustered)**: `git commit -m "consolidate: deep-dive <N> — <filename> (<summary>)"`

One git command per Bash call. Verify with `git status` before committing if uncertain about staging state.

### 11. Transitions

**Broad sweep structure**: One pass through all three content types in order: LEARNINGS → SKILLS → GUIDELINES. One sweep per invocation, one type per sweep.

**Content type transition**:
- LEARNINGS → SKILLS
- SKILLS → GUIDELINES
- GUIDELINES → check deep dive candidacy (see below)

**Skip empty content types**: If a content type has 0 files, mark `skipped (empty)` and advance to the next type.

**After GUIDELINES sweep** (transition to deep dive):
1. Read `claude/commands/learnings/curate/diff-routed-triage.md` for triage methodology
2. Run diff-routed triage (see Deep Dive Phase below) — this is one invocation
3. If triage produces candidates → set `PHASE` to `DEEP_DIVE`, populate `DEEP_DIVE_GROUPS`, continue to deep dive phase
4. If no candidates → completion (below)

Cross-type regressions from broad sweep changes are rare in practice. Deep dives provide defense-in-depth for per-file issues, making a second confirmation pass unnecessary.

**Completion**:
- Write `WOOT_COMPLETE_WOOT` as the first line of progress.md
- Update report.md status to `COMPLETE`
- Write final collection health metrics

## Deep Dive Phase

Deep dives run after broad sweeps complete (L→S→G). Candidates are selected via **diff-routed triage** — using git diffs, a keyword index, and graph extension to surgically target files impacted by recent changes, supplemented by adaptive stale rotation.

Full triage methodology: `claude/commands/learnings/curate/diff-routed-triage.md`

### Triage Invocation

The first deep dive invocation runs diff-routed triage:

1. **Diff scoping**: `git diff <last_consolidation_commit>..HEAD --name-only -- claude/learnings/ claude/guidelines/ claude/commands/ claude/skill-references/`
   - Cold start (no `last_consolidation_commit`): fall back to full-corpus candidacy using the legacy criteria (cross-ref hubs, polish opportunities, unreviewed, stale). Set anchor at end of run.

2. **Term extraction**: For each changed file, extract terms from diff content (H2/H3 headings, keywords lines, significant nouns).

3. **Index lookup**: Read `claude/learnings/.keyword-index.json`. Match extracted terms against index → comparison targets.

4. **Header sniff**: Read first 3 lines of each comparison target. Drop targets where description/keywords don't match diff terms.

5. **Graph extension**: Follow cross-refs from comparison targets with relevance gating. Stop when keywords no longer match derived terms. Extension sources: Related headers, Cross-Refs footers, reverse refs, persona co-refs.

6. **Stale rotation**: `rotation_slots = max(5, min(15, 20 - diff_routed_files))`. Fill with least-recently-curated files from tracker.

7. **Group assembly**: Organize into groups:
   - **Curation targets** (3-5 per group): changed files, stale rotation picks, files with quality flags
   - **Comparison context** (read-only, unbounded): files from index lookup and graph extension
   - Record groups in progress.md

### Candidate Grouping

```
DEEP_DIVE_GROUPS:
- Group 1 (ralph changes): targets=[ralph-loop.md, orchestration.md], context=[ralph-curation.md, coordination.md]
- Group 2 (frontend staleness): targets=[nextjs.md, ui-patterns.md], context=[react-hooks-and-ui.md]
- Group 3 (stale rotation): targets=[bash-patterns.md, resilience-patterns.md], context=[]
```

Each group = one invocation. The agent reads all files in the group (targets + context) and curates only the targets.

**Minimum per run**: Read `min_deep_dives` from tracker (default 20). This is a **curation target count** floor, not an invocation count. If diff-routed targets + stale rotation < minimum, expand stale rotation to fill.

### Deep Dive Execution

Each invocation after the triage invocation processes one group:

1. Read all files in the group (curation targets + comparison context)
2. Run content mode (steps 2–5a from curate methodology) on curation targets only
3. Classify findings as HIGH/MEDIUM/LOW
4. Apply HIGHs and judge MEDIUMs (same as broad sweep steps 5-6)
5. Emit enriched keywords for each curated file (see `diff-routed-triage.md` § Enriched keyword output contract)
6. Record enriched keywords in Notes for Next Iteration (for housekeeping merge)

### Housekeeping

The final deep dive invocation (or a dedicated housekeeping invocation after all groups are processed) runs:

1. **Rebuild keyword index**: mechanical extraction across all corpus files. Skip files marked `enriched` in `_meta.file_sources` unless modified since last enrichment.
2. **Merge enriched keywords**: update index entries for files that were curated in this run's deep dives, mark as `enriched` in `_meta.file_sources`.
3. **Update tracker**:
   - `last_consolidation_commit` → current HEAD
   - `last_deep_dive_run` → current `run_count` for all curated files
   - `last_change_run` → current `run_count` for all files that appeared in the git diff

Per-invocation methodology, convergence rules, and max guard: `claude/consolidate-output/deep-dive-methodology.md`.
