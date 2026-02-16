# Classification Model

The 6-bucket model for classifying learning patterns during curation.

## Classification Buckets

| Classification | Description | Action |
|----------------|-------------|--------|
| **Skill candidate** | Actionable, repeatable workflow | Create new skill or enhance existing |
| **Template for skill** | Reusable structure/format that a skill would generate or reference | Add as reference file in skill directory |
| **Context for skill** | Explanatory material that helps execute a skill better | Add to skill's instructions or preamble |
| **Guideline candidate** | Code standard or behavioral practice | Migrate to `~/.claude/guidelines/` |
| **Standalone reference** | Useful knowledge with no skill/guideline connection | Keep as learning |
| **Outdated** | Superseded, stale, or deprecated | Mark for deletion |

## Decision Criteria

### Skill Candidate

A pattern is a **skill candidate** when:
- It describes a multi-step procedure with clear inputs/outputs
- It's invokable (user would say "do X" or "run the X process")
- It's repeatable (used weekly or more frequently)
- Steps are procedural, not heavily judgment-based

**Examples:**
- "How to rebase a PR onto main" → Skill candidate
- "Process for reviewing duplicate directories" → Skill candidate

### Template for Skill

A pattern is a **template for skill** when:
- It's a reusable structure/format (markdown table, document outline, checklist)
- A skill would copy or generate this structure
- It's 10+ lines of structured content
- Users don't invoke it directly; a skill uses it

**Examples:**
- "Comparison Table Template" → Template (skill generates this)
- "Assumptions Document Structure" → Template (skill creates this file)
- "PR Body Format" → Template (git-create-pr uses this)

### Context for Skill

A pattern is **context for skill** when:
- It explains "when" or "why" for skill decisions
- It provides decision criteria that inform skill execution
- It helps me make better choices during a skill's steps
- Users don't invoke it; it shapes how I execute a skill

**Examples:**
- "Signs One Directory is Superseded" → Context (helps comparison decisions)
- "When to Use v2 vs v1 Spec" → Context (helps init-ralph-research decisions)
- "Priority Definitions for Questions" → Context (helps assumptions doc creation)

### Guideline Candidate

A pattern is a **guideline candidate** when:
- It describes a behavioral rule or standard
- It applies broadly across many tasks (not skill-specific)
- It changes how I should approach work in general
- It's about "how to think" not "what to do"

**Examples:**
- "Variable Renaming: Check for Line Length" → Guideline (python-practices.md)
- "Never Commit Secrets" → Guideline (git-workflow.md)
- "Minimum 80% Test Coverage" → Guideline (project-specific.md)

### Standalone Reference

A pattern is **standalone reference** when:
- It's useful knowledge but not actionable as a procedure
- No existing skill relates to this topic
- It's situational or rarely needed
- It's explanatory without being behavioral

**Before recommending "keep"**, check: is this pattern in its most reusable form? If it contains project-specific details (hardcoded routes, app-specific examples, repo-specific paths), genericize them. "Keep as-is" is only correct when the content is already portable.

**Examples:**
- "History of Feature X" → Reference only
- "Comparison of Library A vs B" → Reference only
- "Edge Cases in External API" → Reference only (unless a skill handles that API)

### Outdated

A pattern is **outdated** when ANY of these apply:

| Criterion | How to Verify |
|-----------|---------------|
| **Superseded by newer learning** | Same topic exists in more recent file/section with updated content |
| **References non-existent code** | File paths, classes, or functions no longer exist in codebase |
| **Contradicts current skill/guideline** | A skill or guideline now recommends a different approach |
| **Migrated completely** | Content was fully incorporated into a skill or guideline |
| **References deprecated tooling** | Mentions tools/libraries no longer used (e.g., pipenv → uv) |

