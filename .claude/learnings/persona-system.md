# Persona System Learnings

## Persona Extends Pattern

**Utility: High**

Child personas can inherit from a parent via an `## Extends: <name>` heading placed immediately after the H1 title. The `set-persona` skill resolves the parent using the same lookup order (project-local `.claude/personas/` → dotfiles `~/.claude/commands/set-persona/`), loads the parent first as foundational context, then layers the child on top.

Key design decisions:
- Child sections **supplement** the parent — they don't replace them
- Only **single-level** extension is supported (no chaining) to keep resolution simple
- Activation confirmation mentions both: "Activated **child** (extends **parent**)"
- The parent is a standalone persona that can be activated directly too

Example: `java-devops` extends `platform-engineer` — Java-specific JVM/Micrometer concerns layer on top of generic CI/CD, deployment, and infrastructure knowledge.

## Persona Extraction Strategy

**Utility: Medium**

When a persona mixes generic and domain-specific content, extract the generic layer into a parent persona and slim the child to domain-specific concerns only. Decision process:

1. **Identify generic content**: tradeoff principles, CI/CD patterns, deployment strategies, and gotchas that aren't tied to a specific language or framework
2. **Create the parent**: move generic content into a new standalone persona following the same 4-section structure (Domain priorities, When reviewing, When making tradeoffs, Known gotchas)
3. **Enrich the parent**: pull in related learnings from `~/.claude/learnings/` that fit the generic domain (e.g., CI/CD learnings → platform-engineer gotchas)
4. **Slim the child**: add `## Extends: <parent>`, remove migrated content, keep only domain-specific sections. Remove entire sections (like "When making tradeoffs") if fully inherited
5. **Verify both paths**: test activating the parent standalone and the child with inheritance
