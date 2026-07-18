Patterns for designing composable, well-structured Claude Code skills.
- **Keywords:** skill design, skill architecture, reference files, composability, standalone, orchestrator
- **Related:** skill-platform-portability.md

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

## Posting/mutating skill under plan mode → do the read-only work, gate only the write

When a skill whose payload is an external mutation (post a review, open a PR, push a branch) is invoked while plan mode is active, don't bail or immediately ask. Do the full read-only analysis (fetch, diff, subagent review, merge — most of the skill's value), stage the artifact, and hold *only* the external write until plan mode exits. Announce the hold up front; the harness blocks the write anyway, so degrading to read-only-then-execute preserves the work instead of discarding it.

## Data-contract edits require a full producer/consumer grep

A skill's data-contract surfaces — `{PLACEHOLDER}` keys filled by `fill-template.sh`, manifest/metadata field names read by runner scripts, `§ N` section references into companion files — are the highest-break-risk part of any skill edit or merge. Renaming a key in the SKILL.md schema silently orphans every consumer (prompt templates, shared preflight docs, `jq '.field'` in generators), and the failure is deferred to the next run as literal unsubstituted placeholders or null jq output. Before landing a schema change, grep every producer and consumer for the old names (`grep -o '{[A-Z_]*}' <templates>` vs the schema; `grep -n '\.fieldname' <scripts>`) — and when fanning edits out across parallel agents with disjoint file ownership, contracts that span bucket boundaries need a dedicated cross-file verifier pass, because no per-bucket editor can see the break.