**NOT outdated (false positives):**
- Old timestamp alone (age doesn't invalidate patterns)
- References old file paths but pattern is sound (update paths, keep pattern)
- Partially migrated (only the migrated portions are outdated)
- Niche/rarely used (low usage ≠ outdated)

## Migration Litmus Test

Before classifying any pattern as a migration candidate (skill, template, context, or guideline), ask: **"Would having this in the target file actually change how I execute?"** If the answer is no, the pattern isn't worth migrating regardless of which bucket it technically fits. Basic tool knowledge, self-evident behavior, and obvious facts fail this test — they add bulk without changing decisions.

## Confidence Levels

| Level | Meaning | Action |
|-------|---------|--------|
| **High** | Classification is clear, criteria strongly match | Apply without additional verification |
| **Medium** | Likely correct but some ambiguity | Note rationale, offer discussion before asking for commit/skip |
| **Low** | Uncertain, multiple classifications could fit | Ask user to decide |

## Cross-Reference Matching

When checking existing skills/guidelines:

| Match Type | Meaning | Implication |
|------------|---------|-------------|
| **Exact match** | Pattern is fully covered elsewhere | Mark as outdated (migrated) |
| **Partial match** | Related content exists but incomplete | Candidate to enhance existing |
| **Thematic match** | Same topic, different angle | May complement rather than duplicate |
| **No match** | No existing coverage | New skill/guideline candidate if actionable |

## Skill Pruning Criteria

When reviewing existing skills (step 5 of curate-learnings), evaluate whether skills should be pruned based on these criteria:

### Strong Prune Candidates

| Criterion | Example |
|-----------|---------|
| **Thin wrapper around simple command** | A skill that just runs `gh pr view` with formatting |
| **Very specialized use case** | Only applies to rare scenarios (stacked PRs, compound branches) |
| **Significant overlap with another skill** | Two skills that do 80%+ the same thing |
| **Low expected usage frequency** | Would be used less than monthly |

### Consider Pruning

| Criterion | Example |
|-----------|---------|
| **Can be done manually with similar effort** | 2-3 commands that are easy to remember |
| **Requires complex setup for rare benefit** | Background polling for occasional comments |
| **Outdated workflow** | Based on patterns no longer used in the project |

### Keep Despite Low Usage

| Criterion | Example |
|-----------|---------|
| **High value when needed** | Conflict resolution saves significant time |
| **Hard to remember steps** | Complex git operations with specific flags |
| **Error-prone without guidance** | Operations where mistakes are costly |

### Pruning Process

1. List all skills with brief description
2. Rate each: High (core workflow), Medium (useful), Low (specialized/rare)
3. For Low-rated skills, check if any "Keep Despite Low Usage" criteria apply
4. Propose pruning for remaining Low-rated skills
5. Get user confirmation before removing

**Note:** Pruning skills is about maintenance, not failure. A skill that served its purpose and is no longer needed was still valuable.

## Examples by Classification

### From ralph-loop-usage.md

| Pattern | Classification | Rationale |
|---------|----------------|-----------|
| "Comparison Table Template" | Template for skill | Structured format that init-ralph-research could generate |
| "Signs Directory Superseded" | Context for skill | Decision criteria that helps comparison process |
| "v2 Spec Structure" | Template for skill | Document structure for spec file generation |
| "When to Use v2 vs v1" | Context for skill | Decision logic for init-ralph-research |
| "Consolidating Duplicates" | Standalone reference | Situational procedure, no matching skill |
| "v1 Spec Structure" | Outdated | Superseded by v2 in same file |

### From a hypothetical python-patterns.md

| Pattern | Classification | Rationale |
|---------|----------------|-----------|
| "Factory Function Pattern" | Standalone reference | Design pattern knowledge, not a procedure |
| "Always Use Type Hints" | Guideline candidate | Behavioral standard for all Python code |
| "How to Add a New Model" | Skill candidate | Multi-step procedure with clear steps |
| "Old Linting Setup" | Outdated | We now use ruff, not flake8 |
