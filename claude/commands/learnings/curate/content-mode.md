# Content Mode (learnings & guidelines)

## 2. Parse files and pre-load reference corpus

**⚡ Parallel: pre-load + parse.** These two activities are independent — run them in the same batch of parallel tool calls:

**Parse** — For each file in `TARGET_FILES`:
1. Read the file content
2. Identify discrete patterns/sections (typically H2 or H3 headers)
3. For each pattern, extract:
   - **Title**: The section heading
   - **Content summary**: 1-2 sentence description
   - **Line count**: Approximate size
   - **Has code examples**: Yes/No
   - **Has templates**: Yes/No (tables, checklists, structured formats)
4. Store as `PATTERNS` list

**Pre-load** — In the same parallel batch as the parse reads above:
1. **Load the reference corpus**: Read all files in `~/.claude/learnings/` and its cluster subdirectories (learnings), `~/.claude/learnings-private/` (private learnings), `~/.claude/guidelines/` (guidelines), and skill directories under `~/.claude/commands/` (skills + reference files). Use recursive glob (`**/*.md`) to catch cluster subdirectories. **Read all files** — don't pre-filter or skip files based on name/size.
2. Additionally load: `~/.claude/commands/set-persona/*.md` (needed for step 6)
3. Read classification-model.md and `~/.claude/learnings/claude-authoring/routing-table.md` (needed for step 5)

Store all pre-loaded content for use in subsequent steps.

**⚡ Parallel: multi-file pipelines.** When `TARGET_FILES` contains 2+ content-mode files, launch one **Task subagent per file** to run steps 2→6 independently. Each subagent receives the full pre-loaded reference corpus. Merge all subagent results at step 7.

## 3. Cross-reference patterns against corpus

**Grep scope:** When grepping for pattern terms, scope to content directories only: `~/.claude/learnings/`, `~/.claude/learnings-private/`, `~/.claude/guidelines/`, `~/.claude/commands/`, `~/.claude/skill-references/`. Exclude `debug/`, `history*`, `file-history/`, `projects/`, `plugins/cache/` — these contain conversation logs and cached data that produce massive false-positive noise.

For each pattern, check against the pre-loaded corpus for matches:
- **Exact match**: Same concept with same or very similar wording in another file → HIGH confidence
- **Partial match**: Same concept but different scope, detail level, or framing → MEDIUM confidence
- **Thematic match**: Related concept in the same domain but different specific insight → LOW confidence
- **No match**: Novel pattern not covered elsewhere

**Do NOT present the classification table (step 7) until this step is fully complete.** Getting this wrong means the user approves actions based on incorrect information.

## 4. File-level gates

### 4a. Reference-file gate (`skill-references/*` only)

**Before pattern-level classification**, identify which skills consume this file — grep for the filename across `~/.claude/commands/`. Reference files are authoritative: they are the single source of truth for shared patterns consumed by multiple skills.

**When cross-referencing (step 3) finds duplicated content in a consuming skill**, the classification must be **"Standalone reference (keep) — deduplicate consumer"**, not "Outdated (duplicated)." The recommended action is to replace the skill's inline content with a pointer back to this reference file (e.g., "See `agent-prompting.md` § Git Workflow").

**Actions:**
- **Pattern duplicated in consumer skill** → Classify as standalone reference. Recommended action: trim the skill's inline copy, add a reference pointer.
- **Pattern not found in any consumer** → Classify normally (may be standalone, outdated, etc.).
- **Pattern partially covered in consumer** → The reference version is authoritative. Flag the consumer's partial copy for alignment.

### 4b. Guideline gate (`guidelines/*` only)

**Before pattern-level classification**, check whether the guideline belongs in `guidelines/` at all. Guidelines must be universal — applicable to any agent regardless of stack, language, or project.

**Test:** Does every pattern in this file apply equally to a Java agent, a Python agent, and a TypeScript agent? If any pattern references a specific framework, library, language feature, or project path, the file contains content that belongs in `learnings/`, not `guidelines/`.

