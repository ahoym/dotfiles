# Human Review Items

Items the autonomous agent couldn't or shouldn't resolve alone. Surfaced during `/ralph:consolidate:resume`.

**How to use**: Run `/learnings:curate <file>` on specific files listed below to review and decide interactively.

<!-- Each item follows one of these formats, tagged by origin:

## [L-N] Title (LOW — ambiguous classification)

- **Iter**: Iteration number when found
- **Content Type**: LEARNINGS | SKILLS | GUIDELINES
- **File**: Source file path
- **Pattern**: Section/pattern name
- **Possible classifications**: What it could be (with rationale for each)
- **Why LOW**: Why autonomous judgment wasn't sufficient
- **Curate command**: `/learnings:curate <file>`

## [BM-N] Title (BLOCKED-MED — needs human decision)

- **Iter**: Iteration number when found
- **Content Type**: LEARNINGS | SKILLS | GUIDELINES
- **Action**: What was proposed
- **Source**: Where the content lives
- **Target**: Where it would go
- **Why blocked**: Why autonomous judgment wasn't sufficient
- **Options**:
  1. Option A — description
  2. Option B — description
  3. Skip — leave as-is
- **Curate command**: `/learnings:curate <file>`

## [MAX-ROUNDS] / [MAX-DEEP-DIVES] (loop limit hit)

- **Details**: What remains unprocessed
- **Action needed**: Resume or manual curation

-->

## [L-1] git-patterns.md missing See also section (LOW)

- **Iter**: 11
- **Content Type**: DEEP_DIVE
- **File**: `.claude/learnings/git-patterns.md`
- **Pattern**: Cross-reference discoverability
- **Possible classifications**: bash-patterns.md already has reverse cross-ref → bidirectional linking would be marginally useful
- **Why LOW**: Reverse link already exists in bash-patterns.md; adding forward link is a net-positive but not required for discoverability
- **Curate command**: `/learnings:curate git-patterns.md`

## [L-2] java-backend persona missing references to java-infosec/observability files (LOW)

- **Iter**: 12
- **Content Type**: DEEP_DIVE
- **File**: `.claude/commands/set-persona/java-backend.md`
- **Pattern**: Missing detailed references to java-infosec-gotchas.md, java-observability-gotchas.md, java-observability.md
- **Possible classifications**: Add as detailed references (increases persona token cost) vs rely on keyword discovery (`java-*` naming convention is reliable)
- **Why LOW**: Both approaches are valid. Keyword discovery via `java-*` naming is reliable for the learnings search protocol. Adding references increases always-loaded persona size for marginal discoverability gain.
- **Curate command**: `/learnings:curate commands/set-persona/java-backend.md`

## [L-3] claude-authoring-skills.md — largest learning file, potential split candidate (LOW)

- **Iter**: 14
- **Content Type**: DEEP_DIVE
- **File**: `.claude/learnings/claude-authoring-skills.md`
- **Pattern**: File size (510 lines, 70+ patterns) — polling/review cluster (lines ~400-500) is the most distinct sub-topic
- **Possible classifications**: Split into `claude-authoring-skills.md` (core design) + `claude-authoring-review-skills.md` (polling/review patterns) vs keep unified
- **Why LOW**: All patterns share the "skill" keyword for lookup. Splitting improves token budget when only core patterns are needed, but adds coordination overhead and all patterns are legitimately skill design content
- **Curate command**: `/learnings:curate learnings/claude-authoring-skills.md`

## [L-4] api-design.md missing See also section (LOW)

- **Iter**: 15
- **Content Type**: DEEP_DIVE
- **File**: `.claude/learnings/api-design.md`
- **Pattern**: Cross-reference discoverability
- **Possible classifications**: Add See also linking financial-applications.md (idempotency), testing-patterns.md (validator testing), code-quality-instincts.md (parameter naming) vs rely on keyword overlap
- **Why LOW**: All related files are discoverable via shared keywords ("idempotency", "validator"). python-specific.md already has an inbound reference. Adding See also is marginally helpful but not critical.
- **Curate command**: `/learnings:curate learnings/api-design.md`

## [L-5] skill-platform-portability.md missing See also section (LOW)

