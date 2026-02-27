---
name: consolidate
description: "Run exhaustive multi-sweep curation of all learnings, skills, and guidelines — auto-applies high-confidence recommendations and batches others for approval."
disable-model-invocation: true
---

# Consolidate Learnings, Skills & Guidelines

Run exhaustive multi-sweep curation of all learnings, skills, and guidelines. Each content type is swept in sequence — learnings first (most commonly migrate into other types), then skills (merges/prunes affect guideline evaluation), then guidelines (benefits from all prior cleanup). Automatically applies HIGH-confidence recommendations and batches MEDIUMs for approval, looping until each content type is fully distilled.

This skill orchestrates multiple invocations of the `/learnings:curate` methodology. It owns the loop, content type progression, and approval flow; `/learnings:curate` owns the analysis methodology.

## Usage

- `/learnings:consolidate` — Full consolidation run (no arguments, always broad sweep)

For targeted single-file curation, use `/learnings:curate <file>` instead.

## Reference Files (conditional — read only when needed)

This skill delegates analysis methodology to learnings:curate. Read these files at the steps indicated:

- `../curate/SKILL.md` — Read at Step 0. Contains broad sweep analysis methodology (learnings), skill mode methodology (2s–4s), and content mode methodology (2–5a). Follow its analysis steps for each sweep, but replace its approval flow (step 7) with the loop defined below.
- `../curate/classification-model.md` — Read via learnings:curate step 4. Contains the 6-bucket classification model and confidence level definitions.
- `../curate/persona-design.md` — Read when persona clusters are detected during a sweep (via learnings:curate step 5a).
- `~/.claude/commands/learnings/compound/content-type-decisions.md` — Read via learnings:curate step 4. Skill vs guideline vs learning decision tree.

## State Variables

Track these across all sweeps:

| Variable | Purpose | Initial |
|----------|---------|---------|
| `SWEEP_COUNT` | Total sweeps executed across all phases and content types | 0 |
| `PHASE` | Current phase: `HIGH_SWEEP`, `MEDIUM_BATCH`, `VERIFICATION`, `DEEP_DIVE` | `HIGH_SWEEP` |
| `CONTENT_TYPE` | Current content type: `LEARNINGS`, `SKILLS`, `GUIDELINES` | `LEARNINGS` |
| `CUMULATIVE_ACTIONS` | All actions across all sweeps — each with: sweep number, content type, action type, source, target, confidence | Empty list |
| `HIGH_SWEEP_COUNT` | Sweeps within the current HIGH_SWEEP phase (resets per content type) | 0 |
| `PHASE_TRANSITIONS` | Log of phase transitions with sweep number, content type, and reason | Empty list |
| `CONTENT_TYPE_SUMMARIES` | Per-type action counts and sweep counts for final summary | Empty map |
| `DEEP_DIVE_CANDIDATES` | Files flagged by broad sweep's "Suggested Deep Dives" | Empty list |
| `DEEP_DIVE_SWEEP_COUNT` | Deep dive sweeps for current content type (resets per type) | 0 |

## Instructions

### Step 0: Load methodology

Read `../curate/SKILL.md` to internalize all analysis methodologies. You will follow its analysis steps for each sweep below, but replace its approval flow (step 7) with the automated loop defined in this skill.

Key points from learnings:curate to apply on every sweep:
- **Learnings sweeps** use **broad sweep mode** (cluster-first approach, steps 1–6 broad sweep)
- **Skills sweeps** use **skill mode** (steps 2s–4s: read skill package, evaluate, classify)
- **Guidelines sweeps** use **content mode** (steps 2–5a: parse, cross-reference, classify)
- Pre-load the full reference corpus (skills, guidelines, personas) — this shared corpus benefits all content types
- Use **parallel tool calls aggressively** (per-cluster subagents, parallel reads)
- Cross-reference thoroughly before classifying
- After clustering (learnings phase), run **concept-name collision detection**: grep for identical or near-identical H2/H3 headings across all files. Flag matches as HIGH-confidence duplicate candidates regardless of cluster membership. This catches cross-file duplicates that cluster-level analysis misses.
- Use the appropriate report format for each content type
- **Deep dive candidates** are extracted from the broad sweep report's "Suggested Deep Dives" section. After clean VERIFICATION, run targeted per-file analysis via subagents. Only applies to LEARNINGS and GUIDELINES — skills use skill mode (per-skill evaluation), not per-pattern analysis.

