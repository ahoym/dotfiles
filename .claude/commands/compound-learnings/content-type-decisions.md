# Content Type Decisions

How to decide whether content should be a skill, guideline, or learning.

## Skill vs Guideline vs Learning

| Type | Purpose | Location | When to use |
|------|---------|----------|-------------|
| **Skill** | Actionable, repeatable task | `.claude/commands/` | Multi-step procedures invoked via `/skill-name` |
| **Guideline** | Rules that shape behavior | `.claude/guidelines/` | Practices loaded via CLAUDE.md that affect how work is done |
| **Learning** | Reference knowledge | `docs/claude-learnings/` | Patterns, examples, or info useful for context but not behavioral |

### Quick Decision Tree

1. Can it be invoked as a command with clear steps? → **Skill**
2. Does it change how I should behave or approach tasks? → **Guideline**
3. Is it useful reference info (patterns, examples, gotchas)? → **Learning**

## Universal vs Language-Specific

Separate language-agnostic principles from language/tool-specific implementations.

**The test:** Ask "Does this apply regardless of language?" If yes, document it as a universal principle with pseudocode examples.

**Examples:**
- **Universal:** Helper Class Extraction, Factory Functions, Single Responsibility Principle
- **Language-specific:** Python docstring style, JavaScript async/await patterns

## Skill vs Guideline (Detailed)

| Create a Skill when... | Keep as Guideline when... |
|------------------------|---------------------------|
| Actionable with clear inputs/outputs | Conceptual guidance or best practices |
| Used repeatedly (weekly or more) | Requires significant judgment |
| Multiple steps benefit from automation | Rarely used or highly situational |
| Steps are procedural, not judgment-based | About "how to think" not "what to do" |

## Maintaining Guidelines and Skills

### Converting Guidelines to Skills

A guideline is a candidate for skill conversion when it describes an actionable, repeatable process with clear inputs.

**Process:**
1. Create skill folder: `.claude/commands/<skill-name>/`
2. Move detailed patterns to a reference file in the skill folder
3. Replace guideline content with: "Use `/<skill-name>` to..."
4. Keep the guideline header for discoverability

### Guideline Scoping: Always-On vs Conditional

A guideline not `@`-imported in CLAUDE.md is only found via search — functionally identical to a learning file. If a guideline is useful but not needed every session, scope it as a **conditional reference** for the specific skill that benefits instead of leaving it unwired.

| Scope | Mechanism | When to use |
|-------|-----------|-------------|
| **Always-on** | `@` import in CLAUDE.md | Behavioral rules that apply to every interaction |
| **Conditional** | Reference file in a skill directory | Context needed only when that skill runs |
| **Search-only** | Standalone file in `guidelines/` or `learnings/` | Rarely needed, fine to discover ad-hoc |

Prefer conditional scoping over always-on when the content is only relevant during a specific workflow.

### Evaluating Existing Guidelines

Periodically review guidelines for continued utility:

| Sign of Low Utility | Action |
|---------------------|--------|
| Documents a past bug fix | Move to code comment at the fix location |
| Describes an existing utility function | Remove; discoverable via code search |
| The "wrong" pattern only exists in the guideline | The bug is fixed; remove the guideline |

## Related References

- skill-template.md - Template and file organization for skills
- writing-best-practices.md - Conventions for writing effective skills
