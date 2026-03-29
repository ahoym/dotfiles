# Diff-Routed Triage

## Purpose

Diff-routed triage replaces the broad sweep suggestions + staleness rotation approach to deep dive candidacy with surgical targeting. Instead of scanning the full corpus for candidates, it uses `git diff` to identify what changed since the last consolidation, extracts terms from the changes, routes to potentially impacted files via an inverted keyword index (`learnings/.keyword-index.json`), and extends to neighbors via the cross-ref graph. The result is grouped deep dive candidates where curation effort is proportional to change volume, not corpus size. This methodology is consumable by both the interactive `/learnings:consolidate` skill and the autonomous ralph loop.

## Prerequisites

Before triage runs, the following must be in place:

- **`learnings/.keyword-index.json`**: inverted keyword index mapping terms to file paths across all content types (learnings, guidelines, skills, skill-references). Built by housekeeping or initial generation via mechanical extraction.
- **`last_consolidation_commit` in deep-dive tracker**: git commit SHA anchoring the diff. Cold start fallback (see step 1) handles the case where this field is absent.
- **Broad sweeps completed**: triage runs after the L->S->G broad sweep progression. Deep dives are the phase that consumes triage output.

## Triage Steps

### Step 1: Diff Scoping

Run:

```bash
git diff <last_consolidation_commit>..HEAD --name-only -- claude/learnings/ claude/guidelines/ claude/commands/ claude/skill-references/
```

This produces the list of changed files — the seeds for term extraction.

**Cold start** (no `last_consolidation_commit` in tracker): fall back to full-corpus deep dive candidacy (the pre-diff-routing behavior). Set the commit anchor to current HEAD at end of run. This only happens once.

### Step 2: Term Extraction

For each changed file, extract terms from the diff content (`git diff <anchor>..HEAD -- <file>`):

- **H2/H3 headings** added or modified
- **`**Keywords:**` line** if changed
- **Significant terms** from new/modified section content (nouns with stop words removed, same extraction as mechanical index building)
- **Function/concept names** from code blocks

These terms drive the keyword index lookup in the next step.

### Step 3: Index Lookup

Read `learnings/.keyword-index.json`. Match extracted terms against index keys. Files whose keywords overlap with diff terms become **comparison targets** — candidates for loading alongside changed files to detect duplicates, overlaps, and cross-ref opportunities.

### Step 4: Header Sniff

Read first 3 lines of each comparison target (`Read(file_path, limit=3)`). The header block contains:

- Line 1: description (relevance check)
- Line 2: `**Keywords:**` (term matching)
- Line 3: `**Related:**` (graph edges)

Check description and keywords against diff terms. **Drop targets where neither matches** — these are false positives from noisy index terms. Surviving targets proceed to graph extension.

### Step 5: Graph Extension

From each surviving comparison target, follow cross-refs with relevance gating. Extension sources:

- **`**Related:**` from headers** (already sniffed in step 4 — cheap)
- **`## Cross-Refs` from footers** (one tail read per file)
- **Reverse refs**: grep for files that reference the target
- **Persona co-refs**: if a persona lists both the changed file and another file, that other file is in the impact set

At each hop, the agent judges relevance: "given the diff context, is this neighbor actually impacted or just adjacent?" This prevents pulling in the full corpus through densely-connected subgraphs.

- No hard depth limit
- Announce at 3+ hops from the original match
- Stop when a hop's keywords no longer match derived terms

### Step 6: Stale Rotation

Calculate the rotation budget:

```
rotation_slots = max(5, min(15, 20 - diff_routed_files))
```

More changes -> fewer rotation slots (the run is already doing useful work). Fewer changes -> more rotation slots (fill the cheap run with coverage). Total work per run stays roughly constant.

Pick the N least-recently-curated files using `last_deep_dive_run` from the deep-dive tracker. These catch issues that existed before the last run but were never flagged — the "silent drift" gap.

### Step 7: Group Assembly

Organize results into groups, each containing **curation targets** and **comparison context**:

**Curation targets** (3-5 per group): files being actively curated. These get the full curation treatment (classification, action recommendations, enriched keyword extraction). Sources:

- Changed files (from diff)
- Stale rotation picks
- Files flagged for quality issues

**Comparison context** (read-only, unbounded): files pulled in by index lookup and graph extension. Loaded into the same context so the agent can check for duplicates, overlaps, and cross-ref opportunities — but not curated themselves.

**Grouping logic:**

- Changed file + its comparison targets -> same group
- Overlap suspects (keyword collision across clusters) -> same group
- Cross-ref pairs flagged for potential staleness -> same group

Groups with 5+ curation targets split into sub-groups.

## Output Format

Triage produces grouped candidates presented for review before deep dive execution:

```
## Diff-Routed Deep Dive Candidates

### Group 1: [description]

**Curation targets:**
| File | Flag | Reason |
|------|------|--------|
| ralph-loop.md | changed | Modified since last consolidation |
| orchestration.md | stale | Last deep dive: run 8 (current: 16) |

**Comparison context:**
| File | Source |
|------|--------|
| ralph-curation.md | Related: header cross-ref |
| coordination.md | keyword overlap: "worktree", "subagent" |

### Group 2: ...
```

## Enriched Keyword Output Contract

Deep dive subagents must emit an enriched keyword section after their classification table. This is part of the deep dive output, not triage output, but triage sets up the expectation.

```
## Enriched Keywords

| File | Keywords |
|------|----------|
| ralph-loop.md | stateless agent, convergence, worktree sentinel, ... |
```

These are higher quality than mechanical extraction — the agent understands context, synonyms, and which terms are load-bearing vs incidental. Enriched keywords are merged into the keyword index during housekeeping.

## Housekeeping Steps

After deep dives complete, run the following housekeeping:

1. **Rebuild keyword index**: mechanical extraction across all files. For each file: parse `**Keywords:**` header line, split H2/H3 headings into terms, extract significant nouns from body text (stop words removed), normalize (lowercase, strip plurals). Skip files marked `enriched` in `_meta.file_sources` unless modified since last enrichment.

2. **Merge enriched keywords**: incorporate enriched keyword output from deep dive subagents into the index. Update `_meta.file_sources` to mark these files as `enriched`.

3. **Update `last_consolidation_commit`**: set to current HEAD in deep-dive tracker. This anchors the next run's diff.

4. **Update `last_deep_dive_run`**: set to current `run_count` for all files that were curated (curation targets across all groups).

5. **Update `last_change_run`**: set to current `run_count` for all files that appeared in the diff (regardless of whether they were curated). Enables "changed in run 12 but not deep-dived since run 8" prioritization in future runs.
