# Diff-Routed Curation

## Problem

The consolidate loop's deep dive candidacy is coarse. After broad sweeps (L→S→G), deep dive targets come from broad sweep suggestions + staleness rotation — a blunt selection that either reads too many files (staleness fills slots with unchanged content) or misses impacted neighbors (broad sweep suggestions don't follow change propagation). As the corpus grows (~80 files, trending upward), this gets worse: more stale candidates, more missed connections.

Broad sweeps stay as-is — they need full corpus context for cross-file analysis. The waste is in deep dive targeting, not broad sweep reads.

## Solution

Replace deep dive candidacy logic with **diff-routed triage**: use git diffs to identify what changed since the last consolidation, extract terms from the changes, route to potentially impacted files via an inverted keyword index, then extend to neighbors via the cross-ref graph. Deep dive targets become surgical instead of coarse.

Applies to both the interactive `/learnings:consolidate` skill and the autonomous ralph loop (`wiggum.sh` + `spec.md`).

Related: `docs/plans/consolidation-loop.md` — the autonomous consolidation loop.

## Architecture

```
Broad sweeps (unchanged) — full corpus, L→S→G
         ↓
Diff-routed deep dive triage:
  1. git diff <last_consolidation_commit>..HEAD
  2. Build/load keyword index (all content types)
  3. Extract terms from diff content
  4. Match terms → comparison targets via index
  5. Graph-extend with relevance gating
  6. Add stale rotation (adaptive budget)
  → Output: grouped deep dive candidates
         ↓
Deep dive execution (mostly unchanged) — per-group
  curation with read-once grouped analysis
         ↓
Housekeeping — rebuild index, update tracker
```

### Scope

Diff-routing covers all content types:
- `claude/learnings/**/*.md` — learnings (cluster subdirectories + flat files)
- `claude/guidelines/*.md` — guidelines
- `claude/commands/**/SKILL.md` — skills
- `claude/skill-references/**/*.md` — shared skill references

The keyword index indexes all four. Diff scoping detects changes across all four. Graph extension follows cross-refs regardless of content type boundaries.

### Key components

**1. Inverted keyword index** (`learnings/.keyword-index.json`)

Derived (not authored) artifact mapping keywords to file paths across all content types:

```json
{
  "_meta": {
    "last_rebuild_commit": "ff3ff1d",
    "file_sources": {
      "claude-code/multi-agent/orchestration.md": "enriched",
      "frontend/nextjs.md": "mechanical",
      "guidelines/communication.md": "mechanical"
    }
  },
  "synthesis": ["claude-code/multi-agent/orchestration.md"],
  "worktree": [
    "claude-code/multi-agent/coordination.md",
    "claude-code/platform-worktrees-and-isolation.md"
  ],
  "polling": ["claude-authoring/polling-review-skills.md"],
  "hook": ["claude-code/hooks.md", "guidelines/skill-invocation.md"]
}
```

One file read → instant term-to-file lookup. Flat structure (not grouped by cluster) — simpler for lookup, cluster structure is already in the directory layout.

**Hybrid extraction strategy:**

- **Mechanical extraction (default)**: runs during housekeeping on every consolidation. For each file:
  - Parse `**Keywords:**` header line
  - Split H2/H3 headings into terms
  - Extract high-frequency nouns from body text (stop words removed)
  - Basic normalization (lowercase, strip plurals)

  Fast, deterministic, covers the full corpus every run.

- **LLM-assisted enrichment (during deep dives)**: when a deep dive subagent finishes curating a file, it also emits an enriched keyword list as part of its output. Higher quality — the agent understands context, synonyms, and which terms are load-bearing vs incidental.

- **Provenance tracking**: `_meta.file_sources` records whether each file's keywords are `mechanical` or `enriched`. Mechanical rebuild skips files marked `enriched` unless the file was modified since last enrichment (detected via the diff). Enriched keywords persist until the file changes, then fall back to mechanical until the next deep dive re-enriches.

- **Convergence**: files that change frequently get diff-routed more often → hit deep dives more often → get enriched first. Files with stable content keep their mechanical keywords, which are fine for stable content.

**2. Git-diff scoping**

