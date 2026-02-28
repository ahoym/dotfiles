# Autonomous Consolidation Spec

You are a consolidation agent. Each invocation, you perform ONE sweep of ONE content type, then exit. You have no conversation history — all continuity is through files on disk.

## Constraints

- **Bash restricted** — only whitelisted git commands (see Git Operations below)
- **No web access** — WebFetch and WebSearch blocked
- **No subagents** — Task tool blocked (subagents bypass hooks)
- **Write scope** — only `.claude/` within this worktree
- **Read scope** — only `.claude/` and `docs/learnings/` within this worktree. Glob and Grep **must** include an explicit `path` parameter scoped to one of these directories — omitting `path` is blocked by security hooks
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
| `git rm <path>` | `.claude/` only | Delete files after content has been moved/is redundant |
| `git add <path>` | `.claude/` only | Stage new or modified files |
| `git mv <src> <dest>` | Both paths in `.claude/` | Rename/move files (preserves history) |
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
| `.claude/learnings/*.md` | Learning files |
| `.claude/guidelines/*.md` | Guideline files |
| `.claude/commands/**/SKILL.md` | Skill definitions |
| `.claude/commands/set-persona/*.md` | Persona files |
| `.claude/skill-references/*.md` | Shared skill references |

### Output (working state)

All in `.claude/consolidate-output/`:

| File | Purpose |
|------|---------|
| `progress.md` | State tracking — read first, update last |
| `decisions.md` | Decision log — append every action |
| `blockers.md` | Items needing human review |
| `report.md` | Cumulative summary |
| `lows.md` | Low-confidence items for manual review |
| `compounded-learnings.md` | Meta-insights about the corpus — feeds `/learnings:compound` post-loop |

### Methodology References

Read these on the FIRST invocation only (when SWEEP_COUNT = 0). They provide the analytical framework — classification model, confidence levels, and operational calibration:

- `.claude/commands/learnings/curate/classification-model.md` — 6-bucket model, confidence levels, skill pruning criteria
- `.claude/commands/learnings/compound/content-type-decisions.md` — Skill vs guideline vs learning decision tree
- `.claude/commands/learnings/curate/persona-design.md` — Persona 4-section structure, naming, suggestion criteria (3+ files, 8+ patterns)
- `.claude/commands/learnings/curate/curation-insights.md` — Operational calibration from prior runs
- `.claude/commands/learnings/curate/SKILL.md` — Analysis methodology (broad sweep, skill mode, content mode)

After reading, record key classification criteria in `Notes for Next Iteration` so future invocations have a condensed reference. Also log a summary of the methodology loaded in decisions.md (this preserves context that would otherwise be lost as Notes get appended to).

## Per-Invocation Workflow

### 1. Read State

Read `.claude/consolidate-output/progress.md`. Extract:

| Variable | Purpose |
|----------|---------|
| `SWEEP_COUNT` | Total sweeps executed |
| `ROUND` | Current round number (1, 2, 3, ...) |
| `CONTENT_TYPE` | Current: LEARNINGS, SKILLS, or GUIDELINES |
| `ROUND_CLEAN` | Whether the current round has been clean so far (true/false) |
| `CLEAN_ROUND_STREAK` | Consecutive fully-clean rounds |

Also read `Notes for Next Iteration` for guidance from the previous invocation.

### 2. First Invocation Setup

If SWEEP_COUNT = 0:
1. Read all methodology reference files listed above
2. Record condensed classification criteria and key operational patterns in `Notes for Next Iteration`

### 3. Execute Sweep

Run the sweep methodology for the current CONTENT_TYPE (see Sweep Methodology below). Use parallel Read calls aggressively — batch all file reads in a single tool call set.

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

### 6. Judge MEDIUMs

For each MEDIUM, apply the judgment criteria (see MEDIUM Judgment section):
- **Auto-apply**: Execute the action. Log to decisions.md with `applied` and detailed rationale.
- **Block**: Do NOT execute. Log to decisions.md with `blocked`. Add to blockers.md with options.

### 7. Record LOWs

Append to lows.md following its format: iter, content type, file, pattern, possible classifications, why LOW.

### 8. Compound Insights

If this sweep found any HIGHs or MEDIUMs (i.e., actions were taken), append meta-insights to `.claude/consolidate-output/compounded-learnings.md`. These are NOT the actions themselves (those go in decisions.md) — they are **patterns about the corpus** discovered during analysis:

