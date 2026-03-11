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

## [L-1] Next.js 16 pointer overlap between personas

- **Iter**: 2
- **Content Type**: SKILLS
- **File**: `commands/set-persona/xrpl-typescript-fullstack.md` + `commands/set-persona/react-frontend.md`
- **Pattern**: Both have `### Next.js 16 / Turbopack` subsection pointing to `learnings/nextjs.md`
- **Possible classifications**:
  1. Deduplicate — remove from one persona (but which? both domains use Next.js)
  2. Keep as-is — both are thin pointers, xrpl adds "rate limiter wiring" which is domain-specific
- **Why LOW**: Both pointers are intentional and serve different personas. The xrpl version includes a domain-specific detail. Removing either could reduce discoverability for that persona's users.
- **Curate command**: `/learnings:curate commands/set-persona/xrpl-typescript-fullstack.md`

## [L-2] vercel-deployment.md not in xrpl-typescript-fullstack Detailed references

- **Iter**: 14
- **Content Type**: DEEP_DIVE
- **File**: `commands/set-persona/xrpl-typescript-fullstack.md`
- **Pattern**: Detailed references section missing vercel-deployment.md
- **Possible classifications**:
  1. Wire reference — vercel-deployment.md has Postgres patterns and cron limits relevant to fullstack XRPL on Vercel
  2. Keep as-is — persona already covers critical Vercel gotchas (WebSocket, rate limiter), and vercel-deployment.md is discoverable via keyword search
- **Why LOW**: Marginal value — persona's Vercel section already has the most critical gotchas, and the deployment file is general platform knowledge rather than XRPL-specific. Discoverable without explicit wiring.
- **Curate command**: `/learnings:curate commands/set-persona/xrpl-typescript-fullstack.md`
