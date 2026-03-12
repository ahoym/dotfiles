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

## [L-3] "Three-Branch Gate Announcements" misplaced in multi-agent-patterns.md

- **Iter**: 19
- **Content Type**: LEARNINGS (DEEP_DIVE)
- **File**: `.claude/learnings/multi-agent-patterns.md`
- **Pattern**: Section "Three-Branch Gate Announcements" (L104-107) — about context-aware-learnings gate observability, not multi-agent orchestration
- **Possible classifications**: Move to skill-design.md (gate/observability design pattern), move to ralph-loop.md (consolidation loop context where it was discovered), or keep in place (the "gate" concept applies to any agent orchestration)
- **Why LOW**: Section is only 4 lines — moving adds churn for marginal benefit. The concept is borderline between multi-agent orchestration and system-design observability. Human judgment on whether discoverability improves with relocation.
- **Curate command**: `/learnings:curate multi-agent-patterns.md`

## [L-4] TaskOutput contradiction between multi-agent-patterns.md and claude-code.md

- **Iter**: 19
- **Content Type**: LEARNINGS (DEEP_DIVE)
- **File**: `.claude/learnings/multi-agent-patterns.md` (L237-240) vs `.claude/learnings/claude-code.md` (L96-104)
- **Pattern**: multi-agent-patterns says "TaskOutput only works for background Bash tasks, not Agent tasks — returns 'No task found' errors." claude-code says "Use TaskOutput, Not Bash, to Check Background Agent Progress" for agents launched via Task with run_in_background.
- **Possible classifications**: multi-agent-patterns is correct (empirical observation), claude-code is correct (more recent/authoritative), or both are partially correct (behavior may depend on agent type or platform version)
- **Why LOW**: Direct factual contradiction between two learnings. Needs empirical testing to determine which claim is accurate. Cannot resolve autonomously without runtime verification.
- **Curate command**: `/learnings:curate multi-agent-patterns.md` and `/learnings:curate claude-code.md`