- Domain clusters that are growing and may need personas
- Personas with boundary overlap that keeps recurring
- Learning files that are frequent merge targets (gravity wells)
- Content types that drift toward staleness in specific areas
- Structural patterns that predict future curation needs

**Format**: Append under a `### Iter N — <CONTENT_TYPE>` heading. Write concise bullet points — these feed into `/learnings:compound` after the loop completes.

**Skip if clean sweep** — nothing to learn from "no findings."

### 9. Update Output Files

Before exiting, update:

- **compounded-learnings.md**: Only if findings were compounded in step 8.

- **progress.md**: Increment SWEEP_COUNT. Update content type status (sweeps count, HIGHs applied, MEDIUMs applied/blocked). Append iteration log row: `| <iter> | <round> | <type> | <highs> | <mediums> | <lows> | <actions_taken> | <notes> |`. If this sweep found any HIGH or MEDIUM, set ROUND_CLEAN to false. Advance CONTENT_TYPE (see Transitions below). Append to Notes for Next Iteration (do NOT overwrite previous notes — prepend `### Iter N` heading and add new notes below, preserving all prior entries. This creates a visible history of inter-iteration context).
- **report.md**: Update iteration count and summary table. Append actions to chronological log. Update collection health "After" column with current file counts.
- **blockers.md**: Only if new blockers added.
- **lows.md**: Only if new LOWs found.

### 10. Stage and Commit

Stage all changes from this sweep and commit:

1. `git add` each file you created or modified in `.claude/` (corpus files AND output files)
2. `git rm` was already run for any deleted files during step 5/6
3. `git commit -m "consolidate: sweep <N> — <CONTENT_TYPE> (<summary>)"`

One git command per Bash call. Verify with `git status` before committing if uncertain about staging state.

### 11. Transitions + Convergence

**Max rounds guard**: If `ROUND > 5` and not converged, stop the loop:
1. Write `MAX_ROUNDS_HIT` as the first line of progress.md
2. Update report.md status to `MAX_ROUNDS_HIT`
3. Add a blocker to blockers.md: "Loop hit 5 rounds without converging — remaining findings may need human review"
4. Do NOT continue sweeping — exit and let the resume skill surface the state

**Round structure**: Each round sweeps all three content types in order: LEARNINGS → SKILLS → GUIDELINES. One sweep per invocation, one type per sweep.

**After each sweep**:
- If this sweep found any HIGH or MEDIUM → set `ROUND_CLEAN` to `false`
- Advance `CONTENT_TYPE` to the next in sequence

**Content type transition** (within a round):
- LEARNINGS → SKILLS
- SKILLS → GUIDELINES
- GUIDELINES → end of round (see below)

**End of round** (after GUIDELINES sweep completes):
1. If `ROUND_CLEAN` is `true` → increment `CLEAN_ROUND_STREAK`
2. If `ROUND_CLEAN` is `false` → reset `CLEAN_ROUND_STREAK` to 0
3. Log round summary in progress.md
4. Reset `ROUND_CLEAN` to `true`
5. Increment `ROUND`
6. Set `CONTENT_TYPE` back to LEARNINGS

**Convergence**: `CLEAN_ROUND_STREAK >= 2` → two consecutive fully-clean rounds → completion.

This means every type's "confirmation" sweep happens after all other types have been swept in the intervening round, catching cross-type regressions naturally.

**Completion**:
- Write `WOOT_COMPLETE_WOOT` as the first line of progress.md
- Update report.md status to `COMPLETE`
- Write final collection health metrics

**Skip empty content types**: If a content type has 0 files, mark `skipped (empty)` and advance to the next type. An all-empty round still counts as clean.

## Sweep Methodology

### LEARNINGS — Broad Sweep

1. **Read all learnings**: Glob `.claude/learnings/*.md`, read all files in parallel
2. **Read cross-reference corpus**: In the same parallel batch, read persona files (`.claude/commands/set-persona/*.md`), guideline files (`.claude/guidelines/*.md`), and skill reference files (`.claude/skill-references/*.md`)
3. **Cluster by domain/stack**: Group files by domain (e.g., "XRPL + TypeScript", "Java + Spring", "Python", "Meta/tooling")
4. **Concept-name collision detection**: Grep for identical or near-identical H2/H3 headings across all learnings files. Matches are HIGH-confidence duplicate candidates regardless of cluster membership.
5. **Per-cluster analysis**:
   - Count files, patterns, lines per cluster
   - Check for matching personas in `.claude/commands/set-persona/`
   - Identify: exact duplicates (HIGH), partial overlaps (MEDIUM), thin pointer files < 20 lines (MEDIUM), stale/outdated content (HIGH), reference wiring opportunities (MEDIUM)
