# Guideline Authoring Patterns

## Merging overlapping guidelines

When two guidelines cover similar territory, merge them into a single section rather than keeping both.

**Pattern**: Make the general principle the heading, and fold the specific case in as an example or opening sentence.

**Example from session**: "Ask when uncertain" (don't guess values) and "Express uncertainty explicitly" (be transparent about confidence) both dealt with uncertainty. Merged into "Be honest about what you know and don't know" — the specific case (don't guess values) became the opening sentence, and the general principle (be transparent about confidence) became the broader framing.

**Why this works**: Fewer guidelines are easier to internalize. When two sections overlap, readers (and AI) have to reconcile them. A single section with a clear principle + concrete examples is both shorter and more actionable.

**When to apply**: During guideline curation (`/learnings:curate`), look for sections that address the same underlying behavior from different angles. If one is a specific instance of the other, merge them.

## Hard Gates Need Tool-Call Triggers

Enforcement gates for agent self-discipline are only "hard" when tied to discrete tool calls (`EnterPlanMode`, `Task`, `Write`, `Skill`). Gates tied to judgment calls ("is this my first substantive response?", "did a keyword appear?") are soft layers dressed as hard rules — they compete with the primary task and lose.

When designing enforcement for agent behavior, ask: "What tool call triggers this check?" If there's no tool call, it's a soft layer regardless of how mandatory the language sounds. Soft layers are still valuable (they fire sometimes), but don't count on them for critical checks.

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

When extracting universal guidelines (see `claude-authoring-content-types.md` → "Universal vs Language-Specific" for the tier taxonomy), use pseudocode examples rather than language-specific ones. Pseudocode makes the universal tier portable across projects — language-specific examples anchor it to one stack.

## Inline Format Examples Over Fenced Code Blocks

When a guideline specifies announcement formats (emoji prefixes, status messages, structured output), use inline `·`-separated examples instead of fenced code blocks. Each code block costs 3+ lines (fence + content + fence) for a single format string; inline examples express the same specification in one line.

**Before** (20 lines for 3 formats): three separate fenced blocks with headers.
**After** (2 lines): `Formats: 📚 Session start — loaded X (reason) · 📚 "keyword" → loaded X · 📚 Searched for "X" — no matches`

Saves ~70% of lines in format-heavy guideline sections. The agent parses inline examples just as reliably as code blocks — the format is the content, not the fencing.

## See also

- `~/.claude/learnings/claude-authoring-content-types.md` — hub routing table, tier taxonomy, guideline scoping and evaluation criteria
- `~/.claude/learnings/claude-authoring-skills.md` — sibling authoring guide for skills (cross-refs back here)
- `~/.claude/commands/learnings/curate/curation-insights.md` — operational calibration including "uniform convention" pattern (migrated from here)