### Content Type Progression

Content types are swept in fixed order: **LEARNINGS → SKILLS → GUIDELINES**. This ordering maximizes value — learnings most commonly migrate into skills/guidelines, and skill merges/prunes affect guideline evaluation.

**Transition between content types:**

1. **Record summary** — save the current content type's action counts, sweep counts, and findings to `CONTENT_TYPE_SUMMARIES`.
2. **Reset phase counters** — set `PHASE` to `HIGH_SWEEP`, `HIGH_SWEEP_COUNT` to 0, `DEEP_DIVE_CANDIDATES` to empty, `DEEP_DIVE_SWEEP_COUNT` to 0.
3. **Refresh modified corpus** — re-read only the files that were modified by the prior content type's phases. This is lighter than a full corpus re-read but ensures subsequent analysis reflects current state.
4. **Advance `CONTENT_TYPE`** — move to the next content type.
5. **Check for skip** — if the content type has no files to sweep (e.g., no skills exist), log "No [type] files found, skipping" and advance to the next.

After the final content type completes (GUIDELINES), proceed to the Cumulative Summary (Step 6).

---

### Step 1: Learnings — HIGH Sweep Loop

**Goal:** Automatically apply all HIGH-confidence recommendations until none remain.

**Loop** (max 5 iterations):

1. **Run broad sweep analysis** — follow learnings:curate steps 1–6 (broad sweep mode). Generate the full broad sweep report. Extract any "Suggested Deep Dives" entries into `DEEP_DIVE_CANDIDATES` (overwrite previous — state changes invalidate earlier suggestions).

2. **Separate findings by confidence:**
   - `HIGH_FINDINGS` — classifications with High confidence
   - `MEDIUM_FINDINGS` — classifications with Medium confidence (noted, NOT acted on yet)
   - `LOW_FINDINGS` — classifications with Low confidence (noted, NOT acted on)

3. **Check termination conditions:**
   - If `HIGH_FINDINGS` is empty → Phase 1 complete. Log transition, proceed to **Step 2**.
   - If `HIGH_SWEEP_COUNT` >= 5 → safety cap reached. Display the cap report (see Edge Cases) and pause for user input.

