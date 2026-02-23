---
description: "Exhaustive multi-sweep curation — auto-applies HIGH-confidence recommendations, batches MEDIUMs for approval, loops until fully distilled. Orchestrates repeated learnings:curate sweeps."
---

# Consolidate Learnings

Run exhaustive multi-sweep curation of all learnings, guidelines, and skills. Automatically applies HIGH-confidence recommendations and batches MEDIUMs for approval, looping until the collection is fully distilled.

This skill orchestrates multiple invocations of the `/learnings:curate` broad sweep methodology. It owns the loop and approval flow; `/learnings:curate` owns the analysis methodology.

## Usage

- `/learnings:consolidate` — Full consolidation run (no arguments, always broad sweep)

For targeted single-file curation, use `/learnings:curate <file>` instead.

## Reference Files (conditional — read only when needed)

This skill delegates analysis methodology to learnings:curate. Read these files at the steps indicated:

- `../curate/SKILL.md` — Read at Step 0. Contains broad sweep analysis methodology, classification steps, cross-referencing, and report formats. Follow its analysis steps (1 through 6) for each sweep, but replace its approval flow (step 7) with the loop defined below.
- `../curate/classification-model.md` — Read via learnings:curate step 4. Contains the 6-bucket classification model and confidence level definitions.
- `../curate/persona-design.md` — Read when persona clusters are detected during a sweep (via learnings:curate step 5a).
- `~/.claude/commands/learnings/compound/content-type-decisions.md` — Read via learnings:curate step 4. Skill vs guideline vs learning decision tree.

## State Variables

Track these across all sweeps:

| Variable | Purpose | Initial |
|----------|---------|---------|
| `SWEEP_COUNT` | Total sweeps executed across all phases | 0 |
| `PHASE` | Current phase: `HIGH_SWEEP`, `MEDIUM_BATCH`, `VERIFICATION` | `HIGH_SWEEP` |
| `CUMULATIVE_ACTIONS` | All actions applied across all sweeps — each with: sweep number, action type, source, target, confidence | Empty list |
| `HIGH_SWEEP_COUNT` | Sweeps within the current Phase 1 run | 0 |
| `PHASE_TRANSITIONS` | Log of phase transitions with sweep number and reason | Empty list |

## Instructions

### Step 0: Load methodology

Read `../curate/SKILL.md` to internalize the broad sweep analysis methodology. You will follow its analysis steps (steps 1 through 6, broad sweep mode) for each sweep below, but replace its approval flow (step 7) with the automated loop defined in this skill.

Key points from learnings:curate to apply on every sweep:
- Always use **broad sweep mode** (cluster-first approach)
- Pre-load the full reference corpus (skills, guidelines, personas)
- Use **parallel tool calls aggressively** (per-cluster subagents, parallel reads)
- Cross-reference thoroughly before classifying
- After clustering, run **concept-name collision detection**: grep for identical or near-identical H2/H3 headings across all files. Flag matches as HIGH-confidence duplicate candidates regardless of cluster membership. This catches cross-file duplicates that cluster-level analysis misses.
- Use the broad sweep report format

### Step 1: Phase 1 — HIGH Sweep Loop

**Goal:** Automatically apply all HIGH-confidence recommendations until none remain.

**Loop** (max 5 iterations):

1. **Run broad sweep analysis** — follow learnings:curate steps 1–6 (broad sweep mode). Generate the full broad sweep report.

2. **Separate findings by confidence:**
   - `HIGH_FINDINGS` — classifications with High confidence
   - `MEDIUM_FINDINGS` — classifications with Medium confidence (noted, NOT acted on yet)
   - `LOW_FINDINGS` — classifications with Low confidence (noted, NOT acted on)

3. **Check termination conditions:**
   - If `HIGH_FINDINGS` is empty → Phase 1 complete. Log transition, proceed to **Step 2**.
   - If `HIGH_SWEEP_COUNT` >= 5 → safety cap reached. Display the cap report (see Edge Cases) and pause for user input.

