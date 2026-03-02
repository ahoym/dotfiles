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

**Status**: RESOLVED (keep as-is — shared cross-persona reference, thin is correct for this role)

## [L-2] Cross-persona gotcha overlap: react-frontend ↔ xrpl-typescript-fullstack

- **Iter**: 2
- **Content Type**: SKILLS
- **File**: `~/.claude/commands/set-persona/react-frontend.md` and `~/.claude/commands/set-persona/xrpl-typescript-fullstack.md`
- **Pattern**: Both personas contain Next.js 16 and React 19 gotchas (async component patterns, `use()` hook, metadata API changes)
- **Possible classifications**:
  - Keep as-is — each persona contextualizes the shared gotchas differently (react-frontend focuses on UI/accessibility implications; xrpl-typescript-fullstack focuses on data-fetching/XRPL integration implications). The overlap is ~30% of content, not 80%+.
  - Extract shared Next.js 16 / React 19 gotchas into a learning file and reference from both — reduces duplication but adds indirection for always-loaded persona content.
- **Why LOW**: The overlap is real but contextually justified. Each persona adds unique detail around the shared framework gotchas. Extracting would save ~15 lines per persona but add a conditional reference hop. Not enough signal to justify action autonomously — leave for human judgment on whether the duplication cost outweighs the context benefit.
- **Curate command**: `/learnings:curate` (manual review of both persona files)

**Status**: RESOLVED (extract shared Next.js 16 / React 19 gotchas into a learning file, reference from both personas)