4. **Display between-sweep report:**

   ```
   ## Sweep N (Learnings — Phase 1: HIGHs)

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

6. **Record actions** — append each applied action to `CUMULATIVE_ACTIONS` with sweep number, content type (`LEARNINGS`), action type, source, target, and confidence.

7. **Increment counters** — `SWEEP_COUNT += 1`, `HIGH_SWEEP_COUNT += 1`.

8. **Loop** — return to substep 1 for a fresh sweep.

### Step 2: Learnings — MEDIUM Batch

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
   ## Learnings — Phase 2: MEDIUM-Confidence Recommendations

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

### Step 3: Learnings — Post-MEDIUM Verification

**Goal:** Check whether changes surfaced new insights.

1. **Check for short-circuit:** If ALL Phase 2 actions were in-place modifications (no files created, deleted, or moved; no content migrated between files), skip verification entirely — in-place edits (genericization, section merges, compression) cannot create new overlaps or classification changes. Log: "Skipping verification — all Phase 2 actions were in-place modifications." Proceed to **Step 4** (Skills sweep).

2. **Check overall safety cap:** If `SWEEP_COUNT` >= 15 → display overall cap report (see Edge Cases) and pause.

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
   - **Clean sweep** (no HIGHs or MEDIUMs) → check `DEEP_DIVE_CANDIDATES`. If non-empty and content type is LEARNINGS, proceed to **Step 1d** (Deep Dive). If empty or content type is SKILLS, record summary and proceed to next content type.

### Step 1d: Learnings Deep Dive Phase

**Goal:** Run targeted per-file analysis on files flagged during the broad sweep, catching within-file opportunities (compression, genericization, section-level reorganization) that broad sweeps miss.

Set `PHASE` to `DEEP_DIVE`.

1. **Check candidates** — if `DEEP_DIVE_CANDIDATES` is empty, log "No deep dive candidates — proceeding to next content type." and proceed. This is the common case.

2. **Display plan:**

   ```
   ## Deep Dive Phase (Learnings)

   | # | File | Patterns | Reason |
   |---|------|----------|--------|
   | 1 | parallel-plans.md | 8 | 2 medium-confidence items, 3 new sections |
   | 2 | skill-design.md | 11 | Several skill-context candidates |
   ```

3. **Safety cap budget check** — if `SWEEP_COUNT` >= 13 before launching, warn and use `AskUserQuestion`:
   - **Run deep dives** — "Proceed with deep dive analysis (budget: N sweeps remaining)"
   - **Skip and list** — "Skip deep dives, list files for manual `/learnings:curate <file>`"
   - **Skip entirely** — "Skip deep dives, proceed to next content type"

4. **Launch subagents** — one Task subagent per candidate file (parallel, max 5 concurrent). Each subagent runs learnings:curate content mode (steps 2–5a) on its file with the pre-loaded corpus. Subagents return per-pattern classification tables — they analyze and report, they do NOT apply changes.

5. **Merge results** — collect classification tables across subagents. Separate into HIGH_FINDINGS, MEDIUM_FINDINGS, LOW_FINDINGS. Remove candidates where the subagent returned no findings (log "classification confirmed" for each).

6. **Deep dive HIGH sweep** (max 3 iterations, tracked by `DEEP_DIVE_SWEEP_COUNT`):
   - If no HIGHs → skip to substep 7.
   - Auto-apply HIGHs. Display between-sweep report:

   ```
   ## Sweep N ([Content Type] — Deep Dive HIGHs)

   | # | File | Pattern | Action | Target | Detail |
   |---|------|---------|--------|--------|--------|
   | 1 | parallel-plans.md | Retry Strategies | Fold | error-handling.md | Duplicate of existing section |
   ```

   - Record actions to `CUMULATIVE_ACTIONS`. Increment `SWEEP_COUNT` and `DEEP_DIVE_SWEEP_COUNT`.
   - Re-run subagents only for affected files. If `DEEP_DIVE_SWEEP_COUNT` >= 3, stop and move remaining HIGHs to MEDIUM batch.

7. **Deep dive MEDIUM batch** — present all MEDIUMs across files in a single `AskUserQuestion` (multi-select):

   ```
   ## [Content Type] — Deep Dive MEDIUMs

   | # | File | Pattern | Action | Target | Rationale | Concern |
   |---|------|---------|--------|--------|-----------|---------|
   | 1 | skill-design.md | Naming Conventions | Genericize | Keep | Hardcoded project names | Context may aid recall |
   | 2 | parallel-plans.md | DAG Scheduling | Compress | Keep | 40% compression achievable | May lose edge case detail |
   ```

   Include LOWs for reference (not selectable). Include **Discuss** and **Skip All** options.

   Apply approved MEDIUMs. Record to `CUMULATIVE_ACTIONS`.

8. **Lightweight verification** — check for broken cross-references in modified files only. If cross-file effects occurred (content migrated to files outside the deep-dived set), log them:

   ```
   ### Cross-File Effects
   Deep dive actions modified files outside the deep-dived set:
   - <file> (received content from <source pattern>)
   These will be evaluated in subsequent consolidation runs.
   ```

   Do NOT trigger a broad re-sweep.

9. **Record and transition** — save deep dive results to `CONTENT_TYPE_SUMMARIES`. Proceed to next content type.

---

### Step 4: Skills Sweep

**Goal:** Evaluate all skills for overlap, staleness, and scope issues using learnings:curate's skill mode methodology.

**No deep dive phase for skills.** Skills use skill mode (per-skill evaluation), not per-pattern analysis.

#### 4a. Cluster skills by prefix

Group all skill directories under `~/.claude/commands/` by their namespace prefix. Also check `~/.claude/lab/` for automation scripts (e.g., `wiggum.sh`) that aren't skill-registered but are part of the tooling surface — the skill loader only discovers `commands/`, so content elsewhere needs explicit scanning.

| Cluster | Skills |
|---------|--------|
| `git:*` | git:split-pr, git:cascade-rebase, git:create-pr, ... |
| `learnings:*` | learnings:curate, learnings:compound, learnings:consolidate, ... |
| `ralph:*` | ralph:init, ralph:compare |
| `parallel-plan:*` | parallel-plan:make, parallel-plan:execute |
| Standalone | do-refactor-code, do-security-audit, explore-repo, set-persona, ... |

This clustering enables cross-skill overlap detection within namespaces.

#### 4b. Evaluate each skill

For each skill, follow learnings:curate skill mode (steps 2s–4s) with full cross-skill context:

1. Read the skill package (SKILL.md + reference files)
2. Evaluate against pruning criteria (relevance, overlap, complexity vs value, reference freshness, scope)
3. Classify: Keep, Enhance, Merge, Split, or Prune

**Cross-skill context:** When evaluating a skill, consider other skills in its cluster. Flag:
- Significant overlap between skills in the same namespace (merge candidates)
- Shared reference files that could be deduplicated
- Skills that are subsets of other skills (merge or prune candidates)
- Namespace gaps (missing skills that would complete a workflow)

**Inline analysis** for the current collection size (~23 skills). Use subagents for collections of 30+.

**Additional cross-cutting checks** (run after individual skill evaluation):
- **Stale model version strings:** Grep all skill directories for `Co-Authored-By` and `Co-authored with` lines with outdated model versions (e.g., previous model generation). Bulk-update matches.
- **Post-prune cross-reference cleanup:** After any Prune action is applied, grep remaining skills for the deleted skill's name — check "Related Skills" tables, usage examples, and conditional workflows. Flag stale references as HIGH-confidence follow-up actions.

#### 4c. Separate findings by confidence

Same as learnings phase — split into HIGH_FINDINGS, MEDIUM_FINDINGS, LOW_FINDINGS.

#### 4d. HIGH/MEDIUM/VERIFICATION loop

Run the same three-phase loop as learnings (Steps 1–3 pattern), with these differences:

**Between-sweep report format:**
```
## Sweep N (Skills — Phase 1: HIGHs)

