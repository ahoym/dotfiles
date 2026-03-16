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
8. **Cross-reference graph health**: Scan all `## See also` sections across learnings files. The agent has the full corpus loaded — this is the best vantage point for graph-level analysis that per-file deep dives can't see.
   - **Stale refs**: Target file no longer exists, or stated relationship decayed (content refactored to different topics). HIGH.
   - **Isolated files**: Files with zero inbound or outbound cross-refs. Not inherently wrong — evaluate whether a cross-ref would provide non-obvious lateral discovery (keyword search wouldn't connect them). MEDIUM if a clear link exists.
   - **Missing cross-cluster refs**: Files in different domain clusters that share non-obvious conceptual overlap (e.g., `resilience-patterns.md` ↔ `aws-messaging.md` on retry/backoff). These are the highest-value cross-refs — keyword search connects within-cluster files but misses cross-cluster relationships. MEDIUM.
   - **Hub files**: High inbound ref count (3+). Flag for deep dive candidacy — foundational knowledge that should be kept current. No action unless stale.
   - Log a topology summary in Notes for Next Iteration (e.g., "Graph: 40 connected, 16 isolated, 3 hubs, 2 stale refs removed, 4 cross-cluster refs added").

   **Cross-ref quality test**: A cross-ref earns its keep when the answer to both questions is yes: (1) Would an agent working in file A benefit from knowing about file B? (2) Would they plausibly not find it via keyword search?

   Good cross-refs connect:
   - **Different vocabulary, shared concept** — files that overlap on a strategy or pattern but use different domain terms (e.g., resilience retry logic vs. SQS retry policies)
   - **Different domain, transferable pattern** — a technique in one domain that applies to another but isn't obviously related (e.g., financial precision handling ↔ DEX data normalization)
   - **Complementary perspectives** — files addressing the same problem from different angles (e.g., test design patterns ↔ local dev seeding)

   Don't cross-ref:
   - **Keyword-discoverable** — files the search protocol already connects via filename or content matching (e.g., `spring-boot.md` ↔ `spring-boot-gotchas.md`)
   - **Weak thematic similarity** — "both mention databases" isn't enough; the link should save a wrong turn or surface a non-obvious approach

**Thin files**: Files < 20 lines that are mostly cross-references are fold-and-delete candidates. Fold substantive content into the target persona or skill, then delete.

**Mature persona check**: When a persona's gotchas comprehensively cover a domain's patterns (e.g., 15/15 match), the learning file is fully redundant → delete rather than pattern-by-pattern migration.

**Opportunity scan** (after defect analysis):
- **Merge for cohesion**: 2+ files in same domain, combined version more discoverable. MEDIUM.
- **Split for discoverability**: >150 lines AND 3+ distinct sub-topics with independent lookup value. MEDIUM. (A large but thematically unified file should NOT be split — the filename is a natural index.)
- **Compression for token ROI**: Files where insight-to-token ratio could improve. MEDIUM.
- **Reference wiring**: Learnings relevant to a persona's domain but not in that persona's Detailed references. MEDIUM.
- **Cross-ref wiring**: Add `## See also` entries for non-obvious cross-cluster relationships identified in step 8. Check bidirectionality — if adding A → B, also add B → A when the reverse provides discovery value. MEDIUM.

**Deep dive candidate recording**: Record files meeting deep dive candidacy criteria (see spec.md > Deep Dive Candidacy) in `Notes for Next Iteration` as `DEEP_DIVE_CANDIDATES: [file1, file2, ...]`. These are used after GUIDELINES completes to populate the deep dive phase.

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
- **Opportunity over cleanup as tiebreaker**: When a finding has both a cleanup option (delete orphan, remove dead weight) and an opportunity option (wire it, restructure it, merge it), prefer opportunity — it fixes the root cause and is reversible. Cleanup accepts the dysfunction. Only prefer cleanup when the content is stale, incorrect, or has no identifiable consumers.