4. **Display between-sweep report:**

   ```
   ## Sweep N (Phase 1: HIGHs)

   ### HIGH-Confidence Actions (auto-applying)

   | # | Action | Source | Target | Detail |
   |---|--------|--------|--------|--------|
   | 1 | Fold thin file | observability-workflow.md | java-devops persona | 14 lines, mostly pointers |
   | 2 | Delete outdated | v1-spec-structure | — | Superseded by v2 in same file |

   ### Deferred
   - N MEDIUM items noted (fresh analysis after HIGHs exhausted)
   - M LOW items noted

   Applying N HIGH actions...
   ```

5. **Auto-apply all HIGH actions** — execute the actions from learnings:curate step 7 (apply changes), but **without user confirmation**. Use parallel tool calls for independent file writes (different target files). Sequential writes for actions targeting the same file.

6. **Record actions** — append each applied action to `CUMULATIVE_ACTIONS` with sweep number, action type, source, target, and confidence.

7. **Increment counters** — `SWEEP_COUNT += 1`, `HIGH_SWEEP_COUNT += 1`.

8. **Loop** — return to substep 1 for a fresh sweep.

### Step 2: Phase 2 — MEDIUM Batch

**Goal:** Present all current MEDIUM-confidence recommendations as a single batch for user approval.

**Important:** Do NOT reuse MEDIUMs accumulated during Phase 1 sweeps when HIGHs were applied — the state has changed and needs fresh analysis.

1. **Determine whether re-analysis is needed:**
   - If Phase 1 applied any HIGH actions → state changed. Run fresh broad sweep analysis (learnings:curate steps 1–6). Increment `SWEEP_COUNT`.
   - If Phase 1 applied zero actions (no HIGHs found on first sweep) → state is unchanged. The MEDIUMs from the Phase 1 sweep are already current — skip re-analysis and use them directly.

2. **If fresh sweep found new HIGHs:** Auto-apply them inline before extracting MEDIUMs — same procedure as Phase 1 substep 5 (parallel tool calls, record to `CUMULATIVE_ACTIONS`). This avoids cycling back to Phase 1 for HIGHs that only became visible after Phase 1 changes. Display them in the between-sweep report format before the MEDIUM batch.

3. **Extract `MEDIUM_FINDINGS`** from the results (fresh or carried forward).

4. **Check if empty:** If no MEDIUMs found → skip to **Step 3**.

5. **Present MEDIUM batch for approval:**

   ```
   ## Phase 2: MEDIUM-Confidence Recommendations

   These items are likely correct but have some ambiguity. Review and select which to apply.

   | # | Action | Source | Target | Rationale | Concern |
   |---|--------|--------|--------|-----------|---------|
   | 1 | Enhance persona | 4 spring patterns | java-backend | Partial match, new gotchas | Some patterns may be too project-specific |
   | 2 | Genericize | api-design: Response Shapes | Keep | Contains hardcoded project paths | Check if examples are still useful |
   ```

   Use `AskUserQuestion` with multi-select. Include rationale and concern in each option's `description` field.

   **Always include options:**
   - Each MEDIUM item as a selectable option
   - A **Discuss** description note — "Select items you want to discuss before deciding"
   - A **Skip all** option — user may decide the current state is good enough

   **Also present LOW items for awareness** (not selectable, just informational):

   ```
   ### LOW-Confidence Items (for reference)

   | # | Item | Why LOW |
   |---|------|---------|
   | 1 | ... | Multiple classifications could fit |
   ```

6. **Apply approved MEDIUMs** — execute selected actions. Parallel tool calls for independent file writes.

7. **Record actions** — append to `CUMULATIVE_ACTIONS`.

8. **Log transition** — add to `PHASE_TRANSITIONS`.

### Step 3: Phase 3 — Post-MEDIUM Verification

**Goal:** Check whether changes surfaced new insights.

1. **Check for short-circuit:** If ALL Phase 2 actions were in-place modifications (no files created, deleted, or moved; no content migrated between files), skip verification entirely — in-place edits (genericization, section merges, compression) cannot create new overlaps or classification changes. Log: "Skipping verification — all Phase 2 actions were in-place modifications." Proceed directly to **Step 4**.

