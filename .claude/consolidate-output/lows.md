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

## [L-1] Orphaned skill-reference: subagent-patterns.md

- **Iter**: 2
- **Content Type**: SKILLS
- **File**: `skill-references/subagent-patterns.md`
- **Pattern**: Entire file (3 subagent patterns: verify output, intermediate files, structured templates)
- **Possible classifications**:
  - **Keep as-is**: Generic patterns that don't need explicit wiring — skills already implement them inline
  - **Wire into skills**: Add as conditional reference in explore-repo, parallel-plan:execute, do-security-audit
  - **Move to learnings**: Content is more reference-knowledge than skill-infrastructure
- **Why LOW**: Patterns are already implemented in the skills that launch subagents; wiring adds marginal value. File is only referenced by `learnings/multi-agent-patterns.md` and `README.md`, not by any SKILL.md.
- **Curate command**: `/learnings:curate skill-references/subagent-patterns.md`
