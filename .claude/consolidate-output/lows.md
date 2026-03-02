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

## [L-1] Cross-persona duplication: react-frontend + xrpl-typescript-fullstack

- **Iter**: 2
- **Content Type**: SKILLS (cross-persona check)
- **File**: `commands/set-persona/xrpl-typescript-fullstack.md`
- **Pattern**: React/Next.js gotchas duplicated across both personas
- **Duplicated content** (~15 lines):
  - `setState` in `useEffect` → render-time sync pattern (React 19)
  - localStorage hydration gating for SSR
  - Next.js 16 proxy.ts/dynamic params mentions
  - `error boundary isolation` pattern
- **Possible approaches**:
  1. **xrpl extends react-frontend** — removes duplication, xrpl inherits all React patterns. Risk: changes persona dependency structure for a heavily-used persona; child "When making tradeoffs" section is XRPL-focused while parent's is React-focused, which is the correct layering.
  2. **Remove React duplicates from xrpl** — keep xrpl standalone but trim the React-generic lines, adding a note to also activate react-frontend for React-specific patterns. Risk: xrpl persona would be incomplete for fullstack XRPL+React work without a second persona.
  3. **Keep as-is** — ~15 lines of duplication is tolerable for a self-contained fullstack persona. The duplication ensures xrpl users get React patterns without needing a second persona activation.
- **Why LOW**: Multiple valid approaches, each with meaningful tradeoffs. The extends mechanism would be cleanest structurally but changes a well-established persona's behavior. The "more specialized persona owns the gotcha" rule is ambiguous here — xrpl is more specialized for XRPL work but react-frontend is more specialized for React work.
- **Curate command**: `/learnings:curate commands/set-persona/xrpl-typescript-fullstack.md`
