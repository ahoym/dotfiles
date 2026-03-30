General patterns for autonomous agent workflows — research methodology, empirical validation, spec design, and confidence calibration. Applies beyond ralph loops to any stateless or autonomous agent.
- **Keywords:** autonomous agent, research, validate, empirical, confidence calibration, skill-as-methodology, lazy-load, issue simplicity, absence vs exclusion
- **Related:** none

---

## Absence of Documentation ≠ Absence of Feature

When docs describe a feature only in the context of X (e.g., "auto-discovery works with `skills/`"), do NOT conclude that Y (e.g., `commands/`) lacks the feature. Silence is not exclusion. Require **explicit** evidence — a statement like "X does not support Y" — before claiming a capability difference. If the docs also contain a general equivalence statement (e.g., "both work the same way"), that should be the default position until contradicted.

**When asserting "X can't do Y":** actively search for evidence that X *can* do Y before committing to the claim. This is the adversarial/red-team step that catches false negatives.

## Broaden Primary Source Coverage in Research

Don't rely on a single doc page. When researching a feature area, traverse **related** official pages (e.g., researching skills? also read plugins, settings, reference docs). Key findings often live on adjacent pages — e.g., the plugin structure table that confirmed `commands/` support was on the plugins page, not the skills page.

## Validate Factual Claims About Runtime Behavior

Research that asserts capability differences (e.g., "directory X supports feature Y but directory Z doesn't") should be validated empirically when possible, not just inferred from docs. If the research loop constraints prevent code execution, flag the claim as **low-confidence/unverified** and note that empirical testing is needed before acting on it.

## Skill Invocation in Autonomous Agents

`claude --print` **can** invoke the Skill tool (tested 2026-03-28). This means autonomous sessions can invoke skills directly rather than reading SKILL.md as inline methodology. However, not all skills support model invocation — some return `disable-model-invocation` and can only be run as slash commands.

**Skill-as-methodology** remains useful when: (a) the skill blocks model invocation, or (b) you need to override interactive steps (AskUserQuestion → auto-apply, report generation → skip). The skill drives classification, cross-referencing, and analysis; the spec provides the autonomous overrides. When the skill evolves, the agent gets improvements for free.

## Lazy-Load Phase-Specific Methodology in Specs

Stateless agent specs benefit from splitting phase-specific methodology into separate files loaded on-demand. The core spec (constraints, workflow, transitions) stays as the prompt; the agent reads the relevant methodology file only when entering that phase. Keep shared decision criteria (e.g., candidacy rules referenced by multiple phases) in core — only extract sections used exclusively by one phase.

## "Validate" Means Run It

When asked to validate that scripts/workflows work, **execute them** — don't just lint. Static analysis (`bash -n`, file existence checks, cross-reference verification) catches structural issues but misses runtime bugs: wrong env values, ordering problems, integration failures. Default escalation: syntax check → dry-run (if available) → actual execution. Only stop at static analysis if execution is explicitly impossible or the operator says so.

When creating docs that mirror code-defined data (enums, config, topology), run the source code to validate claims programmatically. Counting items, listing values, or computing derived facts via `poetry run python3 -c "..."` catches misclassifications that manual review misses.

## Confidence Calibration Diagnostic for Autonomous Loops

When an autonomous loop produces zero items at a classification level (e.g., zero LOWs across all iterations), diagnose whether it's genuine clarity or systematic under-reporting:

1. **Audit the level above**: Check MEDIUM decisions for borderline calls that should have been LOWs. Were any "auto-applied" where the rationale required non-trivial judgment?
2. **Check the classification funnel**: Count action types per level. If the auto-apply bucket has 14 action types and the block/escalate bucket has 4, the funnel structurally prevents items from reaching the lower level.
3. **Spot-check "clean" items**: Pick 2-3 files the agent called clean and review manually. If an operator finds things the agent missed, the agent is resolving ambiguity silently rather than surfacing it.

## Issue Simplicity Heuristic for Implementer Loops

"Simple" = low-judgment, regardless of surface area. A 30-file mechanical rename is simpler than a 3-file architectural decision. Criteria:

- **In**: issue body contains enough context to execute without questions; clear done state; no external dependencies
- **Out**: requires design decisions not in the issue; requires empirical testing against external systems; body says "research"/"investigate"/"explore" without a concrete action plan

File count and cross-cutting scope don't disqualify — only judgment requirements do.

## Cross-Refs

No cross-cluster references.