### HIGH-Confidence Actions (auto-applying)

| # | Action | Skill | Target | Detail |
|---|--------|-------|--------|--------|
| 1 | Merge | git:monitor-pr-comments | git:address-pr-review | 80% overlap, monitoring is subset |
| 2 | Prune | deprecated-skill | — | References removed code |

### Deferred
- N MEDIUM items noted
- M LOW items noted
```

**MEDIUM batch format:**
```
## Skills — Phase 2: MEDIUM-Confidence Recommendations

| # | Action | Skill | Target | Rationale | Concern |
|---|--------|-------|--------|-----------|---------|
| 1 | Enhance | ralph:init | — | Missing error recovery patterns | May over-complicate the skill |
| 2 | Split | do-security-audit | do-security-audit, do-dependency-audit | Two distinct workflows | Shared reference files need duplication |
```

**Skill-specific actions:** Prune, Merge, Enhance, Split, Keep (from learnings:curate 4s).

After skills sweep completes (clean sweep or all phases done), record skills summary and proceed to **Step 5** (Guidelines sweep).

---

### Step 5: Guidelines Sweep

**Goal:** Evaluate all guidelines for redundancy, scope, cost, and wiring issues using learnings:curate's content mode methodology.

#### 5a. Evaluate each guideline

For each file in `~/.claude/guidelines/`, follow learnings:curate content mode (steps 2–5a) with these **additional checks**:

| Check | What to look for |
|-------|-----------------|
| **`@`-reference cost** | Is this guideline `@`-referenced in CLAUDE.md? If so, every token is always-on cost. Does all content need to be always-on, or could parts move to conditional references? |
| **Wiring check** | Is this guideline referenced anywhere (CLAUDE.md, skills, other guidelines)? An unwired guideline may be dead weight. |
| **Behavioral vs reference** | Does the guideline define behavior (how to communicate, code style) vs reference material (API patterns, framework specifics)? Reference material is often better as a conditional skill reference file. |
| **Domain-specific → learnings or persona** | Does the guideline contain domain-specific knowledge (gotchas, facts) that belongs in a learnings file? Or domain-specific *judgment* (tradeoffs, review posture) that belongs in a persona? Knowledge → learnings (for dynamic pulling). Lens → persona. See `context-aware-learnings` guideline. |

#### 5b–5c. HIGH/MEDIUM/VERIFICATION loop

Run the same three-phase loop as learnings (Steps 1–3 pattern), with these differences:

**Between-sweep report format:**
```
## Sweep N (Guidelines — Phase 1: HIGHs)

### HIGH-Confidence Actions (auto-applying)

| # | Action | Guideline | Target | Detail |
|---|--------|-----------|--------|--------|
| 1 | Extract to conditional | communication.md §API patterns | skill reference file | Always-on cost for rarely-needed content |
| 2 | Migrate to persona | code-style.md §Java conventions | java-backend persona | Domain-specific, not universal |

