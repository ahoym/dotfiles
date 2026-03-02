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

## [L-1] code-quality-instincts.md is thin (16 lines)

- **Iter**: 1
- **Content Type**: LEARNINGS
- **File**: `~/.claude/learnings/code-quality-instincts.md`
- **Pattern**: 3 principles (no duplication, single source of truth, port intent not idioms)
- **Possible classifications**:
  - Keep standalone — it's a shared reference wired into personas via `Enforce learnings/code-quality-instincts.md`
  - Fold into a persona — but multiple personas reference it, so standalone is correct
- **Why LOW**: File is thin (16 lines) which normally triggers fold consideration, but it serves as a shared cross-persona reference point. The content is correct and actively wired. Not enough signal to justify action — leave for human review.
- **Curate command**: `/learnings:curate code-quality-instincts.md`