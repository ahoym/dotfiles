Patterns for designing composable, well-structured Claude Code skills.
- **Keywords:** skill design, skill architecture, reference files, composability, standalone, orchestrator
- **Related:** skill-platform-portability.md, multi-agent/director-patterns.md

## Skill-specific vs shared reference files

Reference files used by only one skill belong as **siblings to SKILL.md** (e.g., `address-request-comments/request-reply-templates.md`). `skill-references/` is reserved for files shared across multiple skills (e.g., `request-interaction-base.md`). Misplacing skill-specific files in `skill-references/` clutters the shared namespace and obscures ownership.

## Standalone-first skill design

Build skills as standalone units that orchestrators *call*, not as orchestrator-internal phases. The standalone path handles its own input gathering (e.g., asking the operator for intent). The orchestrator provides pre-computed inputs (e.g., a locked intent file), bypassing the standalone's gathering step. Result: the skill works independently AND composes into larger workflows.

## Conditional reference file pattern

Detect invocation mode from arguments (e.g., `--intent-file` presence → director mode), then conditionally load a sibling `.md` that adds mode-specific behavior (protocols, schemas, output conventions). The base SKILL.md stays lean — it never loads context irrelevant to the current mode. Existing examples: `re-review-mode.md`, `single-reviewer-mode.md`, `director-mode.md`.

## Related Learnings cross-refs belong at the bottom, framed on-demand

SKILL.md cross-refs to related learnings go at the end of the file, framed as "Reference files — load on demand when relevant friction surfaces. Not required for every invocation." Putting them at the top implies mandatory upfront loads, wasting context on information that may not apply. Bottom placement + on-demand framing communicates: available when needed, not a required preamble.

**Why cross-refs matter:** Session-start learnings gates fire inconsistently on `/skill` invocations — the gate may skip keyword globs and go straight to skill execution. Explicit cross-refs in SKILL.md are a deterministic backstop: they load when the skill loads, independent of gate behavior. Treat them as protocol-failure insurance, not redundant linking.

## Coupling check for workflow phases

When reviewing plans that add a new phase to a larger workflow, ask: "is this coupled to its orchestrator, and does it need to be?" Phases designed as orchestrator-internal are harder to test, reuse, and evolve. Default to standalone-first unless tight coupling is genuinely required.
