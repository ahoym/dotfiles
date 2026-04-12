Patterns for designing composable, well-structured Claude Code skills.

**Keywords:** skill design, skill architecture, reference files, composability, standalone, orchestrator
**Related:** skill-platform-portability.md, multi-agent/director-patterns.md

## Skill-specific vs shared reference files

Reference files used by only one skill belong as **siblings to SKILL.md** (e.g., `address-request-comments/request-reply-templates.md`). `skill-references/` is reserved for files shared across multiple skills (e.g., `request-interaction-base.md`). Misplacing skill-specific files in `skill-references/` clutters the shared namespace and obscures ownership.

## Standalone-first skill design

Build skills as standalone units that orchestrators *call*, not as orchestrator-internal phases. The standalone path handles its own input gathering (e.g., asking the operator for intent). The orchestrator provides pre-computed inputs (e.g., a locked intent file), bypassing the standalone's gathering step. Result: the skill works independently AND composes into larger workflows.

## Conditional reference file pattern

Detect invocation mode from arguments (e.g., `--intent-file` presence → director mode), then conditionally load a sibling `.md` that adds mode-specific behavior (protocols, schemas, output conventions). The base SKILL.md stays lean — it never loads context irrelevant to the current mode. Existing examples: `re-review-mode.md`, `single-reviewer-mode.md`, `director-mode.md`.

## Coupling check for workflow phases

When reviewing plans that add a new phase to a larger workflow, ask: "is this coupled to its orchestrator, and does it need to be?" Phases designed as orchestrator-internal are harder to test, reuse, and evolve. Default to standalone-first unless tight coupling is genuinely required.

## Plan-mode design decisions

Surface all open design decisions (naming, output format, file organization, scope boundaries) in one message before requesting plan approval. Drip-feeding decisions via repeated exit-and-revise cycles adds round trips without adding clarity.
