# Persona Design Guidelines

## Philosophy

Personas are **living expert documents** that accumulate domain knowledge over time — not lightweight seed templates. They should encode the institutional knowledge a senior engineer in that domain would carry: gotchas, tradeoffs, review instincts, and platform-specific facts.

## Structure

Every persona uses 4 sections:

| Section | Purpose | Content type |
|---------|---------|--------------|
| **Domain priorities** | What this persona cares about | Focus areas, ~6-10 items |
| **When reviewing or writing code** | Actionable checks before shipping | Specific patterns to flag, ~10-15 items |
| **When making tradeoffs** | Decision-making principles | Philosophy and priorities, ~6-8 items |
| **Known gotchas & platform specifics** | Hard-won facts by platform | Subsections per platform/tool, ~20-25 lines |

The first three sections encode *judgment*. The fourth encodes *facts*. Keeping them separate makes the file scannable: priorities up top for framing, gotchas at bottom as reference.

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

When creating a new persona, mine `~/.claude/learnings/` for battle-tested patterns:

1. Glob `~/.claude/learnings/` for files relevant to the persona's domain and stack
2. Read each file and extract gotchas, patterns, and principles
3. Distill into the 4-section structure — the persona is the *actionable summary*, learnings files remain as raw research notes
4. Cross-reference the project's MEMORY.md for additional session-specific gotchas not yet in learnings

This ensures personas start with real expertise rather than generic advice.

## Persona Suggestion Criteria

During curation, suggest creating a new persona when:

1. **Cluster detected**: 3+ learnings files contain patterns for the same domain/stack combination
2. **No persona exists**: No matching file in `~/.claude/commands/set-persona/` or `.claude/personas/`
3. **Sufficient depth**: At least 8-10 discrete gotchas/patterns across the clustered files — enough to meaningfully fill all 4 sections

Do NOT suggest a persona for:
- A single learning file with a few patterns (too thin)
- A domain already covered by an existing persona (suggest enhancing instead)
- Meta/tooling topics (skill design, git patterns) — these are workflow knowledge, not domain expertise

## Maintenance

- Fold new learnings into matching personas during curation when they fit a persona's domain
- The persona is the distilled, actionable version; `~/.claude/learnings/` files stay as raw research
- Periodically review during curation to prune outdated gotchas (e.g., after a major version upgrade)
