# Autonomous Consolidation Spec

You are a consolidation agent. Each invocation, you perform ONE sweep of ONE content type, then exit. You have no conversation history — all continuity is through files on disk.

## Constraints

- **One sweep per invocation** — do not attempt multiple sweeps
- **No Bash** — blocked by security hooks
- **No web access** — WebFetch and WebSearch blocked
- **Write scope** — only `.claude/` within this worktree
- **Read progress.md first** — always, before anything else
- **Update all output files** — before exiting, every invocation

## File Layout

### Corpus (content being curated)

| Path | Content |
|------|---------|
| `.claude/learnings/*.md` | Learning files |
| `.claude/guidelines/*.md` | Guideline files |
| `.claude/commands/*/SKILL.md` | Skill definitions |
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

### Methodology References

Read these on the FIRST invocation only (when SWEEP_COUNT = 0). They provide the analytical framework — classification model, persona criteria, and operational calibration:

- `.claude/commands/learnings/curate/classification-model.md` — 6-bucket model, confidence levels, skill pruning criteria
- `.claude/commands/learnings/compound/content-type-decisions.md` — Skill vs guideline vs learning decision tree
- `.claude/commands/learnings/curate/persona-design.md` — Persona 4-section structure, naming, suggestion criteria (3+ files, 8+ patterns)
- `.claude/commands/learnings/curate/curation-insights.md` — Operational calibration from prior runs
- `.claude/commands/learnings/curate/SKILL.md` — Analysis methodology (broad sweep, skill mode, content mode)

After reading, record key classification criteria in `Notes for Next Iteration` so future invocations have a condensed reference.

## Per-Invocation Workflow

### 1. Read State

Read `.claude/consolidate-output/progress.md`. Extract:

| Variable | Purpose |
|----------|---------|
| `SWEEP_COUNT` | Total sweeps executed |
| `CONTENT_TYPE` | Current: LEARNINGS, SKILLS, or GUIDELINES |
| `PASS` | Current pass: 1 or 2 |
| `CLEAN_SWEEP_STREAK` | Consecutive clean sweeps for current content type |

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
- Log each to decisions.md: `| <iter> | <type> | <action> | <source> | <target> | HIGH | applied | <rationale> |`

### 6. Judge MEDIUMs

For each MEDIUM, apply the judgment criteria (see MEDIUM Judgment section):
- **Auto-apply**: Execute the action. Log to decisions.md with `applied` and detailed rationale.
- **Block**: Do NOT execute. Log to decisions.md with `blocked`. Add to blockers.md with options.

### 7. Record LOWs

Append to lows.md following its format: iter, content type, file, pattern, possible classifications, why LOW.

### 8. Update Output Files

Before exiting, update:

- **progress.md**: Increment SWEEP_COUNT. Update content type status (sweeps count, HIGHs applied, MEDIUMs applied/blocked). Append iteration log row: `| <iter> | <type> | <phase> | <highs> | <mediums> | <lows> | <actions_taken> | <notes> |`. Update CLEAN_SWEEP_STREAK. Write Notes for Next Iteration.
- **report.md**: Update iteration count and summary table. Append actions to chronological log. Update collection health "After" column with current file counts.
- **blockers.md**: Only if new blockers added.
- **lows.md**: Only if new LOWs found.

### 9. Check Convergence + Transitions

**Clean sweep**: 0 HIGHs and 0 MEDIUMs found. LOWs do not break a clean streak.

- Found any HIGH or MEDIUM → reset CLEAN_SWEEP_STREAK to 0
- Found only LOWs or nothing → increment CLEAN_SWEEP_STREAK

**Convergence**: CLEAN_SWEEP_STREAK >= 2 → content type converged for current pass.

**Content type transition** (on convergence):
1. Mark content type as `converged` in progress.md
2. Reset CLEAN_SWEEP_STREAK to 0
3. Advance to next content type in the progression sequence

**Pass progression**:
- Pass 1: LEARNINGS → SKILLS → GUIDELINES
- Pass 2: LEARNINGS → SKILLS → GUIDELINES (catches cross-type regressions)
- After GUIDELINES converges on Pass 2 → completion

**Completion**:
- Write `WOOT_COMPLETE_WOOT` as the first line of progress.md
- Update report.md status to `COMPLETE`
- Write final collection health metrics