**Actions:**
- **All patterns are stack-specific** → Merge useful content into the domain's existing learning file (e.g., `learnings/testing-patterns.md`), delete the guideline. Skip step 5 entirely.
- **Mix of universal and stack-specific** → Flag stack-specific patterns for migration to learnings. Proceed to step 5 only for the universal patterns.
- **All patterns are universal** → Proceed to step 5 normally.

See `~/.claude/learnings/claude-authoring/routing-table.md` → "Evaluating Existing Guidelines" for the full migration signal table.

## 5. Classify each pattern

Using the criteria in classification-model.md, classify each pattern into one of:

| Classification | Description |
|----------------|-------------|
| **Skill candidate** | Actionable, repeatable workflow → Create or enhance skill |
| **Template for skill** | Reusable structure/format → Skill references or embeds it |
| **Context for skill** | Explanatory material → Skill includes as preamble or reference |
| **Guideline candidate** | Code standard or practice → Migrate to `~/.claude/guidelines/` |
| **Standalone reference** | Useful but no skill connection → Keep as learning |
| **Outdated** | Superseded, references non-existent code, or deprecated → Delete candidate |

For each classification, note:
- **Confidence**: High/Medium/Low
- **Rationale**: Why this classification
- **Target**: If migrating, where should it go?

**Conciseness check:** For patterns classified as "Standalone reference" (keep), also evaluate token efficiency:
- Could the pattern express the same insight in fewer tokens without losing teaching value?
- Are there redundant phrasing, over-explained concepts, or excessive examples?
- Could code examples be shortened while preserving the teaching point?

Flag patterns where meaningful compression (~30%+) is achievable. Include as a "Compress" action in the recommendations.

**Project CLAUDE.md redundancy check:** For any learning file named after a specific project (e.g., `payment-service-setup.md`), check if that project has a CLAUDE.md. If so, compare each pattern against the project CLAUDE.md — content already covered there is an outdated (migrated) candidate.

## 5b. Cross-reference opportunities

For each file being curated, evaluate its `## Cross-Refs` section and `**Related:**` header line. See `~/.claude/learnings/claude-authoring/learnings-organization.md` → "Cross-Reference Convention" for the full convention.

**Cluster-aware rules:**
- Files in a cluster or sub-cluster should have **no intra-cluster refs** — the nearest `CLAUDE.md` (sub-cluster or cluster) handles sibling discovery.
- Cross-cluster refs use full `~/.claude/learnings/...` paths. This includes refs from a sub-cluster file to a sibling file in the parent cluster — these cross a cluster boundary.
- Flag any intra-cluster cross-refs for removal.

**Staleness check** (if `## Cross-Refs` exists):
1. **Existence:** Glob to confirm each target file still exists at its full path. Flag missing targets for removal (files may have moved into clusters).
2. **Relationship decay:** For each cross-ref, check whether the stated reason still describes a real overlap between the two files. Flag cross-refs where the reason no longer holds.