2. **Check overall safety cap:** If `SWEEP_COUNT` >= 10 → display overall cap report (see Edge Cases) and pause.

3. **Determine verification scope** based on the actions applied in Phase 2:

   **Lightweight verification** — use when ALL of these are true:
   - Actions only modified content within existing files (no files created, deleted, or moved)
   - No content was migrated between files (no cross-file effects)
   - Changes are self-contained (removing a section, trimming content, genericizing examples)

   For lightweight verification:
   - For each changed file, check whether the edit created broken cross-references (other files pointing to removed content)
   - Confirm no other file's classification would change based on the edits
   - This is a targeted check, not a full re-read of the corpus. Increment `SWEEP_COUNT`.

   **Full verification** — use when ANY of these are true:
   - Content was moved between files (folded into persona, migrated to skill)
   - Files were created or deleted
   - A persona was enhanced or created (changes what gets cross-referenced in future sweeps)

   For full verification:
   - Run fresh broad sweep analysis (learnings:curate steps 1–6). Increment `SWEEP_COUNT`.

4. **Evaluate results:**
   - **New HIGHs found** → log transition: "Changes surfaced N new HIGH items." Reset `HIGH_SWEEP_COUNT` to 0. Return to **Step 1**.
   - **New MEDIUMs found** → log transition: "Changes surfaced N new MEDIUM items." Return to **Step 2**.
   - **Clean sweep** (no HIGHs or MEDIUMs) → proceed to **Step 4**.

### Step 4: Cumulative Summary

Generate the final consolidation report:

```
## 🏁 Consolidation Complete

### Execution Summary

| Metric | Value |
|--------|-------|
| Total sweeps | N |
| Phase 1 (HIGH) sweeps | N |
| Phase 2 (MEDIUM) batches | N |
| Phase 3 (Verification) sweeps | N |
| Total actions applied | N |

### Actions by Type

| Action Type | Count | Examples |
|-------------|-------|---------|
| Folded thin files | 3 | observability-workflow.md → java-devops, ... |
| Deleted outdated | 2 | v1-spec-structure, ... |
| Enhanced personas | 1 | java-backend (+4 gotchas) |
| Created personas | 0 | — |
| Migrated to skills | 1 | comparison-template → ralph:init |
| Migrated to guidelines | 0 | — |
| Genericized | 2 | api-design: Response Shapes, ... |

### Phase Transition Log

| Sweep | From | To | Reason |
|-------|------|----|--------|
| 3 | HIGH_SWEEP | MEDIUM_BATCH | No more HIGHs found |
| 5 | MEDIUM_BATCH | VERIFICATION | User approved 4 of 6 MEDIUMs |
| 6 | VERIFICATION | DONE | Clean sweep |

### Actions Detail (chronological)

| Sweep | # | Action | Source | Target | Confidence |
|-------|---|--------|--------|--------|------------|
| 1 | 1 | Fold thin file | observability-workflow.md | java-devops persona | High |
| 1 | 2 | Delete outdated | v1-spec-structure | — | High |
| 2 | 3 | Enhance persona | spring-patterns (4 items) | java-backend | High |
| ... | | | | | |

### Remaining Items (not actioned)

| # | Item | Confidence | Reason |
|---|------|------------|--------|
| 1 | ... | Medium | User skipped |
| 2 | ... | Low | Below threshold |

### Collection Health

- **Files**: N learnings, M guidelines, K skills, J personas
- **Status**: [Fully curated | N items remaining for manual review]
```

## Edge Cases

### First sweep finds nothing

If the very first sweep returns no HIGH or MEDIUM items, skip directly to Step 4. **Lead with LOW items** — on a clean sweep, polish opportunities are the primary value of the run. Don't bury them after a "no action needed" headline that signals completion.