- **Iter**: 16
- **Content Type**: DEEP_DIVE
- **File**: `.claude/learnings/skill-platform-portability.md`
- **Pattern**: Cross-reference discoverability
- **Possible classifications**: Add See also linking claude-authoring-skills.md (complementary design patterns), claude-code.md (permission/platform mechanics) vs rely on keyword overlap and existing reverse reference
- **Why LOW**: claude-authoring-skills.md line 507 already has reverse reference to this file. Keyword overlap ("skill", "platform") sufficient for discovery. Adding See also is marginally helpful but not critical.
- **Curate command**: `/learnings:curate learnings/skill-platform-portability.md`

## [L-6] nextjs.md contains generic TypeScript pattern (LOW)

- **Iter**: 17
- **Content Type**: DEEP_DIVE
- **File**: `.claude/learnings/nextjs.md`
- **Pattern**: "Extending a Union Type Used in Record Keys" (lines 86-91)
- **Possible classifications**: Move to a TypeScript-specific learnings file or code-quality-instincts.md vs keep in nextjs.md where it was discovered
- **Why LOW**: The pattern is generic TypeScript (union type + Record key extension), not Next.js-specific. But it's small (5 lines), discoverable in current location, and there's no existing TypeScript-specific learnings file to move it to. Creating one for 5 lines is overhead.
- **Curate command**: `/learnings:curate learnings/nextjs.md`

## [L-7] nextjs.md missing See also section (LOW)

- **Iter**: 17
- **Content Type**: DEEP_DIVE
- **File**: `.claude/learnings/nextjs.md`
- **Pattern**: Cross-reference discoverability
- **Possible classifications**: Add See also linking react-patterns.md (hydration, hooks), testing-patterns.md (route handler testing), react-frontend-gotchas.md (condensed companion) vs rely on persona references and keyword overlap
- **Why LOW**: Both personas (react-frontend, xrpl-typescript-fullstack) already list nextjs.md as a detailed reference. react-frontend-gotchas.md companion header covers Next.js gotchas. Keyword overlap ("Next.js", "proxy", "Turbopack") sufficient for discovery.
- **Curate command**: `/learnings:curate learnings/nextjs.md`

## [L-8] react-patterns.md missing See also section (LOW)

- **Iter**: 18
- **Content Type**: DEEP_DIVE
- **File**: `.claude/learnings/react-patterns.md`
- **Pattern**: Cross-reference discoverability
- **Possible classifications**: Add See also linking reactive-data-patterns.md (complementary refresh/polling patterns), refactoring-patterns.md (general survey methodology), react-frontend-gotchas.md (companion tripwires) vs rely on companion header and keyword overlap
- **Why LOW**: react-frontend-gotchas.md companion header already references react-patterns.md (line 3). Both personas (react-frontend, xrpl-typescript-fullstack) list it. reactive-data-patterns.md is discoverable via keyword overlap ("polling", "refresh", "localStorage"). Adding See also would be marginally helpful but not critical.
- **Curate command**: `/learnings:curate learnings/react-patterns.md`

## [L-9] explore-repo.md missing See also section (LOW)

- **Iter**: 19
- **Content Type**: DEEP_DIVE
- **File**: `.claude/learnings/explore-repo.md`
- **Pattern**: Cross-reference discoverability
- **Possible classifications**: Add See also linking multi-agent-patterns.md (synthesis architecture, output file patterns, structural context for subagents) and claude-authoring-skills.md (stateful mode detection cross-ref) vs rely on keyword overlap and existing inbound cross-ref
- **Why LOW**: claude-authoring-skills.md line 38 already has an inbound cross-ref. multi-agent-patterns.md covers related general patterns at different granularity. No personas reference explore-repo.md directly. Keyword overlap ("synthesis", "scan", "agent") sufficient for discovery.
- **Curate command**: `/learnings:curate learnings/explore-repo.md`

## [L-10] code-quality-instincts.md missing See also section (LOW)

- **Iter**: 22
- **Content Type**: DEEP_DIVE
- **File**: `.claude/learnings/code-quality-instincts.md`
- **Pattern**: Cross-reference discoverability
- **Possible classifications**: Add See also linking process-conventions.md (complementary: code vs process), refactoring-patterns.md (refactoring methodology for code quality instincts) vs rely on keyword overlap and existing reverse reference
- **Why LOW**: process-conventions.md line 165 already has reverse link. 6 personas reference this file (highest persona coverage in corpus). Keyword overlap ("code quality", "duplication", "dead code") sufficient for discovery.
- **Curate command**: `/learnings:curate learnings/code-quality-instincts.md`
