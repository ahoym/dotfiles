# Persona Design Guidelines

## Philosophy

Personas provide a **lens** — priorities, tradeoffs, review instincts, and decision-making posture for a domain. They are NOT the primary store of domain knowledge. Factual knowledge (gotchas, platform specifics, patterns) lives in `~/.claude/learnings/` files organized by topic, where it can be dynamically pulled into any session via the context-aware-learnings guideline — regardless of whether a persona is active.

Personas layer on top of learnings. The persona sets the *focus*; learnings provide the *facts*.

## Structure

Every persona uses 4 sections:

| Section | Purpose | Content type |
|---------|---------|--------------|
| **Domain priorities** | What this persona cares about | Focus areas, ~6-10 items |
| **When reviewing or writing code** | Actionable checks before shipping | Specific patterns to flag, ~10-15 items |
| **When making tradeoffs** | Decision-making principles | Philosophy and priorities, ~6-8 items |
| **Known gotchas & platform specifics** | Key facts that shape the lens | Subsections per platform/tool, ~15-20 lines |

The first three sections encode *judgment* (the lens). The fourth provides *context for that judgment* — not an exhaustive knowledge dump. Detailed gotchas, patterns, and reference material belong in `~/.claude/learnings/` files, where they're available to all sessions regardless of persona. The persona's gotchas section should contain only facts that directly inform the review heuristics and tradeoff principles above.

## Sizing

- Seed personas (no accumulated learnings): ~20 lines
- Mature personas (with battle-tested knowledge): ~60-80 lines
- Upper bound: should fit in one screen read (~100 lines max)

## Naming Convention

Use `<domain>-<stack>-<scope>` format:
- `java-backend` — Java, backend scope
- `java-devops` — Java, DevOps/infrastructure scope
- `xrpl-typescript-fullstack` — XRPL domain, TypeScript stack, fullstack scope

This avoids ambiguity when multiple stacks touch the same domain.

## Learnings-to-Persona Pipeline

When creating a new persona, mine `~/.claude/learnings/` for the *lens* — not to duplicate knowledge:

1. Glob `~/.claude/learnings/` for files relevant to the persona's domain and stack
2. Read each file and extract *judgment patterns*: tradeoff principles, review heuristics, decision priorities
3. Distill into the persona's lens sections (priorities, code review, tradeoffs). Factual gotchas stay in learnings files — include only the subset that directly informs the lens
4. Cross-reference the project's MEMORY.md for additional session-specific insights

The persona references the domain's knowledge; it doesn't absorb it. Learnings files are the source of truth for facts, dynamically pulled via the context-aware-learnings guideline.

## Persona Suggestion Criteria

During curation, suggest creating a new persona when:

1. **Cluster detected**: 3+ learnings files contain patterns for the same domain/stack combination
2. **No persona exists**: No matching file in `~/.claude/commands/set-persona/` or `.claude/personas/`
3. **Sufficient depth**: At least 8-10 discrete gotchas/patterns across the clustered files — enough to meaningfully fill all 4 sections

Do NOT suggest a persona for:
- A single learning file with a few patterns (too thin)
- A domain already covered by an existing persona (suggest enhancing instead)
- Meta/tooling topics (skill design, git patterns) — these are workflow knowledge, not domain expertise

## Persona Inheritance / Extraction

When a persona mixes generic and domain-specific content, extract the generic layer into a parent persona and slim the child to domain-specific concerns only:

1. **Identify generic content**: tradeoff principles, CI/CD patterns, deployment strategies, and gotchas not tied to a specific language or framework
2. **Create the parent**: move generic content into a new standalone persona following the same 4-section structure
3. **Enrich the parent**: pull in related learnings from `~/.claude/learnings/` that fit the generic domain
4. **Slim the child**: add `## Extends: <parent>`, remove migrated content, keep only domain-specific sections. Remove entire sections if fully inherited
5. **Verify both paths**: test activating the parent standalone and the child with inheritance

**Example**: `java-devops` extends `platform-engineer` — generic CI/CD, deployment, and observability patterns live in the parent; Java-specific JVM tuning and Spring Boot operational patterns stay in the child.

**Heuristic for tool categorization:** Categorize tools by their actual scope, not where you first learned them. Example: `dependency-review-action` is language-agnostic (GitHub scans any ecosystem) but `pnpm audit` is TypeScript-specific — they belong in different personas even though you encountered both while setting up the same CI pipeline.

## Tiering: Core vs Deep-Reference

When a persona file accumulates enough domain-specific gotchas that signal density degrades, split into two tiers:

- **Core (always-loaded):** High-frequency patterns checked on every review — flag usage, casing conventions, trust line prerequisites, arithmetic rules. These belong in the persona file itself.
- **Deep-reference (conditional):** Operation-specific knowledge relevant only during certain tasks. Reference via `@` pointer to a learnings file; the agent loads it when the task context matches.

**Cut line:** "Check every time I see domain code" → core. "Reference when building feature X" → deep-reference.

**Trigger:** Signal density, not raw line count. If a reviewer would skim past most entries because they're irrelevant to the current task, the file has crossed the threshold.

## Maintenance

- Fold new learnings into matching personas during curation when they fit a persona's domain
- The persona is the distilled, actionable version; `~/.claude/learnings/` files stay as raw research
- Periodically review during curation to prune outdated gotchas (e.g., after a major version upgrade)
