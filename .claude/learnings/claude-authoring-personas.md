# Persona Authoring Patterns

## Judgment Layer, Not Recipe Catalog

A persona's value comes from changing how you *think* about a domain — priorities, tradeoffs, review instincts. Recipe-heavy content (step-by-step patterns, code templates) belongs in learning files, not personas. When creating a persona from a cluster of learnings:

1. Seed with judgment-grade content only (architectural principles, review checks, tradeoff heuristics, gotchas that change decision-making)
2. Reference learning files conditionally (via "Detailed references" section) for recipes and code patterns
3. Start thin — the enrichment loop grows the persona as more judgment-style insights emerge from real work
4. A persona that's 90% recipes and thin on judgment doesn't justify the always-on context cost

The test: "Would activating this persona before a task actually change what I do?" If the answer is just "load a gotcha list," it's not ready to be a persona yet.

## Reviewer Personas vs Working-in-Repo Personas

A "working in this repo" persona encodes things the user already knows — low value. A reviewer persona encodes the design philosophy and quality bar so a *reviewer agent* can evaluate changes against the user's standards without them being spelled out each time. The test: "does this persona give knowledge to someone who doesn't already have it?" Reviewer personas pass because the reviewer (the agent) is the one who needs the domain context, not the author.

## Tools Must Encode the Philosophy They Curate

When a philosophy is established in learnings (e.g., "lean personas as judgment layers, rich learnings as knowledge") but the tools that maintain the corpus don't enforce it, the philosophy erodes.

**Check**: when updating a curation tool's methodology, cross-reference the principles in the learnings it curates. The tool's actions should reinforce the established philosophy, not contradict it.

## Compose Personas from Shared Learnings

Personas should reference shared learning files for cross-cutting instincts rather than inlining everything. Language-agnostic practices (no duplication, single source of truth, port intent not idioms) go in a shared learning file; language-specific patterns (no IIFEs, no `as` casts) stay inline in the persona. Multiple personas can reference the same learning file without duplication.

Pattern:
```markdown
## Code style
Enforce `learnings/code-quality-instincts.md` (generic instincts).

Language-specific:
- Avoid IIFEs — extract named helpers
- Avoid `as` casts — fix the source type
```

This keeps persona files focused on domain judgment while inheriting shared quality instincts.

## Gotchas Are Proactive Knowledge, Not Reactive Reference

Gotchas and learnings are both knowledge, but they differ in **delivery timing**. A learning can wait until you're in the weeds ("how do I wire a rate limiter?"). A gotcha must be present *before you start* — it prevents mistakes the agent wouldn't think to check for.

**The test:** "Would the agent make this specific mistake without this in-context?" If yes → proactive gotcha. If it's reference knowledge needed only when you're already working in that area → reactive learning.

This distinction matters because reactive-only loading has a failure mode: the agent has to *know it needs the gotcha* to load the file. But the whole point of a gotcha is catching things you wouldn't think to check.

## `*-gotchas.md` Companion File Convention

Proactive gotchas live in dedicated `learnings/*-gotchas.md` files — small (10-30 lines) one-liner tripwires. They're **companions** to `*-patterns.md` files when one exists (e.g., `xrpl-patterns-gotchas.md` alongside `xrpl-patterns.md`), **standalone** when no patterns file exists (e.g., `java-infosec-gotchas.md`).

Personas reference gotcha files via a `## Proactive loads` section — loaded deterministically at persona activation. This is distinct from `## Detailed references` which are reactive/on-demand.

```markdown
## Proactive loads
- `learnings/xrpl-gotchas.md`
- `learnings/react-frontend-gotchas.md`

## Detailed references
- `learnings/xrpl-patterns.md` — full recipes, API details
```

**Why separate files, not sections within patterns files:** The `Read` tool is all-or-nothing — no section-level extraction. Loading `xrpl-patterns.md` (200+ lines) to get 15 lines of gotchas wastes context. Small dedicated files keep proactive loading cheap.

**Every persona's gotchas get a file, even with a single consumer.** Uniform convention over case-by-case optimization — predictability of the pattern matters more than minimizing file count.

## Extends Inherits Detailed References

Child personas that declare `## Extends: <parent>` inherit the parent's Detailed references — the set-persona skill loads the parent first, then layers the child. Don't duplicate parent refs in the child; only add refs unique to the child's narrower domain.

## Proactive Loads Require Agent Behavior, Not @ References

Persona `## Proactive loads` sections cannot use `@` references because persona files are data files read via the Read tool at runtime — `@` only resolves in CLAUDE.md and SKILL.md at the CLI level. The set-persona skill's Step 5 explicitly reads each proactive load file, making it agent-dependent but the only viable mechanism. The keyword-based learnings search (`context-aware-learnings.md`) is the fallback for sessions without an active persona.

## Cross-Persona Duplication: Extract to Shared Dependency

When two peer personas share duplicated content (e.g., both have React/Next.js gotchas), **extract to a shared learning file and reference from both** rather than choosing which persona "owns" the content. Ownership-based resolution ("the more specialized persona owns the gotcha") breaks down when neither persona is clearly more specialized for the shared domain — react-frontend is more specialized for React, xrpl-typescript-fullstack is more specialized for XRPL, but both legitimately need the React patterns.

Extracting to a shared learning eliminates the ownership question and follows the lean-persona philosophy: personas reference knowledge, they don't inline it. Both personas get a Detailed references entry pointing to the same learning file.