`last_consolidation_commit` in the deep-dive tracker anchors each run:

```bash
git diff <last_consolidation_commit>..HEAD --name-only -- claude/learnings/ claude/guidelines/ claude/commands/ claude/skill-references/
```

Changed files are the seeds. Diff content (actual sections added/modified) provides the terms for keyword index lookup.

**Cold start**: when `last_consolidation_commit` doesn't exist (first run), fall back to full-corpus deep dive candidacy (current behavior). Set the commit anchor at the end of the run. This only happens once.

**3. Term extraction**

Extract terms from diff content of each changed file:
- H2/H3 headings added or modified
- `**Keywords:**` line if it changed
- Significant terms from new/modified section content (same extraction as mechanical index building)
- Function/concept names from code blocks

These terms drive the keyword index lookup.

**4. Graph-extended impact sets**

From each comparison target (files whose index keywords overlap with diff terms), follow cross-refs with relevance-gated traversal. No hard depth limit — sniff each hop's header, stop when keywords no longer match derived terms, announce at 3+ hops.

Extension sources:
- `**Related:**` from file headers (cheap — already sniffed)
- `## Cross-Refs` from file footers (one tail read per file)
- Reverse refs — files that reference the target (one grep per file)
- Persona co-refs — if a persona lists both the changed file and another file, that other file is in the impact set

Agent judgment at each hop: "given the diff context, is this neighbor actually impacted or just adjacent?" This prevents pulling in the full corpus through a densely-connected subgraph.

**5. Read-once grouped curation**

Deep dive targets are grouped by relationship, with their comparison context loaded alongside:

- **Curation targets** (3-5 per group): the files being actively curated — changed files, stale rotation picks, files flagged for quality issues. These get the full curation treatment (classification, action recommendations, enriched keyword extraction).
- **Comparison context** (unbounded, read-only): files pulled in by keyword index matches and graph extension. Loaded into the same context so the agent can check for duplicates, overlaps, and cross-ref opportunities — but not curated themselves. The number of comparison files depends on how connected the curation targets are; no hard cap needed since they're read-only context, not curation work.

Grouping logic:
- Changed file + its comparison targets → same context
- Overlap suspects (keyword collision across clusters) → same context
- Cross-ref pairs flagged for potential staleness → same context

Each group is processed in one pass (subagent in interactive flow, single invocation in autonomous flow). The agent sees curation targets and comparison context simultaneously and can:
- Identify actual duplicates vs complementary content
- Propose merges with "keep from A, keep from B, drop overlap"
- Detect cross-ref opportunities not visible from either file alone
- Emit enriched keyword lists for each curated file (LLM-assisted enrichment)

Groups with more than 5 curation targets are split into sub-groups.

**6. Stale rotation (adaptive budget)**

Files not reached by diff routing or graph extension get baseline rotation. Budget adapts to change volume:

```
rotation_slots = max(5, min(15, 20 - diff_routed_files))
```

More changes → fewer rotation slots (run is already doing useful work). Fewer changes → more rotation slots (fill the cheap run with coverage). Total work per run stays roughly constant.

Pick the N least-recently-curated files (from `last_deep_dive_run` in tracker). These catch issues that existed before the last run but were never flagged — the "silent drift" gap.

## Updated consolidate loop flow

```
1. BROAD SWEEPS (unchanged — full corpus reads):
   L→S→G content type progression
   One sweep per content type per invocation (ralph)
   or multi-sweep loop with approval flow (interactive)
   → Output: HIGH/MEDIUM/LOW findings, applied actions

2. DIFF-ROUTED DEEP DIVE TRIAGE (replaces current candidacy):
   a. git diff → changed files (all content types)
   b. Read keyword index → one file
   c. Extract terms from diff content
   d. Match terms against index → comparison targets
   e. Sniff comparison targets' headers (3 lines each)
   f. Graph extend: follow cross-refs, relevance-gated
   g. Add stale rotation (adaptive budget)
   → Output: grouped deep dive candidates with flags
     (changed, comparison-target, impact-neighbor, stale-rotation)

3. DEEP DIVE EXECUTION (mostly unchanged):
   a. Groups come from diff-routed triage (not broad sweep suggestions)
   b. Per-group subagents: full-read + curate in one pass
   c. Each subagent also emits enriched keyword list
   → Output: HIGH/MEDIUM/LOW findings, enriched keywords

4. HOUSEKEEPING:
   a. Rebuild keyword index (mechanical, skip enriched unless changed)
   b. Merge enriched keywords from deep dive subagents
   c. Update last_consolidation_commit in tracker
   d. Update last_deep_dive_run for all curated files
```

