# Low-Confidence Items

Items classified as LOW during autonomous consolidation. These need human judgment via `/learnings:curate`.

**How to use**: Run `/learnings:curate <file>` on specific files listed below to review and decide on these items interactively.

<!-- Each LOW item follows this format:

## [L-N] Title

- **Iter**: Iteration number when found
- **Content Type**: LEARNINGS | SKILLS | GUIDELINES
- **File**: Source file path
- **Pattern**: Section/pattern name
- **Possible classifications**: What it could be (with rationale for each)
- **Why LOW**: Why autonomous judgment wasn't sufficient
- **Curate command**: `/learnings:curate <file>`

-->

## [L-1] quarkus-kotlin.md is thin (8 lines, single gotcha)

- **Iter**: 1
- **Content Type**: LEARNINGS
- **File**: `.claude/learnings/quarkus-kotlin.md`
- **Pattern**: Entire file — single gotcha about enum changes requiring clean build
- **Possible classifications**: Standalone reference (if Quarkus still in use) or Outdated (if not)
- **Why LOW**: Don't know if user still works with Quarkus/Kotlin — can't judge relevance
- **Curate command**: `/learnings:curate quarkus-kotlin.md`

## [L-2] python-specific.md is niche standalone

- **Iter**: 1
- **Content Type**: LEARNINGS
- **File**: `.claude/learnings/python-specific.md`
- **Pattern**: Pydantic v2, TypedDict, env var patterns — 77 lines, well-structured but no persona references
- **Possible classifications**: Standalone reference (keyword-triggered, fine as-is) or candidate for Python persona (if user does enough Python work)
- **Why LOW**: No Python persona exists; file works via keyword matching but orphaned from persona system
- **Curate command**: `/learnings:curate python-specific.md`
