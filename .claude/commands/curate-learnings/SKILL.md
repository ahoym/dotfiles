---
description: Review learnings to consolidate into skills or guidelines
---

# Curate Learnings

Review specific learning files to identify patterns that should be migrated to skills, used as templates, added as skill context, moved to guidelines, or flagged as outdated.

## Usage

- `/curate-learnings <file-path>` - Curate a specific learning file
- `/curate-learnings <file1> <file2>` - Curate multiple files
- `/curate-learnings` - Prompt for which learning file to curate

## Reference Files (conditional — read in step 4)

- classification-model.md - The 6-bucket classification model with decision criteria

## Instructions

### 1. Get target learning file(s)

**If `$ARGUMENTS` provided**:
- Parse as space-separated file paths
- Verify each file exists in `docs/claude-learnings/` or `.claude/guidelines/`
- Store as `TARGET_FILES`

**If no arguments**:
- Use `AskUserQuestion` to prompt user with available learning files:
  ```
  Which learning file would you like to curate?

  Options from docs/claude-learnings/:
  - backtest-warmup-period.md
  - ci-cd.md
  - git-workflow-patterns.md
  - ...
  ```
- Store selection as `TARGET_FILES`

### 2. Parse learning file into patterns

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

For each pattern in `PATTERNS`:
1. Search existing skills in `.claude/commands/` for related content
2. Search guidelines in `.claude/guidelines/` for related content
3. Note any matches:
   - **Exact match**: Pattern is already fully covered
   - **Partial match**: Related skill/guideline exists but doesn't cover this
   - **No match**: No existing skill/guideline covers this topic

### 4. Classify each pattern

Using the criteria in classification-model.md, classify each pattern into one of:

| Classification | Description |
|----------------|-------------|
| **Skill candidate** | Actionable, repeatable workflow → Create or enhance skill |
| **Template for skill** | Reusable structure/format → Skill references or embeds it |
| **Context for skill** | Explanatory material → Skill includes as preamble or reference |
| **Guideline candidate** | Code standard or practice → Migrate to `.claude/guidelines/` |
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

### 6. Generate recommendations

Display the full report inline in the CLI:

```
## Curation Summary: <filename>

### Patterns Analyzed: N

| # | Pattern | Lines | Classification | Confidence | Target |
|---|---------|-------|----------------|------------|--------|
| 1 | Comparison Table Template | 21-32 | Template for skill | High | init-ralph-research |
| 2 | Signs Directory Superseded | 34-40 | Context for skill | Medium | init-ralph-research |
| 3 | v1 Spec Structure | 264-350 | Outdated | High | Delete - already in spec-template.md |

### Pattern Details

For each pattern, include:
- **Rationale**: Why this classification was chosen
- **Cross-references**: What existing skills/guidelines relate to this

### Recommended Actions

**Migrate to skills:**
- [ ] Pattern 1 → Add to `init-ralph-research` as template
- [ ] Pattern 2 → Add to `init-ralph-research` as context

**Keep as learning:**
- Pattern 5: Standalone reference, no skill relevance

**Delete candidates:**
- Pattern 3: Superseded by v2 spec in same file

### Skills to Review
- `<skill-name>`: <reason for review>
```

### 7. Apply changes (with approval)

For each recommended action, use `AskUserQuestion` to confirm:

```
Apply these changes?

1. Add "Comparison Table Template" to init-ralph-research
2. Add "Signs Directory Superseded" as context to init-ralph-research
3. Mark "v1 Spec Structure" section as outdated in source file

Options: [Apply all] [Select specific] [Skip - just save report]
```

**If user approves**:

For **skill migrations**:
1. Read target skill file
2. Add pattern content to appropriate section
3. If template: add to skill's reference files
4. If context: add to skill's instructions or preamble

For **guideline migrations**:
1. Read target guideline file
2. Add pattern as new section (or merge with existing)

For **outdated deletions**:
1. With user approval, delete the outdated section from the source file
2. User can review the deletion in the PR before merging

For **standalone reference** (keep as learning):
- No action needed, pattern stays in place

### 8. Report results

```
## Curation Complete

**File curated**: docs/claude-learnings/ralph-loop-usage.md

**Actions taken**:
- Added 2 patterns to init-ralph-research skill
- Deleted 1 outdated section
- Kept 4 patterns as standalone learnings

**Skills flagged for review**: 1
- `git-split-pr`: No usage found in learnings, may be underutilized
```

## Example Session

```
User: /curate-learnings docs/claude-learnings/ralph-loop-usage.md

Claude: Analyzing ralph-loop-usage.md...

Found 12 discrete patterns. Cross-referencing with 18 skills and 4 guidelines...

## Curation Summary: ralph-loop-usage.md

### Patterns Analyzed: 12

| # | Pattern | Classification | Confidence | Target |
|---|---------|----------------|------------|--------|
| 1 | Comparing Duplicate Outputs | Context for skill | High | init-ralph-research |
| 2 | Comparison Table Template | Template for skill | High | init-ralph-research |
| 3 | Assumptions Document Structure | Template for skill | High | init-ralph-research |
| 4 | Preventing Early Loop Termination | Context for skill | High | init-ralph-research |
| 5 | Deep Research Artifact Sync | Context for skill | Medium | init-ralph-research |
| 6 | info.md as Tracker | Context for skill | Medium | init-ralph-research |
| 7 | Consolidating Duplicates | Standalone reference | Medium | Keep |
| 8 | Deep Research: Files vs Consolidation | Context for skill | Medium | init-ralph-research |
| 9 | v2 Spec Enhancements | Context for skill | High | init-ralph-research |

### Recommended Actions

**Migrate to init-ralph-research:**
- 2 templates (Comparison Table, Assumptions Structure)
- 6 context sections

**Keep as learning:**
- "Consolidating Duplicates" - situational reference

Apply these changes?
[Apply all] [Select specific] [Skip]

User: Apply all

Claude: Applying changes...

- Updated .claude/commands/init-ralph-research/SKILL.md with context sections
- Created .claude/commands/init-ralph-research/comparison-table-template.md
- Created .claude/commands/init-ralph-research/assumptions-template.md

Curation complete.
```

## Important Notes

- **User approval required**: Always use `AskUserQuestion` before applying changes
- **Deletion with approval**: Outdated content can be deleted if user approves (they can review in PR)
- **Preserve context**: When migrating, ensure the pattern retains enough context to be useful standalone
- **Update cross-references**: If a pattern is migrated, update any internal links in the source file
- **Frequency**: Designed for daily/frequent use to prevent learning bloat
- **Complements compound-learnings**: This curates existing content; `compound-learnings` creates new content