### Deferred
- N MEDIUM items noted
- M LOW items noted
```

**MEDIUM batch format:**
```
## Guidelines — Phase 2: MEDIUM-Confidence Recommendations

| # | Action | Guideline | Target | Rationale | Concern |
|---|--------|-----------|--------|-----------|---------|
| 1 | Compress | communication.md | — | 30%+ compression achievable | May lose nuance |
| 2 | Unwired, delete? | old-patterns.md | — | No references found | May be used implicitly |
```

**Guideline-specific actions:** Compress, Extract to conditional, Migrate to persona, Delete unwired, Keep (standard content mode classifications plus the additional checks above).

After the guidelines VERIFICATION loop exits clean: check `DEEP_DIVE_CANDIDATES`. If non-empty, run the same deep dive phase as Step 1d (substituting GUIDELINES for the content type). If empty, proceed to **Step 6**.

After guidelines sweep completes (including any deep dive phase), proceed to **Step 6** (Cumulative Summary).

---

### Step 6: Cumulative Summary

Generate the final consolidation report:

```
## 🏁 Consolidation Complete

### Execution Summary

| Content Type | Sweeps | HIGH Applied | MEDIUM Applied | MEDIUM Skipped | Deep Dives |
|--------------|--------|--------------|----------------|----------------|------------|
| Learnings | N | N | N | N | N files |
| Skills | N | N | N | N | — |
| Guidelines | N | N | N | N | N files |
| **Total** | **N** | **N** | **N** | **N** | **N** |

### Actions by Type

| Action Type | Content Type | Count | Examples |
|-------------|--------------|-------|---------|
| Folded thin files | Learnings | 3 | observability-workflow.md → java-devops, ... |
| Deleted outdated | Learnings | 2 | v1-spec-structure, ... |
| Enhanced personas | Learnings | 1 | java-backend (+4 gotchas) |
| Merged skills | Skills | 1 | git:monitor-pr-comments → git:address-pr-review |
| Pruned skills | Skills | 1 | deprecated-skill |
| Extracted to conditional | Guidelines | 1 | communication.md §API patterns |
| Compressed | Guidelines | 2 | code-style.md, ... |

### Phase Transition Log

| Sweep | Content Type | From | To | Reason |
|-------|--------------|------|----|--------|
| 3 | Learnings | HIGH_SWEEP | MEDIUM_BATCH | No more HIGHs found |
| 5 | Learnings | MEDIUM_BATCH | VERIFICATION | User approved 4 of 6 MEDIUMs |
| 6 | Learnings | VERIFICATION | DONE | Clean sweep |
| 7 | Skills | HIGH_SWEEP | MEDIUM_BATCH | No more HIGHs found |
| ... | | | | |

### Actions Detail (chronological)

| Sweep | Content Type | # | Action | Source | Target | Confidence |
|-------|--------------|---|--------|--------|--------|------------|
| 1 | Learnings | 1 | Fold thin file | observability-workflow.md | java-devops persona | High |
| 1 | Learnings | 2 | Delete outdated | v1-spec-structure | — | High |
| 7 | Skills | 5 | Merge | git:monitor-pr-comments | git:address-pr-review | High |
| ... | | | | | | |

### Deep Dive Detail

| Content Type | File | Patterns | HIGHs | MEDIUMs Applied | MEDIUMs Skipped |
|--------------|------|----------|-------|-----------------|-----------------|
| Learnings | parallel-plans.md | 8 | 1 | 2 | 0 |
| Guidelines | communication.md | 5 | 0 | 1 | 1 |

### Remaining Items (not actioned)

| # | Content Type | Item | Confidence | Reason |
|---|--------------|------|------------|--------|
| 1 | Learnings | ... | Medium | User skipped |
| 2 | Skills | ... | Low | Below threshold |

### Collection Health

- **Learnings**: N files, ~M patterns
- **Skills**: K skill directories
- **Guidelines**: J guideline files
- **Personas**: P persona files
- **Status**: [Fully curated | N items remaining for manual review]
```

## Edge Cases

### Learnings sweep finds nothing

If the very first learnings sweep returns no HIGH or MEDIUM items, proceed to the skills sweep (Step 4) — don't stop the entire consolidation. **Lead with LOW items** — on a clean sweep, polish opportunities are the primary value. Don't bury them after a "no action needed" headline that signals completion.

Polish Opportunities are populated from the curate sweep's **per-file quality scan** (step 5b). If the quality scan found no candidates, omit this section and use the shorter "no actionable recommendations" format.

```
## Learnings: Clean