```
## 🏁 Consolidation Complete

Swept N files (~M patterns). No HIGH or MEDIUM recommendations.

### Polish Opportunities

These won't break anything as-is, but could improve the collection:

| # | File | Opportunity | Tradeoff |
|---|------|-------------|----------|
| 1 | playwright-patterns.md | Genericize XRPL contextual references | Provenance notes only, code examples already generic |
| 2 | trade-page-patterns.md | Genericize XRPL implementation details | Small file, domain context adds teaching value |

Use `/learnings:curate <file>` to act on any of these.

### Collection Health

- **Files**: N learnings, M guidelines, K skills, J personas
- **Status**: Curated — N polish items noted above
```

If there are truly zero LOWs either, use this minimal variant:

```
## 🏁 Consolidation Complete

Swept N files (~M patterns). No recommendations at any confidence level.

Collection is fully curated. ✅
```

### HIGHs keep cascading (Phase 1 cap hit)

If 5 HIGH sweeps complete and new HIGHs keep appearing:

```
## ⚠️ Phase 1 Safety Cap: 5 HIGH sweeps completed

Actions are creating cascading changes (e.g., folding content surfaces new overlaps).

### Sweep History
| Sweep | HIGHs Found | HIGHs Applied |
|-------|-------------|---------------|
| 1 | 8 | 8 |
| 2 | 3 | 3 |
| ... | | |

### Remaining HIGHs
| # | Action | Source | Target |
|---|--------|--------|--------|
| ... | | | |
```

Use `AskUserQuestion`:
- **Continue** — "Run 5 more HIGH sweeps"
- **Downgrade to MEDIUMs** — "Move remaining HIGHs to Phase 2 for manual review"
- **Stop here** — "End consolidation, show summary of what was applied"

### Overall safety cap (10 sweeps)

```
## ⚠️ Overall Safety Cap: 10 sweeps completed

### Current State
- N remaining MEDIUM items
- M remaining LOW items
- K total actions applied

The collection may have diminishing-return items that keep surfacing.
```

Use `AskUserQuestion`:
- **Continue** — "Run 5 more sweeps"
- **Stop here** — "End consolidation with current results"

### Phase cycle repeats 2+ times

If the Phase 1 → Phase 2 → Phase 3 → Phase 1 cycle completes more than twice:

```
## ℹ️ Cycle Check: Round N through the full cycle

Each round of changes keeps surfacing new recommendations.

Remaining: N HIGHs, M MEDIUMs
```

Use `AskUserQuestion`:
- **Continue** — "Keep going"
- **Apply HIGHs only and stop** — "Auto-apply remaining HIGHs, skip MEDIUMs, show summary"
- **Stop here** — "End consolidation with current results"

## Important Notes

- **Always broad sweep** — this skill does not support targeted files. Use `/learnings:curate <file>` for that.
- **HIGHs are auto-applied** — that's the value proposition. If uncomfortable, use `/learnings:curate` instead.
- **MEDIUMs always get approval** — the batch in Phase 2 is the primary user interaction point.
- **LOWs are never auto-applied** — they appear in reports for awareness but require explicit `/learnings:curate` runs.
- **Fresh analysis per phase** — MEDIUMs are NOT accumulated across sweeps. Each transition triggers fresh analysis because state has changed.
- **Methodology delegation** — this skill orchestrates the loop; `/learnings:curate` owns the analysis. Changes to learnings:curate automatically flow through.

## Prerequisites

For prompt-free execution, add these allow patterns to `~/.claude/settings.local.json`:

```json
"Read(~/.claude/commands/**)",
"Read(~/.claude/learnings/**)",
"Read(~/.claude/guidelines/**)",
"Write(~/.claude/commands/**)",
"Write(~/.claude/learnings/**)",
"Write(~/.claude/guidelines/**)",
"Edit(~/.claude/commands/**)",
"Edit(~/.claude/learnings/**)",
"Edit(~/.claude/guidelines/**)"
```

## Related Skills

| Workflow | Skill |
|----------|-------|
| Curate a specific file | `/learnings:curate <file>` |
| Capture learnings from a session | `/learnings:compound` |
| Pull learnings from sync source | `/quantum-tunnel-claudes` |
| Distribute learnings to a project | `/learnings:distribute` |
