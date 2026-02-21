# Corpus Cross-Reference

Shared procedure for loading the target corpus and assessing content coverage. Used by curate-learnings, quantum-tunnel-claudes, and any skill that needs to evaluate content against existing knowledge.

## Loading the Corpus

Load these in a single parallel batch:

1. **Skills**: Glob `<TARGET>/.claude/commands/*/SKILL.md` and read all files
2. **Skill reference files**: Glob `<TARGET>/.claude/commands/*/*.md` (excluding SKILL.md) — these contain templates, patterns, and context that skills reference
3. **Guidelines**: Glob and read all `<TARGET>/.claude/guidelines/*.md`
4. **Learnings**: Glob and read all `<TARGET>/.claude/learnings/*.md`

Store all content for use in subsequent cross-referencing. This corpus represents the target's current knowledge base.

**Note:** `<TARGET>` is the repo root — for curate-learnings this is typically `~/.claude/`, for quantum-tunnel-claudes it's the current project root.

## Cross-Referencing Content

For each pattern/section being evaluated, search the loaded corpus for related content.

**This must be thorough — compare against the actual loaded content, not just keyword grep.** Shallow cross-referencing leads to wrong classifications (e.g., recommending "pull" when the content is already fully covered, or "migrate" when it's already in a skill).

### Procedure

For each incoming pattern:
1. Search the loaded skills for related content (check both SKILL.md instructions and reference files)
2. Check coverage depth — does the skill just mention this topic, or does it cover it thoroughly?
3. Search the loaded guidelines for related content
4. Search the loaded learnings for related content (to catch same-topic coverage in different files)

### Coverage Match Types

| Match Type | Meaning | Implication |
|------------|---------|-------------|
| **Exact match** | Pattern is fully covered elsewhere | Content is redundant — skip or mark as already migrated |
| **Partial match** | Related content exists but doesn't cover this specific angle | Candidate to enhance existing content |
| **Thematic match** | Same topic, different angle or detail level | May complement rather than duplicate — assess whether it adds value |
| **No match** | No existing coverage of this topic | Genuinely new content |

### Confidence Assessment

| Level | Meaning | Action |
|-------|---------|--------|
| **High** | Coverage assessment is clear — strong exact match or clearly no match | Act on assessment directly |
| **Medium** | Likely correct but some ambiguity — partial or thematic match | Note rationale, flag for user review |
| **Low** | Uncertain — multiple interpretations possible | Present to user with context for decision |