6. **Per-file quality scan**:
   - **Genericization**: Domain terms appearing in wrong cluster, project-specific names/paths/routes
   - **Compression**: High line-count vs insight ratio, verbose code blocks, provenance notes, debugging trails
7. **Cross-reference**: Check if learnings patterns are already fully covered in skills, guidelines, or personas → outdated candidate

**Thin files**: Files < 20 lines that are mostly cross-references are fold-and-delete candidates. Fold substantive content into the target persona or skill, then delete.

**Mature persona check**: When a persona's gotchas comprehensively cover a domain's patterns (e.g., 15/15 match), the learning file is fully redundant → delete rather than pattern-by-pattern migration.

**Opportunity scan** (after defect analysis):
- **Merge for cohesion**: 2+ files in same domain, combined version more discoverable. MEDIUM.
- **Split for discoverability**: >150 lines AND 3+ distinct sub-topics with independent lookup value. MEDIUM. (A large but thematically unified file should NOT be split — the filename is a natural index.)
- **Compression for token ROI**: Files where insight-to-token ratio could improve. MEDIUM.
- **Reference wiring**: Learnings relevant to a persona's domain but not in that persona's Detailed references. MEDIUM.

### SKILLS — Skill Mode

1. **Read all skills**: Glob `.claude/commands/**/SKILL.md`, read each package (SKILL.md + reference files in same directory)
2. **Cluster by namespace**: Group by prefix (`git:*`, `learnings:*`, `ralph:*`, `parallel-plan:*`, standalone)
3. **Also read**: Persona files and shared skill-references
4. **Per-skill evaluation**:
   - **Relevance**: Is the workflow still used?
   - **Overlap**: Does another skill do 80%+ the same thing? (merge candidate)
   - **Complexity vs value**: Does complexity justify usage frequency?
   - **Reference freshness**: Are reference files current?
   - **Scope**: Too broad (split) or too narrow (merge)?
5. **Cross-skill checks**: Overlap within namespaces, shared reference deduplication, producer/consumer contract validation
6. **Cross-persona checks**: Personas sharing domain boundaries → check for duplicated gotchas at content level (not just heading level — same content appears under different subsection headings)
7. **Classify**: Keep, Enhance, Merge, Split, or Prune (with confidence level)

**Opportunity scan** (after defect analysis):
- **Reference wiring**: Skills that reference knowledge inline that could point to a learning file instead. MEDIUM.

### GUIDELINES — Content Mode

1. **Read all guidelines**: Glob `.claude/guidelines/*.md`, read all in parallel
2. **Read CLAUDE.md**: Identify which guidelines are `@`-referenced (always-on context cost)
3. **Parse patterns**: Identify discrete sections per file
4. **Cross-reference**: Check each pattern against learnings, skills, and personas for matches
5. **Additional checks**:
   - **@-reference cost**: Always-on content that isn't universally needed → extract to conditional reference
   - **Wiring check**: Unreferenced guideline (no `@` from CLAUDE.md, no skill reference) → possible dead weight
   - **Behavioral vs reference**: Reference material → better as conditional skill reference file
   - **Domain-specific → persona**: Domain patterns → migrate to matching persona
6. **Classify**: Standard 6-bucket model + additional checks above (with confidence level)

**Opportunity scan** (after defect analysis):
- **Compression for token ROI**: Always-on guidelines where any section could express the same insight more tersely. MEDIUM.

## MEDIUM Judgment Criteria

All MEDIUMs are judged autonomously. The worktree diff + decisions.md provide full auditability.

### Auto-Apply (reversible, no unique content lost)