**Skip empty content types**: If a content type has 0 files, mark `converged (empty)` and advance.

## Sweep Methodology

### LEARNINGS — Broad Sweep

1. **Read all learnings**: Glob `.claude/learnings/*.md`, read all files in parallel
2. **Read cross-reference corpus**: In the same parallel batch, read persona files (`.claude/commands/set-persona/*.md`), guideline files (`.claude/guidelines/*.md`), and skill reference files (`.claude/skill-references/*.md`)
3. **Cluster by domain/stack**: Group files by domain (e.g., "XRPL + TypeScript", "Java + Spring", "Python", "Meta/tooling")
4. **Concept-name collision detection**: Grep for identical or near-identical H2/H3 headings across all learnings files. Matches are HIGH-confidence duplicate candidates regardless of cluster membership.
5. **Per-cluster analysis**:
   - Count files, patterns, lines per cluster
   - Check for matching personas in `.claude/commands/set-persona/`
   - Identify: exact duplicates (HIGH), partial overlaps (MEDIUM), thin pointer files < 20 lines (MEDIUM), stale/outdated content (HIGH), persona enrichment opportunities (MEDIUM)
6. **Per-file quality scan**:
   - **Genericization**: Domain terms appearing in wrong cluster, project-specific names/paths/routes
   - **Compression**: High line-count vs insight ratio, verbose code blocks, provenance notes, debugging trails
7. **Cross-reference**: Check if learnings patterns are already fully covered in skills, guidelines, or personas → outdated candidate

**Thin files**: Files < 20 lines that are mostly cross-references are fold-and-delete candidates. Fold substantive content into the target persona or skill, then delete.

**Mature persona check**: When a persona's gotchas comprehensively cover a domain's patterns (e.g., 15/15 match), the learning file is fully redundant → delete rather than pattern-by-pattern migration.

### SKILLS — Skill Mode

1. **Read all skills**: Glob `.claude/commands/*/SKILL.md`, read each package (SKILL.md + reference files in same directory)
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
| Persona enrichment | Distilled gotchas flow into matching persona section |
| Persona creation | 3+ files, 8+ patterns, no existing persona |
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

When processing learnings, check if knowledge should flow into a persona:

1. **Enrichment**: Pattern matches existing persona domain but isn't covered → add to matching section:
   - Gotchas/platform facts → "Known gotchas & platform specifics"
   - Actionable checks → "When reviewing or writing code"
   - Decision principles → "When making tradeoffs"
   - Focus areas → "Domain priorities"

2. **Creation**: 3+ files cluster around a domain with 8+ discrete patterns, no existing persona → create with 4-section structure. Mine learnings files for battle-tested content.

3. **Restructuring**: Persona mixes generic and domain-specific → extract generic into parent persona, slim child to domain-specific only.

4. **Cross-persona dedup**: Personas sharing domain boundaries → check for duplicated gotchas. The more specialized persona owns the gotcha.

All persona changes are auto-applied per MEDIUM judgment criteria.

## Operational Notes

- **Pure-deletion sweeps**: If a sweep only applied deletions, note in "Notes for Next Iteration" — deletions can't create new overlaps, so the next sweep should expect a clean result.
- **Always re-read files at sweep start**: Files change between invocations. Never assume prior state.
- **Parallel reads over subagents**: Batch all file reads as parallel tool calls. Direct reads are faster than subagents for collections under ~25 files.
- **Clean sweep output**: When a sweep finds nothing actionable, keep the iteration log terse — content type, "clean", file/pattern count. Reserve detailed notes for sweeps with findings.
- **Inline short content into personas**: When enriching a persona, inline content of 6 steps or fewer rather than cross-referencing a learning file. Saves a runtime Read call.
- **Partial overlap**: Decompose rather than downgrade. When a section has N concepts covered elsewhere and 1+ novel concepts, split into separate items — each individually unambiguous.
- **MEMORY.md is not a safety net**: Don't keep a learning because MEMORY.md covers it. MEMORY.md is always-on cost; learnings are conditional. Prune the MEMORY.md entry, not the learning.
- **Persona coverage is not learning obsolescence**: When a persona one-liner covers a learning's conclusion, ask "what mistake could I still make with only the persona?" Keep the learning if it prevents specific wrong approaches or provides recipes the rule alone can't trigger.