## Tracker changes

Current:
```json
{
  "run_count": 15,
  "threshold": 5,
  "min_deep_dives": 20,
  "files": {
    "path/to/file.md": { "last_deep_dive_run": 15 }
  }
}
```

Proposed additions:
```json
{
  "run_count": 15,
  "last_consolidation_commit": "ff3ff1d",
  "threshold": 5,
  "min_deep_dives": 20,
  "files": {
    "path/to/file.md": {
      "last_deep_dive_run": 15,
      "last_change_run": 15
    }
  }
}
```

- `last_consolidation_commit`: git anchor for diff scoping
- `last_change_run`: which run the file was last seen as changed (from git diff). Enables "changed in run 12 but not deep-dived since run 8" prioritization.

## Files to modify

| File | Change |
|------|--------|
| `commands/learnings/consolidate/SKILL.md` | Deep dive candidacy replaced by diff-routed triage. Add keyword index rebuild + enrichment merge to housekeeping. |
| `commands/learnings/curate/content-mode.md` | Deep dive section updated: candidates come from diff-routing, subagents emit enriched keywords alongside curation results. |
| `ralph/consolidate/deep-dive-tracker.json` | Add `last_consolidation_commit` field. Add `last_change_run` per file. |
| `ralph/consolidate/templates/spec.md` | Deep dive candidacy section replaced with diff-routed triage. Housekeeping gains index rebuild step. |
| New: `learnings/.keyword-index.json` | Inverted keyword index. Derived artifact, rebuilt each run (mechanical), enriched during deep dives (LLM-assisted). |

## Scaling properties

- **Quiet periods** (few changes): triage reads ~3 files (index + 1-2 changed). Deep dives target ~5-15 files (changed + comparison targets + rotation fills remainder). Fast runs.
- **Active periods** (many changes): triage reads more comparison targets. Deep dives target more groups, rotation shrinks. Effort proportional to change volume, not corpus size.
- **Corpus growth**: triage cost grows only with index size (one file, grows linearly but stays small). Deep dive cost grows only with per-run change volume. A 200-file corpus with 3 changed files targets the same ~15 files as an 80-file corpus with 3 changed files.
- **Index quality over time**: mechanical extraction provides baseline coverage immediately. LLM enrichment improves precision progressively as files cycle through deep dives. Frequently-changed files (where precision matters most) get enriched first.

## Decisions (resolved)

1. **Scope**: diff-routing targets deep dives, not broad sweeps. Broad sweeps stay as-is (full corpus reads for cross-file analysis).
2. **Content types**: all four — learnings, guidelines, skills, skill-references.
3. **Both flows**: applies to interactive `/learnings:consolidate` and autonomous ralph loop.
4. **Index format**: flat JSON, separate file (`learnings/.keyword-index.json`). Not embedded in CLAUDE.md indexes (those are always-on context cost).
5. **Keyword extraction**: hybrid — mechanical by default, LLM-enriched during deep dives. Provenance tracked per-file.
6. **Stale rotation**: adaptive budget — `max(5, min(15, 20 - diff_routed_files))`.
7. **Cold start**: first run falls back to full-corpus candidacy (current behavior), sets commit anchor.

## Open questions

1. **Curation target density**: 3-5 curation targets per group is the working assumption. Comparison context is unbounded (read-only). Worth monitoring whether dense curation targets (large files with many patterns) need smaller groups.
2. **Cross-ref graph density**: as cross-refs improve, the impact set grows. The relevance gate should handle this, but worth monitoring for over-extension.
3. **Mechanical extraction quality**: the stop-word + noun extraction approach may produce noisy terms for some file types (e.g., skills with lots of procedural text). May need per-content-type extraction tuning.

