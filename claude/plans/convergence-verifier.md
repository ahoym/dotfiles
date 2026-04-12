# Convergence Verifier

> **SUPERSEDED** (2026-04-12): Implemented as standalone-first skill `/verify-business-logic`. See:
> - Skill: `claude/commands/git/verify-business-logic/SKILL.md`
> - Persona: `claude/commands/set-persona/convergence-verifier.md`
> - Director integration: Phase 1 (intent capture) + Phase 5 (verifier invocation) in `claude/commands/director/SKILL.md`
>
> Key design change from this plan: verifier is a standalone skill the director calls, not a director-internal phase. Output is a top-level PR comment (not local-only). Intent capture splits: lightweight version in verifier (standalone), full negotiation in director.

A post-convergence check that runs once per PR per session, after compound mode reaches a stable state. Produces a local report (not posted to the PR) that the operator reviews before merging. Designed to close the gap where reviewer/addresser drift goes unnoticed because the operator can't manually re-read every comment.

## Why it exists

The reviewer/addresser feedback loop catches **reviewer's findings** (addresser fixes) and **addresser's fixes** (next-cycle reviewer reacts). It does NOT catch:

- **Reviewer's own discipline drift** (body shape, reaction style, summary content) — no second eye on it.
- **Intent drift across cycles** — the PR set out to do X, scope expanded along the way, did the final state still hit the original X?
- **Quality/completeness gaps** — placeholder text, broken sub-pieces, missing follow-through.

These currently get caught by the operator manually reading each PR. The verifier closes that loop.

## Report structure

Two sections, distinct because they have different confidence profiles.

### Section 1 — Discipline (high confidence, deterministic-ish)

Structural rules from the skill templates. Assertions, not opinions.

- **Body shape**: review body has no per-finding ledger; addresser top-level uses single-line variant when zero escalations.
- **Reaction discipline**: resolved/acknowledged threads are reaction-only (no text reply restating the addresser).
- **Loop closure**: every inline finding has a reaction or text reply; every "Resolved" claim corresponds to a real diff hunk; no orphaned threads (replies on threads with no original comment, findings posted but never replied to).

Output format: assertions with cited comment IDs and exact rule references.

### Section 2 — Intent alignment (LLM judgment, lower confidence — frame as "things to check," not verdicts)

- **Acceptance check**: each item in the captured intent → was it delivered? Cite the commit + diff lines.
- **Scope drift**: what got pulled in beyond the original intent? Classify as `intentional expansion` / `unrelated drift` / `missed cleanup`.
- **Quality gate**: obviously broken/incomplete pieces — placeholder text, TODO comments left in, half-implemented branches.
- **Side effects**: changes outside the intent (ambient learnings commits, etc.). Surface, don't judge.

Output format: questions framed for operator review, with specific citations. No vague "the PR seems incomplete." Always cite line/comment IDs.

## Intent capture (director-led negotiation)

The director collaborates with the operator to articulate intent at session start, then writes a structured artifact that the verifier reads at convergence. This is **active**, not passive — the director drafts, the operator confirms or revises, the result is locked. Catches ambiguity at the start instead of letting drift accumulate to convergence. Grounds the decision framework: "is this in scope?" becomes a checkable question against the locked artifact.

> **Future evolution**: an operator-approved library of **mission-briefs** (see `mission-brief-library.md`) becomes the highest-preference intent source. When a new item matches a stored mission-brief with high confidence, the director applies it silently — no negotiation needed. Director-led negotiation remains the fallback for items that don't match any stored mission-brief.

### Negotiation flow

1. Operator triggers compound mode on a PR/issue (or adds an item mid-session).
2. Director reads item metadata (PR title/description/linked issues, or issue body) plus any conversation context.
3. Director **drafts** an initial intent file from that metadata.
4. Director presents the draft to the operator: "Here's what I think we're building. Confirm, revise, or fill the gaps."
5. Operator responds freeform.
6. Director restructures the response into the final intent shape and writes to `<session_dir>/intents/<id>.md`.
7. One revision round if the operator wants to tighten anything.
8. Once confirmed, the file is **locked** for the session.

### Lock-and-update cycle

The intent file is locked after operator confirmation. In-session scope expansion does NOT mutate the file silently — it goes through an explicit update step:

1. Director (or verifier mid-run) detects in-session scope expansion (e.g., reviewer surfaces a finding outside the original intent).
2. Director presents the expansion to the operator with the question: "Add to intent or defer to a follow-up issue?"
3. If add: director appends a dated revision section to the intent file, increments the revisions counter in the metadata header, and logs the update to `decisions.md` with category `intent-update`.
4. If defer: director files a GitHub issue per the framework's out-of-scope handling, logs to `decisions.md`, and the intent file stays unchanged.

The verifier always reads the **current** locked state of the intent file at convergence — the cumulative result of all approved updates, not the original.

### Directory layout — one file per item

Director sessions coordinate N items, so intents live in a directory keyed by item ID:

```
<session_dir>/intents/
  pr-78.md
  pr-79.md
  issue-56.md
  index.md          # optional rollup — one-line per item, "what is this session working on"
```

Each file stands alone. Mid-session additions create new files. Mid-session item closures (PR merged/closed) leave the file in place as a historical record — the verifier knows from `session.json` which items are still active.

### Per-item file shape