**New cross-ref suggestions:**
- Only suggest **cross-cluster** refs — relationships between files in different clusters or between cluster files and flat files
- Identify 1-3 related files where the relationship is **non-obvious from vocabulary** (wouldn't be found by keyword search)
- Don't suggest cross-refs where shared vocabulary already connects the files (the keyword search protocol handles those)

**Inbound reference check (consuming personas and skills):**
Grep `~/.claude/commands/set-persona/` for paths referencing files in the curated cluster — Proactive Cross-Refs, Cross-Refs, and `> Full criteria:` section refs. Check for:
1. **Stale paths** from pre-cluster flat naming (e.g., `claude-authoring-skills.md` → should be `claude-authoring/skill-design.md`). These cause silent knowledge loss — the persona loads nothing instead of the intended file.
2. **Split casualties** — refs to a file that was split this session (e.g., `learnings.md` → `learnings-content.md` + `learnings-organization.md`). Update to point to the appropriate successor file.

Flag stale inbound refs as HIGH confidence actions — they're unambiguous and high-impact.

Store findings as `CROSSREF_ACTIONS` (stale removals + new suggestions + stale inbound refs). Report alongside other classifications in step 7.

## 6. Check underutilized skills and detect persona opportunities

**⚡ Parallel.** These two analyses are independent — run them as parallel tool calls after step 5.

**Underutilized skills.** Using the pre-loaded skill corpus, note any skills that:
- Have no corresponding usage in learnings or guidelines
- Overlap significantly with another skill
- Reference patterns that no longer exist in the codebase

Flag these as `SKILL_REVIEW_CANDIDATES`.

**Domain organization & persona opportunities.** Check whether curated patterns are well-organized for dynamic pulling (per `context-aware-learnings` guideline) and whether a persona lens would add value:

1. **Tag each pattern** with its domain and stack (e.g., "XRPL + TypeScript", "React + Next.js", "Java + Spring")
2. **Count clusters**: Group patterns by domain/stack combination
3. **Check learnings organization first**:
   - Does each domain cluster have a well-named learnings file that serves as a keyword index? (e.g., `aws-patterns.md` for AWS, `vercel-deployment.md` for Vercel)
   - Are patterns in the right files for keyword-based discovery? A Fargate gotcha in a generic `deployment.md` is harder to find than in `aws-patterns.md`.
   - **Suggest reorganization** when patterns would be more discoverable in a differently-named or split file.
4. **Check existing personas**: Glob `~/.claude/commands/set-persona/*.md` and `.claude/personas/*.md`
5. **Evaluate persona opportunity** (read `persona-design.md` for full criteria):
   - **New persona**: Only when a domain cluster needs a distinct *lens* (tradeoff priorities, review posture) — not just factual knowledge. 3+ learnings files, 8+ patterns, AND identifiable judgment patterns (not just gotchas).
   - **Enhance existing persona**: Only for lens-type content (priorities, tradeoffs, review heuristics). Factual gotchas should stay in or be moved to learnings files.
   - **No action**: Patterns are purely factual (belong in learnings), too scattered, or already covered.

Store matches as `DOMAIN_SUGGESTIONS` (learnings reorganization) and `PERSONA_SUGGESTIONS` (lens creation/enhancement). Both may be empty.

**Skip this step** if curating a single small file with < 3 patterns.

---

## Broad Sweep (all learnings)

When the user selects "all learnings", use a **cluster-first approach**. Learnings are organized into cluster subdirectories (e.g., `xrpl/`, `frontend/`, `claude-authoring/`) which may contain sub-clusters (e.g., `claude-code/multi-agent/`), with flat files at root.

1. Read all learnings files recursively (use parallel Read calls). Read each cluster's and sub-cluster's `CLAUDE.md` for its routing table.
2. Use existing directory structure as clusters — don't re-derive. Sub-clusters are independent curation units alongside top-level clusters. Flat files at root form a "general" group. Flat files within a cluster (not in any sub-cluster) form that cluster's own curation unit.
3. **⚡ Parallel: per-cluster analysis.** Launch one **Task subagent per cluster and per sub-cluster** to run steps 3–6 independently. Each subagent: counts files & patterns, checks for matching personas, flags thin pointer files, classifies patterns needing action, and detects persona opportunities. Merge all subagent results for the report.
4. Flag thin pointer files (< 20 lines, mostly cross-references) as fold-and-delete candidates
5. **Split candidates.** Flag files over ~150 lines that have clearly separable sub-topics. See `~/.claude/learnings/claude-authoring/learnings-organization.md` → "File Splitting and Directory Clustering" for conventions. Report as a separate section.
6. Run persona detection (step 6) across all clusters simultaneously
7. **Per-file quality scan.** During the file read phase (or as a parallel pass after clustering), check each file for:
   - **Genericization candidates**: A file containing domain-specific terms that isn't in that domain's cluster → genericization candidate. Also check for project-specific patterns: hardcoded app names, route paths, class names that aren't framework-standard.
   - **Compression candidates**: Files with patterns that have high line-count relative to insight count (e.g., 30+ line patterns with large code blocks). Flag files where estimated compression >= 30%.
   - **Cluster promotion candidates**: Flat files at root that share a domain with 2+ other flat files → suggest promoting to a cluster subdirectory.

   Store as `POLISH_CANDIDATES`. These are reported separately from HIGH/MEDIUM/LOW findings — they're quality signals, not classification changes.
8. Only classify individual patterns when they need action (outdated, migrate, enhance persona, genericize)
9. Use the **broad sweep report format** below

10. **Cross-reference graph health.** After cluster analysis, scan `## Cross-Refs` and `**Related:**` across learnings files and report:
   - **Stale intra-cluster refs:** Files with sibling cross-refs that should have been removed (cluster CLAUDE.md handles these)
   - **Isolated nodes:** Files with zero cross-cluster refs (self-contained or orphaned?)
   - **Missing cross-cluster refs:** Files that share concepts across clusters but aren't linked
   - Format as a summary line (e.g., "Graph: 3 stale intra-cluster, 5 isolated, 2 missing cross-cluster links")

**Why cluster-first:** Clusters already exist as directories. The sweep validates their health (split candidates, cluster promotion, cross-ref hygiene) rather than re-deriving structure from scratch.

**Consecutive sweeps compound:** Each sweep's actions (enhanced personas, deleted files, moved content) create new state for the next sweep to evaluate. For example, after folding `spring-patterns.md` content into `java-backend`, a follow-up sweep can check whether `spring-patterns.md` is now partially redundant. Run 2-3 consecutive sweeps to fully distill.

---

## Content Report Formats

### Standard report (≤20 patterns)

```
## Curation Summary: <filename>

### Patterns Analyzed: N

| # | Pattern | Lines | Classification | Confidence | Target |
|---|---------|-------|----------------|------------|--------|
| 1 | Comparison Table Template | 21-32 | Template for skill | High | ralph:init |
| 2 | Signs Directory Superseded | 34-40 | Context for skill | Medium | ralph:init |

### Domain Organization (if any)

| Suggestion | Action | Evidence |
|------------|--------|----------|
| Split `deployment.md` | Rename/split into `aws-patterns.md` + `vercel-deployment.md` | Mixed domains, poor keyword discoverability |

### Persona Suggestions (if any)

| Suggestion | Action | Evidence |
|------------|--------|----------|
| Create `python-fastapi-backend` | New persona (lens) | Distinct tradeoff patterns across 3 files |
| Enhance `xrpl-typescript-fullstack` | Add review heuristic | New code review pattern (lens, not factual) |

### Recommended Actions
...
```

### Decomposition report (20+ patterns)

When a single file has 20+ patterns, the flat classification table becomes unreadable. Switch to a **destination-grouped format** that organizes patterns by where they should go:

```
## Curation Summary: <filename>

### Overview
**<size>, ~N patterns — <diagnosis>.** <1-2 sentence summary of why the file needs decomposition and what domains it spans.>

**Core recommendation:** <high-level action>

### DELETE — Already Covered Elsewhere (N patterns)

| # | Pattern | Lines | Covered By | Confidence |
|---|---------|-------|------------|------------|
| 1 | ... | ... | `file.md` line N: "..." | HIGH |

### MIGRATE — By Destination (~N patterns)

#### → `target-file.md` (N patterns)

| Pattern | Lines | Note |
|---------|-------|------|
| ... | ... | ... |

#### → `other-file.md` (N patterns)
...

### KEEP — Truly Cross-Cutting (~N patterns)

| Pattern | Lines | Note |
|---------|-------|------|
| ... | ... | ... |

### Compression Opportunities
...

### Recommended Actions
...
```

The destination grouping makes the actual decision ("where does this go?") the organizing principle instead of the classification taxonomy. Each destination group is self-contained and actionable.

**Confirmation checkpoint:** When the approved actions will touch 10+ files, confirm interpretation of user selections before executing — especially when the user provided freeform input rather than selecting a pre-defined option.

### Broad sweep report (when curating all learnings)

```
## Broad Sweep: All Learnings (N files, ~M patterns)

### Clusters

| Cluster | Files | Patterns | Existing Persona | Split Candidates |
|---------|-------|----------|-----------------|-----------------|
| xrpl/ | 6 | 22 | xrpl-typescript-fullstack | patterns.md (214 lines) |
| claude-authoring/ | 7 | 61 | — | skills.md (434 lines) |
| frontend/ | 7 | 18 | — | react-patterns.md (236 lines) |

### Split Candidates (files over ~150 lines with separable sub-topics)

| File | Lines | Sections | Suggested Split |
|------|-------|----------|----------------|
| claude-authoring/skills.md | 434 | 61 | ~7 files by sub-topic |
| claude-code/platform.md | 312 | 36 | ~4 files by area |

### Thin Pointer Files (fold-and-delete candidates)

| File | Lines | Content | Suggested Target |
|------|-------|---------|-----------------|
| observability-workflow.md | 14 | Mostly "see X" pointers | java-devops persona |

### Persona Suggestions

| Suggestion | Action | Evidence | Confidence |
|------------|--------|----------|------------|
| Enhance `java-backend` | Add Spring gotchas | 4 patterns not in seed persona | Medium |

### Highlights (patterns needing action only)

| # | File | Pattern | Action | Target |
|---|------|---------|--------|--------|
| 1 | api-design | Consistent Response Shapes | Genericize | Keep (remove Python examples) |

### Polish Opportunities

| # | File | Type | Detail | Command |
|---|------|------|--------|---------|
| 1 | playwright-patterns.md | Genericize | XRPL-specific references (address regex, currency encoding) | `/learnings:curate learnings/playwright-patterns.md` |
| 2 | api-design.md | Compress | 3 patterns with verbose code blocks (~35% compression achievable) | `/learnings:curate learnings/api-design.md` |

Omit this section if no candidates found.

### Suggested Deep Dives

| File | Why | Command |
|------|-----|---------|
| `claude-code/parallel-plans.md` | 2 medium-confidence items, 3 new sections | `/learnings:curate learnings/claude-code/parallel-plans.md` |
| `claude-authoring/skills.md` | 434 lines, split candidate | `/learnings:curate learnings/claude-authoring/skills.md` |

### Recommended Actions
...
```

**Deep dive criteria** — include a file in "Suggested Deep Dives" when it meets the **size threshold AND at least one action signal**:

**Size threshold** (necessary but not sufficient):
- 5+ patterns in the file

**Action signals** (at least one required):
- **Medium-confidence items**: patterns where classification is uncertain and needs per-pattern cross-referencing
- **New content since last sweep**: files that grew by 3+ sections since the previous sweep
- **Context-for-skill clusters**: multiple patterns that could fold into the same skill's reference files, AND the broad sweep didn't verify per-pattern coverage against the skill's reference files (cluster analysis checks thematic overlap, not line-by-line coverage)
- **Unverified cross-references**: patterns that reference specific skills but the skill files weren't read during cluster-level analysis

A large file with all High-confidence "standalone reference" classifications does NOT need a deep dive — the broad sweep already confirmed its status. Size alone indicates potential, not need.

Omit this section if no files meet the criteria (collection is fully curated).

## Content Mode Apply Actions

- Skill migrations: add pattern to target skill's reference files or instructions
- Guideline migrations: add pattern as new section in target guideline
- Outdated deletions: delete the section from source file (with approval). If all sections in a file are deleted or folded elsewhere, delete the entire file.
- Standalone reference: no action, pattern stays in place. If examples use project-specific names, genericize them while preserving the pattern's teaching value. When genericizing project-specific content, note in the report which project/domain the content originated from. If the project has a learnings directory (e.g., `docs/claude-learnings/`), suggest creating a project-specific instance there — the global file teaches the generic pattern, the project file preserves the concrete gotcha.
- Compress: rewrite the section to express the same insight more concisely — remove redundant phrasing, trim excessive examples, tighten explanations. Preserve the core insight and any code examples essential to understanding.
- Split file: for files over ~150 lines with separable sub-topics, propose a split into multiple files within the same cluster directory. Each new file gets a standardized header (description, keywords, related) and only cross-cluster refs. Update the cluster `CLAUDE.md` routing table to include the new files. See `~/.claude/learnings/claude-authoring/learnings-organization.md` → "File Splitting and Directory Clustering" for conventions.
- Promote to cluster: for flat files at root that share a domain with 2+ other flat files, create a cluster subdirectory with a `CLAUDE.md` routing table, move files in, update top-level `learnings/CLAUDE.md`.
- Promote to sub-cluster: for files within a cluster that share a narrower domain with 2+ siblings, create a sub-cluster subdirectory with its own `CLAUDE.md` routing table. Move files in, update the parent cluster's `CLAUDE.md` to list the sub-cluster as a pointer. See `~/.claude/learnings/claude-authoring/learnings-organization.md` → "Sub-Cluster Nesting" for when to nest vs promote to top-level.
- Thin pointer file: fold substantive content into the target persona/skill, delete the source file
- **New persona**: read `persona-design.md`, mine relevant learnings files, draft persona using the 4-section structure, write to `~/.claude/commands/set-persona/<name>.md`
- **Enhance persona**: read `persona-design.md` for section descriptions, then read the target persona file. For each pattern, map it to the appropriate section: gotchas/platform facts → "Known gotchas & platform specifics", actionable checks → "When reviewing or writing code", decision principles → "When making tradeoffs", focus areas → "Domain priorities". Append to the matching section.
- **Add cross-ref**: Append to or create `## Cross-Refs` section as the last section of the file. Follow the format in `~/.claude/learnings/claude-authoring/learnings-organization.md` → "Cross-Reference Convention". Use full `~/.claude/learnings/...` paths for cross-cluster refs. No intra-cluster refs — the nearest `CLAUDE.md` (sub-cluster or cluster) handles those. Refs from a sub-cluster file to a parent cluster sibling are cross-cluster.
- **Remove stale cross-ref**: Delete lines pointing to files that no longer exist or where the relationship decayed. Include the reason (file deleted vs. relationship no longer holds) in the report.
- **Add reverse cross-ref**: When adding A → B, also add B → A in the target file if the reverse provides lateral discovery value.

## Deep Dive Enriched Keyword Output

When running as a deep dive subagent (invoked from consolidate's diff-routed deep dive phase), append an enriched keyword section after the classification table. This feeds the keyword index's LLM-assisted enrichment.

**When to emit**: only when the subagent is processing curation targets (not comparison context files). The consolidate orchestrator will specify which files are curation targets.

**What to extract**: for each curated file, emit the terms that best describe its content for routing purposes. Focus on:
- Load-bearing concepts (not incidental mentions)
- Terms that would help someone find this file when working on a related problem
- Synonyms and related terms that mechanical extraction would miss
- Multi-word phrases that capture specific patterns (e.g., "stale rotation", "cross-ref graph")

**Format**:
```
## Enriched Keywords

| File | Keywords |
|------|----------|
| ralph-loop.md | stateless agent, convergence, worktree sentinel, runner-spec contract, one-action enforcement, wiggum |
| orchestration.md | work distribution, synthesis, parallel agents, context compaction, three-phase refactoring |
```

Aim for 8-20 keywords per file. Prefer specific over generic.

## Content Mode Example

```
User: /learnings:curate learnings/nextjs.md

Claude:
## Curation Summary: nextjs.md
### Patterns Analyzed: 2

| # | Pattern | Lines | Classification | Confidence | Target |
|---|---------|-------|----------------|------------|--------|
| 1 | Next.js 16: middleware → proxy | 3-26 | Standalone reference | High | Keep |
| 2 | Rate Limiter Wiring Pattern | 28-45 | Standalone reference | High | Keep (genericize) |

### Recommended Actions
**Keep as learning** (genericize project-specific details in pattern 2)

Apply? [Apply all] [Select specific] [Discuss] [Skip]
```