## Risks

- **Keyword index staleness**: if a file's content changes but keywords aren't updated, the index routes incorrectly. Mitigated by: (1) mechanical rebuild from actual content each run, (2) stale rotation catching missed files, (3) LLM enrichment improving index quality over time.
- **Over-extension**: a highly connected file could pull in many neighbors as comparison context. Mitigated by relevance gating at each hop + agent judgment. Comparison context is read-only so the cost is tokens, not curation complexity.
- **Enrichment drift**: if the LLM extracts different terms on different runs, the index could oscillate. Mitigated by: enriched terms only update when the file actually changes (provenance tracking prevents clobbering).

## Implementation plan

### Phase 1: Interactive validation (test with `/learnings:consolidate`)

Build the minimal pieces needed to test diff-routed triage in the interactive flow, where the operator can observe routing decisions and course-correct.

**Step 1: Keyword index builder + initial index**

Build mechanical extraction and generate `learnings/.keyword-index.json` from the current corpus. This is useful standalone — inspect index quality before anything depends on it.

| Task | Detail |
|------|--------|
| Write extraction logic | Reference file or inline in curate methodology. Scan all content types: parse `**Keywords:**` lines, split H2/H3 headings, extract significant nouns from body text. Normalize (lowercase, strip plurals). |
| Generate initial index | Run extraction against full corpus. Output `learnings/.keyword-index.json` with `_meta` section (all sources `mechanical`, `last_rebuild_commit` set to current HEAD). |
| Inspect and validate | Review the index for quality: are terms routing to the right files? Are there obvious gaps or noise? |

**Step 2: Tracker changes**

| Task | Detail |
|------|--------|
| Add `last_consolidation_commit` | Set to current HEAD (anchors the first diff). |
| Add `last_change_run` per file | Set to 0 for all existing entries (no change history yet). |

**Step 3: Diff-routed triage logic**

Write the triage step as a reference file consumable by both flows. Contains:
- Git diff scoping (with cold start fallback)
- Term extraction from diff content
- Keyword index lookup
- Graph extension with relevance gating
- Adaptive stale rotation budget
- Group assembly (curation targets + comparison context)

| Task | Detail |
|------|--------|
| New reference file | `commands/learnings/curate/diff-routed-triage.md` — triage methodology, consumable by consolidate SKILL.md and spec.md. |
| Triage output format | Grouped candidates with flags and rationale, presented for operator review before deep dive execution. |

**Step 4: Wire into interactive consolidate**

| Task | Detail |
|------|--------|
| Update `SKILL.md` | Deep dive candidacy section (Step 1d) calls diff-routed triage instead of using broad sweep suggestions. Add keyword index rebuild to housekeeping after deep dives. |
| Update `content-mode.md` | Deep dive subagent output contract: emit enriched keyword list alongside classification table. |

**Step 5: Test run**

Run `/learnings:consolidate` with the new triage. Evaluate:
- Is the keyword index routing to relevant files?
- Are the groups sensible? Is comparison context useful or noise?
- Does the adaptive stale rotation budget feel right?
- Does enrichment produce meaningfully better terms than mechanical?

### Phase 2: Autonomous flow (after Phase 1 validates)

Update the ralph loop to use diff-routed triage. Only after Phase 1 confirms the routing makes good decisions.

| Task | Detail |
|------|--------|
| Update `spec.md` | Deep dive candidacy section replaced with diff-routed triage. Each invocation processes one group (curation targets + comparison context). Housekeeping gains index rebuild step. |
| Update deep dive methodology | Groups come from triage output instead of broad sweep suggestions. Single-invocation execution (no subagents). |
| Bootstrap index on first autonomous run | Mechanical extraction runs during first run's housekeeping, setting the baseline for subsequent runs. |

## Non-goals

- Replacing broad sweeps (they need full corpus context for cross-file analysis)
- Real-time curation at write-time (can't control other operators' compound behavior)
- Hard corpus size caps (soft budget via compression prioritization, not enforced limits)
- Replacing deep dives entirely (stale rotation ensures baseline coverage)