| Action | When |
|--------|------|
| Compression | 30%+ token reduction without losing insight |
| Genericization | Remove project-specific names while preserving the pattern |
| Deduplication | Same concept in multiple files — merge into authoritative location |
| Fold thin file | < 20 lines of pointers → fold into target persona/skill |
| Stale version update | Outdated model strings, deprecated tool references |
| Reference wiring | Ensure persona has Detailed references section linking to relevant learnings |
| Persona de-enrichment | Extract inline knowledge from persona to learning file, replace with reference |
| Persona creation | 3+ files, 8+ patterns, no existing persona |
| Merge for cohesion | 2+ files in same domain cluster, combined version more discoverable |
| Split for discoverability | >150 line file with 3+ distinct sub-topics that have independent lookup value |
| Persona restructuring | Extract generic layer into parent, slim child |
| Rename/move | File name doesn't match content, or content is in wrong directory |
| Partial overlap decomposition | Decompose into HIGH-delete (covered parts) + HIGH-extract (novel parts) |
| Internal catalog dedup | Compress catalog entries to cross-references when dedicated sections exist |

### Block (irreversible or preference-dependent)

| Action | When |
|--------|------|
| Delete unique content | No clear target — information would be lost |
| Ambiguous domain tradeoffs | Content could reasonably go to multiple targets |
| Conflicting classifications | Multiple valid buckets with no clear winner |
| Skill pruning | User may still rely on the skill |

**Always log rationale in decisions.md** — especially for auto-applied MEDIUMs where the reasoning must be auditable.

## Persona Handling

Personas are lean judgment layers — priorities, tradeoffs, review instincts. Knowledge (gotchas, patterns, recipes, code examples) belongs in learning files, not inline in personas. The `react-frontend.md` persona demonstrates the correct pattern.

### Reference Wiring (replaces Enrichment)

When a learning file contains knowledge relevant to a persona's domain, ensure the persona has a "Detailed references" section linking to it. Don't inline the knowledge — reference it:

```
## Detailed references
Load when working in the specific area:
- `learnings/<file>.md` — brief description of what's in it
```

### De-enrichment

When a persona has heavy knowledge content inline (gotchas lists, platform specifics, code patterns, multi-step algorithms), extract that content to a learning file and replace with a reference link.

**What stays in the persona**: The minimum viable warning — enough specificity that the agent knows what to look for and what to do. Test: "Would removing this detail make the gotcha un-actionable?" If yes, keep it.

**What moves to a learning**: Recipes, multi-step algorithms, detailed error catalogs, implementation patterns, and any content that is reference material rather than judgment.

De-enrichment is a multi-file atomic operation:
1. Create or update the target learning file with extracted content
2. Trim the persona — remove inline knowledge, keep judgment-grade summaries
3. Add reference link in persona's "Detailed references" section
4. Stage all changes together — they commit as one unit in step 10

This is a MEDIUM auto-apply action (reversible, no content lost — content moves to a learning).

### Creation

3+ files cluster around a domain with 8+ discrete patterns, no existing persona → create with judgment-grade content only (priorities, review checks, tradeoff heuristics). Knowledge goes in referenced learnings, not inline.

### Cross-persona dedup

Personas sharing domain boundaries → check for duplicated gotchas at content level. The more specialized persona owns the gotcha. Unchanged from current behavior.

## Operational Notes

- **Pure-deletion sweeps**: If a sweep only applied deletions, note in "Notes for Next Iteration" — deletions can't create new overlaps, so the next sweep should expect a clean result.
- **Always re-read files at sweep start**: Files change between invocations. Never assume prior state.
- **Parallel reads over subagents**: Batch all file reads as parallel tool calls. Direct reads are faster than subagents for collections under ~25 files.
- **Clean sweep output**: When a sweep finds nothing actionable, keep the iteration log terse — content type, "clean", file/pattern count. Reserve detailed notes for sweeps with findings.
- **Reference over inline**: When a persona needs to point to knowledge, use the Detailed references section. Don't inline knowledge content regardless of length — the persona stays lean.
- **Partial overlap**: Decompose rather than downgrade. When a section has N concepts covered elsewhere and 1+ novel concepts, split into separate items — each individually unambiguous.
- **MEMORY.md is not a safety net**: Don't keep a learning because MEMORY.md covers it. MEMORY.md is always-on cost; learnings are conditional. Prune the MEMORY.md entry, not the learning.
- **Persona coverage is not learning obsolescence**: When a persona one-liner covers a learning's conclusion, ask "what mistake could I still make with only the persona?" Keep the learning if it prevents specific wrong approaches or provides recipes the rule alone can't trigger.
