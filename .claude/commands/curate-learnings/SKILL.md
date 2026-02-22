---
description: Curate learnings, guidelines, and skills — consolidate, reorganize, or prune
---

# Curate Learnings

Review learnings, guidelines, or skills to identify content that should be migrated, reorganized, or pruned.

## Usage

- `/curate-learnings <file-path>` - Curate a specific file (relative to `~/.claude/`)
- `/curate-learnings <file1> <file2>` - Curate multiple files
- `/curate-learnings` - Prompt for which file to curate

## Reference Files (conditional)

- `~/.claude/commands/_shared/corpus-cross-reference.md` — Corpus loading and cross-referencing procedure — read in step 3
- classification-model.md — The 6-bucket classification model with decision criteria (learnings/guidelines) and skill pruning criteria (skills) — read in step 4
- `~/.claude/commands/compound-learnings/content-type-decisions.md` — Skill vs guideline vs learning decision tree (for reorganization) — read in step 4
- persona-design.md — Persona structure, naming, sizing, and suggestion criteria — read in step 5a when persona clusters are detected

## Parallel Execution

This skill has several steps that can run concurrently. **Use parallel tool calls aggressively** to reduce wall-clock time:

| Opportunity | When | How |
|---|---|---|
| **Pre-load + parse** | Always (content mode) | Steps 2 + 3-reads: parse target files AND bulk-read all skill/guideline files in the same tool-call batch |
| **Multi-file pipelines** | 2+ target files in content mode | Launch one Task subagent per file for steps 2→5a, merge results at step 6 |
| **Steps 5 + 5a** | Single-file content mode | Run underutilized-skill check and persona detection as parallel tool calls after step 4 |
| **Broad sweep clusters** | "All learnings" mode | After clustering (step 2), launch one Task subagent per domain/stack cluster for analysis |
| **Apply actions** | Step 7, after user approval | Execute independent file writes (different target files) as parallel tool calls |

Detailed instructions for each opportunity are inline in the relevant steps below (marked with **⚡ Parallel**).

## Instructions

### 1. Get target file(s)

**If `$ARGUMENTS` provided**:
- Parse as space-separated file paths (relative to `~/.claude/`)
- Verify each file exists under `~/.claude/` (e.g., `learnings/`, `guidelines/`, `commands/`)
- Determine the **curation mode** per file:
  - `learnings/*` or `guidelines/*` → **Content mode** (pattern-level analysis)
  - `commands/*` → **Skill mode** (skill-level evaluation)
- Store as `TARGET_FILES`

**If no arguments**:
- List available files under `~/.claude/learnings/`, `~/.claude/guidelines/`, and skill directories under `~/.claude/commands/`
- Use `AskUserQuestion` to prompt user:
  ```
  What would you like to curate?

  Learnings:
  - learnings/nextjs.md
  - ...

  Guidelines:
  - guidelines/communication.md
  - ...

  Skills:
  - commands/do-security-audit
  - commands/git/split-pr
  - ...
  ```
- Store selection as `TARGET_FILES`

**If user selects "all learnings" (broad sweep mode)**:

Broad sweep uses a **cluster-first approach** instead of per-file pattern analysis:

1. Read all learnings files (use parallel Read calls for all files in one batch)
2. Cluster files by domain/stack (e.g., "XRPL + TypeScript", "Java + Spring", "Python", "Meta/tooling")
3. **⚡ Parallel: per-cluster analysis.** Launch one **Task subagent per cluster** to run steps 3–5a independently. Each subagent: counts files & patterns, checks for matching personas, flags thin pointer files, classifies patterns needing action, and detects persona opportunities. Merge all subagent results for the report.
4. Flag thin pointer files (< 20 lines, mostly cross-references) as fold-and-delete candidates
5. Run step 5a (persona detection) across all clusters simultaneously
6. Only classify individual patterns when they need action (outdated, migrate, enhance persona, genericize)
7. Use the **broad sweep report format** (see step 6)

**Why cluster-first:** Classifying all ~50 patterns individually produces an unreadable table. Most are "standalone reference / keep." Clustering surfaces the high-value actions (persona enhancements, thin file cleanup, staleness) without the noise.

**Consecutive sweeps compound:** Each sweep's actions (enhanced personas, deleted files, moved content) create new state for the next sweep to evaluate. For example, after folding `spring-patterns.md` content into `java-backend`, a follow-up sweep can check whether `spring-patterns.md` is now partially redundant. Run 2-3 consecutive sweeps to fully distill.

---

## Content Mode (learnings & guidelines)

### 2 + 3. Parse files and pre-load reference corpus

**⚡ Parallel: pre-load + parse.** These two activities are independent — run them in the same batch of parallel tool calls:

**Parse (step 2)** — For each file in `TARGET_FILES`:
1. Read the file content
2. Identify discrete patterns/sections (typically H2 or H3 headers)
3. For each pattern, extract:
   - **Title**: The section heading
   - **Content summary**: 1-2 sentence description
   - **Line count**: Approximate size
   - **Has code examples**: Yes/No
   - **Has templates**: Yes/No (tables, checklists, structured formats)
