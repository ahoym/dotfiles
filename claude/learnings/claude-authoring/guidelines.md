Craft patterns for writing, merging, scoping, and compressing guidelines including enforcement gate design, eager vs lazy loading, and pseudocode conventions.
- **Keywords:** guideline merge, enforcement gate, tool-call trigger, eager load, lazy load, pseudocode, condensing, soft gate, hard gate, unreferenced guideline, redundant guideline
- **Related:** none

---

## Merging overlapping guidelines

When two guidelines cover similar territory, merge them into a single section rather than keeping both.

**Pattern**: Make the general principle the heading, and fold the specific case in as an example or opening sentence.

**Example from session**: "Ask when uncertain" (don't guess values) and "Express uncertainty explicitly" (be transparent about confidence) both dealt with uncertainty. Merged into "Be honest about what you know and don't know" — the specific case (don't guess values) became the opening sentence, and the general principle (be transparent about confidence) became the broader framing.

**Why this works**: Fewer guidelines are easier to internalize. When two sections overlap, readers (and AI) have to reconcile them. A single section with a clear principle + concrete examples is both shorter and more actionable.

**When to apply**: During guideline curation (`/learnings:curate`), look for sections that address the same underlying behavior from different angles. If one is a specific instance of the other, merge them.

## Hard Gates Need Tool-Call Triggers

Enforcement gates for agent self-discipline are only "hard" when tied to discrete tool calls (`EnterPlanMode`, `Task`, `Write`, `Skill`). Gates tied to judgment calls ("is this my first substantive response?", "did a keyword appear?") are soft layers dressed as hard rules — they compete with the primary task and lose.

When designing enforcement for agent behavior, ask: "What tool call triggers this check?" If there's no tool call, it's a soft layer regardless of how mandatory the language sounds. Soft layers are still valuable (they fire sometimes), but don't count on them for critical checks.

**Upgrading soft layers:** Passive triggers ("when keyword X appears") can be strengthened by anchoring them to actions the agent is already performing. "Before responding to a user message that introduces domain X" anchors to message processing. "Before first Edit in domain X" anchors to the Edit action. Both outperform "whenever X appears" because the agent is already at the decision point — the check piggybacks rather than competing for attention.

## Unreferenced Guidelines Are Dead Weight

A guideline not `@`-referenced from CLAUDE.md and not referenced by any skill or persona has no delivery mechanism. The content may be valid but it never loads — making it invisible to the agent.

**During curation**: Grep the corpus for the guideline filename. If nothing references it, the content needs to either earn an `@`-reference (if universal) or move to the correct content type (learning for reference info, persona gotcha for domain-specific patterns).

**Common pattern**: Domain-specific debugging heuristics and operational procedures get created as guidelines because they contain prescriptive language ("do X before Y"). But prescriptive ≠ behavioral. The test: does it change behavior universally, or provide knowledge conditionally? If conditional → learning or persona, not guideline.

## Don't Create Guidelines That Restate Skill Defaults

A guideline is redundant when skills already handle the behavior as part of their instructions. It's counterproductive when it overrides explicit user intent.

**Test:** For any proposed guideline, ask: "Does a skill already route this correctly by default?" If yes, the guideline adds no value for the default case and risks overriding the user when they intentionally deviate.

**Example:** A "store learnings in `~/.claude/`, not repo branches" guideline was redundant because `learnings:compound` already writes to `~/.claude/learnings/` by default. Worse, it intercepted explicit requests like "save these learnings to the repo" — overriding the user's stated intent to put project-specific content in the project.

**Rule:** Guidelines should shape ambiguous situations, not override explicit instructions. If a skill handles the default and the user explicitly asks for something different, honor the user.

## Pseudocode at the Universal Tier

When extracting universal guidelines (see `routing-table.md` → "Universal vs Language-Specific" for the tier taxonomy), use pseudocode examples rather than language-specific ones. Pseudocode makes the universal tier portable across projects — language-specific examples anchor it to one stack.

## Inline Format Examples Over Fenced Code Blocks

When a guideline specifies announcement formats (emoji prefixes, status messages, structured output), use inline `·`-separated examples instead of fenced code blocks. Each code block costs 3+ lines (fence + content + fence) for a single format string; inline examples express the same specification in one line.

**Before** (20 lines for 3 formats): three separate fenced blocks with headers.
**After** (2 lines): `Formats: 📚 Session start — loaded X (reason) · 📚 "keyword" → loaded X · 📚 Searched for "X" — no matches`

Saves ~70% of lines in format-heavy guideline sections. The agent parses inline examples just as reliably as code blocks — the format is the content, not the fencing.

## Condensing Guidelines for Agent Consumption

When a guideline file grows unwieldy, apply these compression patterns:

- **Define constants once.** Repeated values (directory paths, tool names, format strings) should be declared once and referenced. Each repetition wastes load-time tokens and creates drift risk.
- **Tables over prose for rule sets.** When multiple rules share the same structure (trigger → action → scope), a table scans faster than numbered paragraphs. Agents parse structured formats more reliably.
- **Cut "why" justifications.** Agents need rules, not motivation. "Plans lock in decisions that are expensive to reverse" doesn't change behavior — the rule "search before `EnterPlanMode`" does. Reserve "why" for cases where it changes how edge cases are handled.
- **Merge scattered related sections.** If the same concept appears in 3 places (definition, notes, additions), consolidate. Split info forces the agent to reconstruct the full picture.

**When framing affects compliance**: word choice matters. "Soft gates (proactive)" reads as optional/best-effort. "Gates (mandatory when triggered)" reads as required. If a label undermines the rule's authority, change the label.

## Eager vs Lazy Loading Decision Framework

Guidelines split into two categories for loading strategy:

- **Behavioral** (shapes every response): confidence calibration, pushback norms, autonomy boundaries, communication style → eager-load via `@`
- **Procedural** (steps for specific actions): path resolution, skill chaining rules, format specs → lazy-load via trigger table

**Test**: "If I miss this on the first message, will the interaction feel wrong?" Yes → eager. No → lazy-load with a trigger.

**Trigger table format** in CLAUDE.md:
```markdown
| File | When to read |
|------|-------------|
| guidelines/path-resolution.md | When resolving relative paths in SKILL.md files |
```

**Edge case**: A file mixing both types (e.g., skill-invocation.md with a behavioral rule + procedural details) → inline the behavioral rule (~2-3 lines) in CLAUDE.md, lazy-load the rest.

**Context-aware-learnings is behavioral, not procedural.** The session-start gate fires before the first tool call, making the entire file load-bearing from moment zero. Gates that fire reactively (keyword, domain-shift) also need the format/observability spec available at all times.

## Cross-Refs

- `~/.claude/commands/learnings/curate/curation-insights.md` — operational calibration including "uniform convention" pattern (migrated from here)