```markdown
# Intent: PR #<N> — <title>

**Item ID**: pr-<N>
**Status**: locked at <ISO> (revisions: <count>)
**Source**: director-negotiated | agent-prompt | inferred-from-pr-description

## Goal
<one or two sentences — what done looks like>

## Acceptance criteria
- [ ] <criterion 1 — checkable>
- [ ] <criterion 2 — checkable>

## Out of scope
- <thing the operator explicitly didn't want pulled in>

## Success signals
<observable outputs the verifier can check at convergence — not internal states>
```

### Three sources for the directory contents

1. **Director-negotiated** (preferred): the negotiation flow above. Highest confidence; the operator confirmed.
2. **Agent prompt as intent**: for mid-session PRs built by an `Agent(isolation: "worktree")` call, the agent's prompt is restructured into the standard intent shape and written to `intents/<id>.md`. Director restructures, doesn't just dump the prompt verbatim. Source field: `agent-prompt`.
3. **PR description fallback**: for items added mid-session without explicit negotiation (e.g., a new PR opened externally), director drafts from PR metadata and writes with `Source: inferred-from-pr-description`. Verifier sees the lower confidence and tones down its scope-drift checks accordingly.

### Index file (optional but recommended)

`<session_dir>/intents/index.md` — one line per item, updated whenever an intent is added or revised. Format:

```markdown
# Intents — director session 2026-04-11-1015

- pr-78.md — Batch import skill + learnings refinements [locked, rev 0]
- pr-79.md — Codify director decision-making framework [locked, rev 1]
- issue-56.md — Provider-aware learnings (in negotiation)
```

Lets the operator see the session at a glance without opening every file. Also useful for retro: what did this session set out to accomplish?

## Mid-run clarification

If intent is too vague to evaluate scope drift or acceptance, the verifier may request clarification from the director once per run. This is **dynamic decision-making** — products aren't built right the first time, and the verifier needs the same flexibility the director has.

Mechanism:

- Verifier's prompt allows it to output `CLARIFY: <question>` instead of a final report.
- Director receives the clarification request, logs it to `<session_dir>/decisions.md` with category `verifier-clarification`, and routes per the **Decision Framework** in `director-playbook.md`:
  - **Simple/silent** (verifier asks for a missing acceptance criterion that's obvious from context): director answers and re-invokes verifier.
  - **Complex/escalate** (verifier asks something that requires operator judgment about intent): director escalates to operator with the question, then re-invokes verifier with the answer.
- Maximum one round of clarification per verifier run. If still unclear after one round, the verifier produces a "intent too vague to evaluate" report instead of looping.

This loop is what makes the verifier continuously improve the director loop — each clarification request surfaces a gap in intent capture or decision routing, which feeds back into refinements.

## Where it fires

Director skill Phase 5 (Convergence + Wrap-up), before presenting the final summary to the operator. Replaces or precedes the current "ready to merge?" prompt. Operator gets the verifier report alongside the usual summary.

## Output location

`<session_dir>/verify-pr-<N>.md` — local to the director session dir, **not posted as a PR comment**. The report is for the operator's pre-merge decision, not for future reviewers or PR history. Posting it would add noise.

## Persona

A small dedicated `convergence-verifier` persona — checks structural rules, applies the framework for clarification routing, no domain lens. The reviewer already did the domain check; the verifier checks the meta. Lean persona; the prompt does most of the lifting.

## Cost

~$0.20-0.50 per PR per session. One `claude -p` invocation, more reasoning than a discipline-only check. Acceptable — fires once at convergence, not per cycle. Compare to the cost of the operator manually re-reading every comment (the human cost dominates).

## Trust calibration

First several sessions: run the verifier alongside operator manual review. If verifier consistently flags what the operator would flag manually, trust grows and the operator reads fewer PR comments by hand. If verifier produces noise (false positives) or misses things, tune the prompt. Treat it as a build-trust-then-cede-judgment progression — the same shape as the director decision framework itself.

## Open questions to revisit when building

- **Verifier-vs-reviewer disagreement**: if the verifier flags something the reviewer didn't catch, who arbitrates? Probably the operator, via the same escalation framework. But could be a structural mini-debate between the two personas.
- **Per-PR vs cross-PR**: in a multi-PR sweep session, should the verifier produce one report per PR or a session-level aggregate? Lean per-PR for clarity.
- **Re-verification on relaunch**: if the operator addresses verifier findings and re-runs compound mode, does the verifier re-fire on the next convergence? Yes — the report is per-session, not per-PR-lifetime.
- **Discipline rule source**: where do the discipline rules live? Probably in a single `claude/skill-references/verifier-discipline-rules.md` so the verifier prompt points at one canonical source. Updating the rules updates the check automatically.

## Implementation sketch (rough order)

1. Write the `convergence-verifier` persona at `~/.claude/commands/set-persona/convergence-verifier.md`.
2. Write the verifier prompt template at `claude/skill-references/verifier-prompt.md` (with placeholders for intent, diff, final state, discipline rules).
3. Write the canonical discipline rules at `claude/skill-references/verifier-discipline-rules.md`.
4. Add Phase 5 step to the director skill that invokes the verifier per converged PR.
5. Add intent-capture prompt to director skill Phase 1.
6. Add `decisions.md` schema entry for `verifier-clarification` (depends on PR 79 framework merging first).