4. Store as `PATTERNS` list

**Pre-load (step 3 reads)** — In the same parallel batch as the parse reads above:
1. Read `~/.claude/commands/_shared/corpus-cross-reference.md` for the corpus loading procedure
2. Follow its "Loading the Corpus" section to load skills, skill reference files, guidelines, and learnings
3. Additionally load: `~/.claude/commands/set-persona/*.md` (needed for step 5a)
4. Read classification-model.md and `~/.claude/commands/compound-learnings/content-type-decisions.md` (needed for step 4)

Store all pre-loaded content for use in subsequent steps.

**⚡ Parallel: multi-file pipelines.** When `TARGET_FILES` contains 2+ content-mode files, launch one **Task subagent per file** to run steps 2→5a independently. Each subagent receives the full pre-loaded reference corpus. Merge all subagent results at step 6.

### 3 (cont). Cross-reference patterns against corpus

Follow the "Cross-Referencing Content" procedure in `corpus-cross-reference.md`. Use the match types (exact, partial, thematic, no match) and confidence levels defined there.

**Do NOT present the classification table (step 6) until this step is fully complete.** Getting this wrong means the user approves actions based on incorrect information.

### 4. Classify each pattern

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

**Project CLAUDE.md redundancy check:** For any learning file named after a specific project (e.g., `payment-service-setup.md`), check if that project has a CLAUDE.md. If so, compare each pattern against the project CLAUDE.md — content already covered there is an outdated (migrated) candidate.

### 5 + 5a. Check underutilized skills AND detect persona opportunities

**⚡ Parallel: steps 5 + 5a.** These two analyses are independent — run them as parallel tool calls after step 4.

**Step 5 — Underutilized skills.** Using the pre-loaded skill corpus, note any skills that:
- Have no corresponding usage in learnings or guidelines
- Overlap significantly with another skill
- Reference patterns that no longer exist in the codebase

Flag these as `SKILL_REVIEW_CANDIDATES`.

**Step 5a — Persona opportunities.** Check whether curated patterns cluster around a domain/stack that could benefit from a persona:

1. **Tag each pattern** with its domain and stack (e.g., "XRPL + TypeScript", "React + Next.js", "Java + Spring")
2. **Count clusters**: Group patterns by domain/stack combination
3. **Check existing personas**: Glob `~/.claude/commands/set-persona/*.md` and `.claude/personas/*.md`
4. **Evaluate against criteria** (read `persona-design.md` for full criteria):
   - **New persona**: 3+ learnings files with patterns for the same domain/stack, no matching persona exists, 8+ discrete gotchas/patterns
   - **Enhance existing persona**: Patterns match an existing persona's domain but aren't covered in it yet
   - **No action**: Patterns are too scattered across domains, or already covered by an existing persona

Store matches as `PERSONA_SUGGESTIONS` (may be empty).

**Skip this step** if curating a single small file with < 3 patterns.

---

## Skill Mode (commands)

### 2s. Read the skill package

For the target skill directory:
1. Read `SKILL.md` (main instructions)
2. List and read all reference files in the skill directory
3. Note the skill's description, usage patterns, and reference file count

### 3s. Evaluate the skill

Using the Skill Pruning Criteria in classification-model.md, evaluate:

| Dimension | What to check |
|-----------|---------------|
| **Relevance** | Is the workflow this skill automates still used? |
| **Overlap** | Does another skill do 80%+ the same thing? |
| **Complexity vs value** | Does the skill's complexity justify its usage frequency? |
| **Reference freshness** | Are reference files current, or do they reference stale patterns? |
| **Scope** | Is the skill too broad (should split) or too narrow (should merge)? |

Also check:
- Does the skill have reference files that could be pruned or consolidated?
- Is the skill description accurate for what it actually does?
- Are there missing reference files that would improve execution?

### 4s. Classify the skill

| Classification | Description |
|----------------|-------------|
| **Keep** | Skill is relevant, well-scoped, and reference files are current |
| **Enhance** | Skill is useful but missing context, reference files, or coverage |
| **Merge** | Skill overlaps significantly with another — combine them |
| **Split** | Skill is too broad — break into focused skills |
| **Prune** | Skill is outdated, too specialized, or easily done manually |

For each classification, note:
- **Confidence**: High/Medium/Low
- **Rationale**: Why this classification
- **Target**: If merging/enhancing, which skill?

---

## Shared Steps (both modes)

### 6. Generate recommendations

Display the full report inline in the CLI.

**Content mode report:**
```
## Curation Summary: <filename>

### Patterns Analyzed: N

| # | Pattern | Lines | Classification | Confidence | Target |
|---|---------|-------|----------------|------------|--------|
| 1 | Comparison Table Template | 21-32 | Template for skill | High | init-ralph-research |
| 2 | Signs Directory Superseded | 34-40 | Context for skill | Medium | init-ralph-research |

### Persona Suggestions (if any)

| Suggestion | Action | Evidence |
|------------|--------|----------|
| Create `python-fastapi-backend` | New persona | 8 patterns across 3 files, no persona exists |
| Enhance `xrpl-typescript-fullstack` | Add 2 gotchas | New Turbopack patterns not in existing persona |

### Recommended Actions
...
```

