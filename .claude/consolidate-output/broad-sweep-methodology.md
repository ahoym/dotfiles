# Broad Sweep Methodology

Read by the consolidation agent when `PHASE` is `BROAD_SWEEP`. Not needed during deep dives.

## LEARNINGS — Broad Sweep

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
8. **Cross-reference graph health**: Scan all `## See also` sections across learnings files. Full corpus is loaded — best vantage for graph-level analysis.
   - **Stale refs**: Target gone or relationship decayed. HIGH.
   - **Isolated files**: Zero cross-refs. MEDIUM if a non-obvious lateral link exists.
   - **Missing cross-cluster refs**: Different domain clusters sharing non-obvious conceptual overlap (highest-value cross-refs — keyword search misses these). MEDIUM.
   - **Hub files**: 3+ inbound refs. Flag for deep dive candidacy.
   - Log topology summary in Notes (e.g., "Graph: 40 connected, 16 isolated, 3 hubs").

   **Quality test**: (1) Would an agent in file A benefit from knowing about file B? (2) Would they plausibly not find it via keyword search? Both must be yes.

   **Good cross-refs**: different vocabulary/shared concept, different domain/transferable pattern, complementary perspectives.
   **Don't cross-ref**: keyword-discoverable pairs, weak thematic similarity.

**Thin files**: Files < 20 lines that are mostly cross-references are fold-and-delete candidates. Fold substantive content into the target persona or skill, then delete.

**Mature persona check**: When a persona's gotchas comprehensively cover a domain's patterns (e.g., 15/15 match), the learning file is fully redundant → delete rather than pattern-by-pattern migration.

**Opportunity scan** (after defect analysis):
- **Merge for cohesion**: 2+ files in same domain, combined version more discoverable. MEDIUM.
- **Split for discoverability**: >150 lines AND 3+ distinct sub-topics with independent lookup value. MEDIUM. (A large but thematically unified file should NOT be split — the filename is a natural index.)
- **Compression for token ROI**: Files where insight-to-token ratio could improve. MEDIUM.
- **Reference wiring**: Learnings relevant to a persona's domain but not in that persona's Detailed references. MEDIUM.
- **Cross-ref wiring**: Add `## See also` entries for non-obvious cross-cluster relationships identified in step 8. Check bidirectionality — if adding A → B, also add B → A when the reverse provides discovery value. MEDIUM.

**Deep dive candidate recording**: Record files meeting deep dive candidacy criteria (see spec.md > Deep Dive Candidacy) in `Notes for Next Iteration` as `DEEP_DIVE_CANDIDATES: [file1, file2, ...]`. These are used after GUIDELINES completes to populate the deep dive phase. Include skill-reference files (`.claude/skill-references/**/*.md`) — they follow the same candidacy criteria as other corpus files.

## SKILL-REFERENCES — Consumer Wiring Check

During the SKILLS broad sweep (step 4 above), also scan skill-references for consumer health:

1. **Read all skill-references**: Glob `.claude/skill-references/**/*.md`
2. **Consumer wiring**: For each skill-reference, grep skill directories for references to its filename. An unreferenced skill-reference is dead weight — HIGH delete candidate.
3. **Staleness**: Cross-reference content against the learnings and skills it supports. Stale patterns → HIGH update or delete.
4. **Duplication with learnings**: Check if a skill-reference duplicates content already in a learnings file. Dedup from the consuming skill (not from the reference) per the reference-file gate.

Record findings inline with the SKILLS sweep classifications. Skill-references share the SKILLS sweep — they don't get a separate broad sweep pass.

## SKILLS — Skill Mode

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

## GUIDELINES — Content Mode

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
| Compression | Meaningful token reduction without losing insight |
| Genericization | Remove project-specific names while preserving the pattern |
| Deduplication | Same concept in multiple files — merge into authoritative location |
| Fold thin file | < 20 lines of pointers → fold into target persona/skill |
| Stale version update | Outdated model strings, deprecated tool references |
| Reference wiring | Ensure persona has Detailed references section linking to relevant learnings; ensure skill-reference files are wired into skills that would benefit |
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

Blocked MEDIUMs go to `review.md` with `[BLOCKED-MED]` tag and options. **Always log rationale in decisions.md** — especially for auto-applied MEDIUMs where the reasoning must be auditable.

## Persona Handling

Personas are lean judgment layers — priorities, tradeoffs, review instincts. Knowledge belongs in learning files, not inline.

### Reference Wiring

Ensure personas have `## Detailed references` linking to relevant learnings. Don't inline knowledge — reference it.

### De-enrichment

Extract heavy inline knowledge (gotchas lists, platform specifics, code patterns) to learning files. Keep only judgment-grade summaries in the persona. Test: "Would removing this detail make the gotcha un-actionable?" If yes, keep it.

Atomic operation: (1) create/update learning, (2) trim persona, (3) add reference link, (4) stage together. MEDIUM auto-apply (reversible, no content lost).

### Creation

3+ files, 8+ patterns, no existing persona → create with judgment-grade content only. Knowledge in referenced learnings.

### Cross-persona dedup

Shared domain boundaries → check for duplicated gotchas at content level. More specialized persona owns the gotcha.

## Operational Notes

- **Pure-deletion sweeps**: Note in "Notes for Next Iteration" — deletions can't create new overlaps.
- **Always re-read files at sweep start**: Files change between invocations.
- **Parallel reads over subagents**: Batch all reads as parallel tool calls. Faster than subagents for <25 files.
- **Clean sweep output**: Terse iteration log — content type, "clean", file/pattern count.
- **Reference over inline**: Personas use Detailed references, never inline knowledge.
- **Partial overlap**: Decompose rather than downgrade — split into individually unambiguous items.
- **MEMORY.md is not a safety net**: Prune the MEMORY.md entry, not the learning.
- **Persona coverage ≠ learning obsolescence**: Keep learnings that prevent specific wrong approaches the persona one-liner can't.
- **Opportunity over cleanup as tiebreaker**: Prefer wiring/restructuring (reversible, fixes root cause) over deletion (irreversible). Only delete when stale, incorrect, or no consumers.