Swept N files (~M patterns). No HIGH or MEDIUM recommendations.

### Polish Opportunities

These won't break anything as-is, but could improve the collection:

| # | File | Opportunity | Tradeoff |
|---|------|-------------|----------|
| 1 | playwright-patterns.md | Genericize XRPL contextual references | Provenance notes only, code examples already generic |
| 2 | trade-page-patterns.md | Genericize XRPL implementation details | Small file, domain context adds teaching value |

Use `/learnings:curate <file>` to act on any of these.

Proceeding to skills sweep...
```

### Content type has no actionable findings

If a content type's first sweep returns no HIGH or MEDIUM items, log a brief summary and skip to the next content type:

```
## [Content Type]: Clean

Swept N items. No actionable recommendations. Proceeding to [next type]...
```

### All content types clean

If all three content types produce no actionable findings:

```
## 🏁 Consolidation Complete

Swept all content types:
- Learnings: N files (~M patterns) — clean
- Skills: K skills — clean
- Guidelines: J files — clean

No recommendations at any confidence level. Collection is fully curated. ✅
```

### HIGHs keep cascading (Phase 1 cap hit)

If 5 HIGH sweeps complete and new HIGHs keep appearing:

```
## ⚠️ Phase 1 Safety Cap: 5 HIGH sweeps completed ([Content Type])

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

### Overall safety cap (15 sweeps)

```
## ⚠️ Overall Safety Cap: 15 sweeps completed

### Current State
- N remaining MEDIUM items
- M remaining LOW items
- K total actions applied
- Currently processing: [Content Type]

The collection may have diminishing-return items that keep surfacing.
```

Use `AskUserQuestion`:
- **Continue** — "Run 5 more sweeps"
- **Stop here** — "End consolidation with current results"

### Phase cycle repeats 2+ times

If the Phase 1 → Phase 2 → Phase 3 → Phase 1 cycle completes more than twice within a single content type:

```
## ℹ️ Cycle Check: Round N through the full cycle ([Content Type])

Each round of changes keeps surfacing new recommendations.

Remaining: N HIGHs, M MEDIUMs
```

Use `AskUserQuestion`:
- **Continue** — "Keep going"
- **Apply HIGHs only and stop** — "Auto-apply remaining HIGHs, skip MEDIUMs, show summary"
- **Stop here** — "End consolidation with current results"

### Deep dive: no candidates (common case)

One-line log, no interaction: "No deep dive candidates — proceeding to next content type."

### Deep dive: subagent returns no findings

Remove the file from candidates. Log: "[file] — classification confirmed, no within-file actions needed."

### Deep dive: cross-file conflict between subagents

Orchestrator sequences conflicting actions — same pattern as broad sweep (parallel for different target files, sequential for actions targeting the same file).

## Important Notes

- **Always broad sweep** — this skill does not support targeted files. Use `/learnings:curate <file>` for that.
- **Fixed content type ordering** — LEARNINGS → SKILLS → GUIDELINES. This is not configurable; the ordering ensures each type benefits from prior cleanup.
- **HIGHs are auto-applied** — that's the value proposition. If uncomfortable, use `/learnings:curate` instead.
- **MEDIUMs always get approval** — the batch in Phase 2 is the primary user interaction point.
- **LOWs are never auto-applied** — they appear in reports for awareness but require explicit `/learnings:curate` runs.
- **Fresh analysis per phase** — MEDIUMs are NOT accumulated across sweeps. Each transition triggers fresh analysis because state has changed.
- **Corpus refresh at content type boundaries** — when transitioning between content types, re-read files modified by prior phases rather than the full corpus. This keeps subsequent analysis current without the cost of a full re-read.
- **Skill mode vs content mode** — skills use learnings:curate's skill mode (2s–4s); guidelines use content mode (2–5a). The loop structure is the same, but the analysis methodology differs.
- **Methodology delegation** — this skill orchestrates the loop; `/learnings:curate` owns the analysis. Changes to learnings:curate automatically flow through.
- **Deep dives are bounded** — cross-file effects from deep dive actions are logged but don't cascade back to broad sweeps. Run `/learnings:curate <file>` or another consolidation for full re-evaluation.

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