**Broad sweep report** (when curating all learnings):
```
## Broad Sweep: All Learnings (N files, ~M patterns)

### Domain/Stack Clusters

| Cluster | Files | Patterns | Existing Persona |
|---------|-------|----------|-----------------|
| XRPL + TypeScript | xrpl-patterns, react-patterns, ... | 13 | xrpl-typescript-fullstack |
| Java + Spring | spring-patterns, ... | 5 | java-backend, java-devops |

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

### Suggested Deep Dives

| File | Why | Command |
|------|-----|---------|
| `parallel-plans.md` | 2 medium-confidence items, 3 new sections | `/curate-learnings learnings/parallel-plans.md` |
| `skill-design.md` | 11 patterns, several skill-context candidates | `/curate-learnings learnings/skill-design.md` |

### Recommended Actions
...
```

**Deep dive criteria** — include a file in "Suggested Deep Dives" when any of these apply:
- **Medium-confidence items**: patterns where classification is uncertain and needs per-pattern cross-referencing
- **High pattern count**: files with 5+ patterns are more likely to have migration candidates that cluster-level analysis misses
- **New content since last sweep**: files that grew by 3+ sections since the previous sweep
- **Context-for-skill clusters**: multiple patterns in one file that could fold into the same skill's reference files

Omit this section if no files meet the criteria (collection is fully curated).

**Skill mode report:**
```
## Skill Curation: <skill-name>

### Overview
- **Description**: ...
- **Files**: SKILL.md + N reference files
- **Classification**: Keep / Enhance / Merge / Split / Prune
- **Confidence**: High/Medium/Low

### Evaluation
- **Relevance**: ...
- **Overlap**: ...
- **Reference freshness**: ...
- **Scope**: ...

### Recommended Actions
- [ ] Action 1
- [ ] Action 2
```

### 7. Apply changes (with approval)

For each recommended action, use `AskUserQuestion` to confirm:

```
Apply these changes?

Options: [Apply all] [Select specific] [Discuss] [Skip]
```

Always include a **Discuss** option, especially for medium-confidence items.

**If user approves**:

**⚡ Parallel: apply actions.** Group approved actions by target file. Actions targeting **different files** are independent — execute them as parallel tool calls. Actions targeting the **same file** must be sequential (to avoid edit conflicts).

For **content mode** actions:
- Skill migrations: add pattern to target skill's reference files or instructions
- Guideline migrations: add pattern as new section in target guideline
- Outdated deletions: delete the section from source file (with approval). If all sections in a file are deleted or folded elsewhere, delete the entire file.
- Standalone reference: no action, pattern stays in place. If examples use project-specific names, genericize them while preserving the pattern's teaching value.
- Thin pointer file: fold substantive content into the target persona/skill, delete the source file
- **New persona**: read `persona-design.md`, mine relevant learnings files, draft persona using the 4-section structure, write to `~/.claude/commands/set-persona/<name>.md`
- **Enhance persona**: read `persona-design.md` for section descriptions, then read the target persona file. For each pattern, map it to the appropriate section: gotchas/platform facts → "Known gotchas & platform specifics", actionable checks → "When reviewing or writing code", decision principles → "When making tradeoffs", focus areas → "Domain priorities". Append to the matching section.

For **skill mode** actions:
- Enhance: add missing reference files or context to the skill
- Merge: combine two skills into one, delete the redundant one
- Split: create new skill directories, distribute content
- Prune: delete the skill directory (with approval)

### 8. Report results

```
## Curation Complete

**Curated**: <file or skill name>

**Actions taken**:
- ...

**Skills flagged for review**: N
```

## Example Sessions

### Content mode
```
User: /curate-learnings learnings/nextjs.md

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

### Skill mode
```
User: /curate-learnings commands/git/monitor-pr-comments

Claude:
## Skill Curation: git-monitor-pr-comments

### Overview
- **Description**: Watch a PR in background and address new comments
- **Files**: SKILL.md + 2 scripts (init-tracking.sh, monitor-script.sh)
- **Classification**: Prune
- **Confidence**: Medium

### Evaluation
- **Relevance**: Specialized — background polling for PR comments
- **Overlap**: Partially overlaps with git-address-pr-review
- **Complexity vs value**: Requires background agent setup for occasional use
- **Reference freshness**: Scripts are current

### Recommended Actions
- [ ] Prune skill (complex setup, rare use case)

Apply? [Apply all] [Discuss] [Skip]
```

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

## Important Notes

- **User approval required**: Always use `AskUserQuestion` before applying changes
- **Discuss option**: Always include for medium-confidence items
- **Deletion with approval**: Content/skills can be deleted if user approves
- **Preserve context**: When migrating, ensure content retains enough context to be useful standalone
- **Update cross-references**: If content is migrated, update any internal links in the source file
- **Frequency**: Designed for regular use to prevent bloat across learnings, guidelines, and skills
- **Complements compound-learnings**: This curates existing content; `compound-learnings` creates new content
