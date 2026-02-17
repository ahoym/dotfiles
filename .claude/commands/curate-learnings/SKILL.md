---
description: Curate learnings, guidelines, and skills — consolidate, reorganize, or prune
---

# Curate Learnings

Review learnings, guidelines, or skills to identify content that should be migrated, reorganized, or pruned.

## Usage

- `/curate-learnings <file-path>` - Curate a specific file (relative to `~/.claude/`)
- `/curate-learnings <file1> <file2>` - Curate multiple files
- `/curate-learnings` - Prompt for which file to curate

## Reference Files (conditional — read in step 4)

- classification-model.md - The 6-bucket classification model with decision criteria (learnings/guidelines) and skill pruning criteria (skills)
- `~/.claude/commands/compound-learnings/content-type-decisions.md` - Skill vs guideline vs learning decision tree (for reorganization recommendations)

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
  - commands/git-split-pr
  - ...
  ```
- Store selection as `TARGET_FILES`

---

## Content Mode (learnings & guidelines)

### 2. Parse file into patterns

For each file in `TARGET_FILES`:
1. Read the file content
2. Identify discrete patterns/sections (typically H2 or H3 headers)
3. For each pattern, extract:
   - **Title**: The section heading
   - **Content summary**: 1-2 sentence description
   - **Line count**: Approximate size
   - **Has code examples**: Yes/No
   - **Has templates**: Yes/No (tables, checklists, structured formats)

Store as `PATTERNS` list.

### 3. Cross-reference existing skills and guidelines

**This step must be thorough — read the actual skill/guideline files, don't just grep for keywords.** Shallow cross-referencing leads to wrong classifications (e.g., recommending "migrate" when the content is already fully covered).

For each pattern in `PATTERNS`:
1. Search existing skills in `~/.claude/commands/` for related content
2. **Read the relevant skill files** (SKILL.md and reference files) to check for coverage
3. Search guidelines in `~/.claude/guidelines/` for related content
4. Note any matches:
   - **Exact match**: Pattern is already fully covered
   - **Partial match**: Related skill/guideline exists but doesn't cover this
   - **No match**: No existing skill/guideline covers this topic

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

### 5. Check for underutilized skills

While cross-referencing, note any skills that:
- Have no corresponding usage in learnings or guidelines
- Overlap significantly with another skill
- Reference patterns that no longer exist in the codebase

Flag these as `SKILL_REVIEW_CANDIDATES`.

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

### Recommended Actions
...
```

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

For **content mode** actions:
- Skill migrations: add pattern to target skill's reference files or instructions
- Guideline migrations: add pattern as new section in target guideline
- Outdated deletions: delete the section from source file (with approval)
- Standalone reference: no action, pattern stays in place

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
User: /curate-learnings commands/git-monitor-pr-comments

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

## Important Notes

- **User approval required**: Always use `AskUserQuestion` before applying changes
- **Discuss option**: Always include for medium-confidence items
- **Deletion with approval**: Content/skills can be deleted if user approves
- **Preserve context**: When migrating, ensure content retains enough context to be useful standalone
- **Update cross-references**: If content is migrated, update any internal links in the source file
- **Frequency**: Designed for regular use to prevent bloat across learnings, guidelines, and skills
- **Complements compound-learnings**: This curates existing content; `compound-learnings` creates new content
