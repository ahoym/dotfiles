Patterns for organizing learnings files — cross-reference conventions, directory clustering, curated indexes, file splitting, and keyword gate design.
- **Keywords:** cross-refs, cross-reference, directory clustering, file splitting, CLAUDE.md index, catch-all directory, hub-spoke, discovery vs semantic, dedup, keyword gate
- **Related:** none

---

## Cross-Reference Convention (`## Cross-Refs`)

Learnings files can cross-reference related files to enable **lateral discovery** — finding files that are relevant to what you already loaded but wouldn't be found by keyword search alone. Cross-refs are conditional (non-`@`) signposts, not eager loads.

**Format:** A `## Cross-Refs` footer as the last section in the file, with 1-5 refs:

```markdown
## Cross-Refs

.claude/learnings/postgresql-query-patterns.md — migration patterns overlap with Flyway/Spring Boot
.claude/learnings/java-observability-gotchas.md — Spring Boot instrumentation pitfalls
```

**Rules:**
- **Scope:** Learnings-only (`~/.claude/learnings/`) for now — not cross-type to skills or guidelines
- **Only non-obvious relationships.** If keyword search would find the connection (shared vocabulary in filenames or content), a cross-ref adds no value. Reserve for relationships where the agent wouldn't think to search.
- **1-5 refs max per file.** The number is a guardrail, not a target — each ref must pass the non-obvious test. Hub files that route to a cluster may exceed 5 when each ref adds non-keyword-discoverable value.
- **Include a reason.** The one-liner after the path explains *why* the relationship exists, which helps the agent (and user) judge relevance without loading the target.
- **Path format:** `~/.claude/learnings/<file>.md` (absolute tilde path — works outside the repo's CWD and matches Read tool resolution from any context)
- **Placement:** Always the last section in the file, after all content sections.

**Hub-spoke rule:** When files form a hub-spoke cluster (e.g., `content-types.md` routing to `skills.md`, `guidelines.md`, etc.), spokes should cross-ref the hub (upward navigation — the agent needs a breadcrumb back to the routing table) but NOT sibling spokes (lateral navigation — the hub already handles that). Spoke-to-spoke refs duplicate hub routing and grow linearly with new spokes.

**Bidirectionality:** When adding A → B, check whether B → A is also valuable. Relationships can be asymmetric — "spring-boot-gotchas relates to postgresql for migrations" doesn't necessarily mean postgresql needs to link back to spring-boot. Add the reverse only when both directions provide lateral discovery value.

**Growth:** Cross-refs grow organically through `/learnings:curate` content-mode passes, not through bulk backfill. When curate touches a file, it considers cross-ref opportunities as part of the pass.

**Staleness:** Cross-refs can decay two ways:
1. **Target deleted** — the file no longer exists (caught by glob)
2. **Relationship decay** — the file exists but the stated reason no longer holds (e.g., content was refactored to cover different topics). Curate checks both during its staleness pass.

**Prioritize islands.** Files with no persona refs and no inbound cross-refs are discoverable only by filename match. Target these first, especially when they share no obvious keyword overlap with related files.

## Cross-Reference Types: Semantic vs Discovery

Two distinct purposes for `## Cross-Refs` cross-references in learnings files:

- **Discovery** ("this file also exists") — redundant when a curated index is present; the index surfaces all files with descriptions. Can be dropped.
- **Semantic** ("when using X with Y, the interaction matters because Z") — carries contextual reasoning that no index description can replicate. Keep these; they fire when a file is *already loaded* and provide targeted follow-up context.

**Test:** Does the cross-reference explain *why* the interaction matters, or just that another file exists? If the latter, the index makes it redundant.

## CLAUDE.md as Curated Directory Index

A `CLAUDE.md` in a reference directory (e.g., `~/.claude/learnings/`) can serve as a curated index: one entry per file with a filename and one-line description grouped by domain. This replaces the glob → derive terms → sniff pipeline with a single read.

**Design:** Federated — each directory owns its `CLAUDE.md`. A parent index conditionally references child indexes (`if ~/.claude/learnings-private/CLAUDE.md exists, read it too`). No eager loading; files are read on demand after scanning the index.

**Why it works:** The sniff step (read 5 lines to check relevance) exists because filenames alone are weak signals. Descriptions make sniffing unnecessary. The pipeline was compensating for missing structure.

**Maintenance cost:** Low when there's a regular consolidation cadence — add an entry when adding a file, remove when removing.

## Avoid Nesting Subdirectories Inside learnings/

Content is either a guideline (in `guidelines/`) or a learning (in `learnings/`). Do not create a `guidelines/` subfolder inside `learnings/` — it creates type ambiguity and discoverability issues.

**The problem:** Files in `learnings/guidelines/` look like guidelines (behavioral, prescriptive) but live in the learnings directory. They won't be found by guideline searches, won't be candidates for `@`-import, and their location suggests they're reference material when they're actually behavioral rules.

**Rule:** If content is behavioral/prescriptive, decide: is it universal enough for `guidelines/`? If yes, put it there. If it's domain-specific, put it in a persona or keep it as a flat learning in `learnings/`. No middle ground.

## Avoid Catch-All Directories

When organizing files into subdirectories, don't create a `general/` or `misc/` directory for uncategorized files. Keep them at the root instead.

**Why:** A catch-all directory hides clustering signals. When 3+ root files share a theme, the clustering is visible and the promotion path to a new domain directory is obvious. Inside a catch-all, the same signal is buried in a grab-bag that never gets reviewed. The directory name carries no domain signal — it's a category that means "uncategorized."

**Rule:** Files that don't fit a domain directory stay at the root. Promote to a new directory when a theme emerges (3+ files). Review root files during curation passes.

## Keyword Gate Design: Dedup as Scoping Mechanism

When reintroducing a broad trigger (e.g., keyword-based learnings search), existing narrower gates + dedup can handle scoping naturally — a broad trigger doesn't need its own specificity filter if other gates already cover the common cases and dedup prevents redundant loads. Quoted terms from the operator bypass dedup as an explicit override.

## File Splitting and Directory Clustering

When learnings files grow large, the sniff becomes imprecise — loading 400 lines to find one 8-line section wastes context.

**Split threshold:** Flag files over ~150 lines during curation. Files under 150 lines are cheap enough to load fully.

**Split criteria:** Split when a file has clearly separable sub-topics. Leave dense files with many short sections (e.g., `code-quality-instincts.md` at 4.2 lines/section) — they're already atomic, just co-located.

**Directory promotion:** When a domain accumulates 3+ files (from splitting or natural growth), promote to a subdirectory: `learnings/skill-authoring/`, `learnings/xrpl/`, etc.

**Cluster index pattern:** Each subdirectory gets an `INDEX.md` (like `content-types.md` serves for the authoring cluster). The index handles intra-cluster navigation — individual files point `**Related:**` back to their index rather than cross-referencing every sibling. This keeps cross-ref counts manageable as file count grows.

**Cross-cluster refs:** Remain file-to-file for precision. `skill-authoring/contracts.md → multi-agent/orchestration.md` is a genuine domain intersection that should be explicit, not abstracted to cluster-to-cluster.

**Curate skill scoping:** Curate operates on one cluster at a time. Within a cluster: maintain the index, verify internal consistency. Between clusters: verify cross-cluster refs still resolve, but don't reorganize the target cluster.

**Search pipeline impact:** Directory structure enables glob scoping — "does this session involve XRPL?" → no → skip entire `xrpl/` directory. Reduces sniff cost from "all files" to "relevant cluster files."

**Split grouping heuristic:** Group sections by co-search likelihood: "if someone is searching for topic A, what other topics would they also need in the same work context?" Sections that co-occur during the same task belong in the same file. Dense files (under ~6 lines/section average) resist splitting — the sections are too interleaved and short to form coherent standalone files. Skip these even if they exceed the line threshold.

## Sub-Cluster Nesting

Clusters can contain sub-clusters when a tighter domain emerges within an existing cluster. The same 3+ file threshold applies: when 3+ files within a cluster share a narrower domain than the parent, promote them to a sub-cluster.

**Depth cap:** Maximum 2 directory levels below `learnings/` — i.e., `learnings/cluster/subcluster/file.md`. If a sub-cluster would itself need sub-clusters, promote the sub-cluster to a top-level cluster instead. Deeper nesting adds navigation cost that outweighs the organizational benefit.

**When to nest vs promote to top-level:**
- **Nest** when the sub-cluster's content is genuinely specific to the parent domain. Test: "Would someone searching for this sub-topic always also be in the parent domain?" If yes, nest. Example: `claude-code/multi-agent/` — multi-agent orchestration in the learnings corpus is Claude Code–specific, not general-purpose.
- **Promote** when the sub-cluster has independent search value outside the parent domain, or when the content applies across multiple parent domains. Example: if `multi-agent/` patterns applied to arbitrary agent frameworks, it belongs at the top level.

**Sub-cluster CLAUDE.md:** Each sub-cluster gets its own `CLAUDE.md` with a routing table for its files. The parent cluster's `CLAUDE.md` lists sub-clusters as pointers (like the top-level `learnings/CLAUDE.md` lists clusters), not individual sub-cluster files:

```markdown
## Sub-clusters

- `multi-agent/CLAUDE.md` — Work distribution, coordination, quality, parallelization
```

**Cross-ref semantics at depth:**
- Refs between files within the same sub-cluster → intra-cluster (handled by sub-cluster `CLAUDE.md`, no explicit cross-refs needed)
- Refs from a sub-cluster file to a sibling file in the parent cluster → cross-cluster (explicit file-to-file, full `~/.claude/learnings/...` path)
- Refs from a sub-cluster file to a file in a different top-level cluster → cross-cluster (same as today)

**Curate scoping:** Sub-clusters are treated as independent curation units. In broad sweeps, each sub-cluster gets its own subagent alongside top-level clusters. The parent cluster's flat files (those not in any sub-cluster) form their own curation unit.

**Residual files:** Files that don't fit any sub-cluster stay flat in the parent cluster directory. The same "avoid catch-all" rule applies — don't create a `general/` sub-cluster for leftovers.

## Cross-Refs

No cross-cluster references.
