---
description: "Decision matrix for director autonomy: escalation tiers, routine vs judgment calls, out-of-scope handling, decisions.md schema."
---

# Decision Matrix

Classifies every director action into an escalation tier. Apply this before every action in Phase 4 (Monitor + React). The matrix classifies the *rules*, not individual actions — when the rule that triggers an action is unambiguous, execute and surface what was done.

## Escalate to operator (operator makes the call)
1. **Irreversible / high-blast-radius actions** — force-push to main, branch deletion, data drops, anything bypassing safety hooks. Operator pulls the trigger even when "obviously fine."
2. **Scope expansion that changes PR intent** — pulling refactors into bug fixes, expanding a learnings PR into a skill rewrite. Small in-scope fixes are NOT escalated; out-of-scope discoveries are NOT escalated (see "Out-of-scope handling" below).
3. **Security / auth / compliance touchpoints** — secrets, permission patterns, sensitive files, external credentials. Blast radius beyond the repo means the director can't fully reason about it.
4. **Conflicting evidence about operator intent** — stated goal vs code signal disagree, or a request reads two ways with materially different outcomes. Escalate **with a written report** in `decisions.md` — not just a verbal ask.
5. **External-facing surfaces** — PR titles/descriptions others read, public docs, anything landing beyond the operator/director loop.

## Decide-with-report (director decides, logs rationale to `decisions.md`)
6. **Subagent / reviewer dissent surviving deliberation** — two personas hold incompatible positions after a deliberation pass and the call is taste-based. Director makes the call and logs why.
7. **Cost / time blowups** — sessions about to spawn many parallel agents, run for hours, or hit rate-limit cliffs. Director decides; reports estimated duration at launch and material deviations (>2x estimate) thereafter.

## Decide silently (no report needed)
- Routine convergence calls in compound mode (deterministic per Convergence Rules).
- Small in-scope fixes that match the PR's intent.
- Choosing between equivalent technical paths.
- Body discipline / formatting / template decisions.
- Whether to write a directive for a summary-only finding inside the current scope.
- **Conflict resolution** — write directive to addresser, launch address runner. Do not ask operator. Do not do the git work yourself.
- **Persona propagation** — carry forward persona from prior runs in the same session.
- **Relaunch decisions** — deterministic from convergence rules and relaunch sequence.

## Out-of-scope handling

When a review surfaces a finding clearly outside the current PR's scope, the director:
1. Files a GitHub issue in the CWD repo. Issue body includes: source PR/session reference, the finding text, suggested fix if any, and the persona that surfaced it.
2. Logs the issue creation in `decisions.md` so the operator can audit what got punted.
3. Optionally spawns `/sweep:work-items` to address immediately, **only if context window allows**.

## `decisions.md` schema

Lives at `<session_dir>/decisions.md` alongside `session.json`. Append-only dated sections:

```markdown
## <ISO timestamp> — <one-line title>

**Category**: <dissent | cost-time | out-of-scope | irreversible | scope-expansion | security | intent-conflict | external-surface>
**Decision**: <what was decided>
**Why**: <rationale, including what was weighed>
**Reversal cost**: <how easy is this to undo>
**Reported to operator**: <yes/no — yes for escalated categories, no for decide-with-report categories>
```

Write to `decisions.md` at decision time for categories 4, 6, 7. For categories 1, 2, 3, 5, escalate to chat first and log the operator's response afterward.
