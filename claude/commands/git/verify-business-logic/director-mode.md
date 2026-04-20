# Director Mode

Loaded when `/verify-business-logic` is invoked with `--intent-file <path> --session-dir <path>`. These conventions govern behavior when the director orchestrates the verifier.

## Intent File Schema

The director writes locked intent files to `<session_dir>/intents/<id>.md`. The verifier reads these — never writes or modifies them.

```markdown
# Intent: PR #<N> — <title>

**Item ID**: pr-<N>
**Status**: locked at <ISO> (revisions: <count>)
**Source**: director-negotiated | agent-prompt | draft-timeout | inferred-from-pr-description

## Goal
<one or two sentences — what done looks like>

## Acceptance criteria
- [ ] <criterion 1 — checkable>
- [ ] <criterion 2 — checkable>

## Out of scope
- <thing the operator explicitly didn't want pulled in>

## Success signals
<observable outputs the verifier can check at convergence>
```

**Source field affects confidence**:
- `director-negotiated`: highest confidence — operator confirmed. Full scope-drift analysis warranted.
- `agent-prompt`: medium — restructured from the agent's prompt, not directly confirmed by operator. Note lower confidence in report.
- `draft-timeout`: medium-low — director drafted intent from metadata and presented to operator, but operator did not respond within the timeout window. Higher confidence than pure inference (operator saw the draft) but lower than explicit confirmation.
- `inferred-from-pr-description`: lowest — tone down scope-drift checks. Frame as suggestions, not assertions.

## CLARIFY Protocol

When the verifier needs clarification on intent (too vague to evaluate scope drift or acceptance), output the following instead of a final report:

```
CLARIFY: <specific question about the intent>
```

The director receives this and routes through its Decision Framework:
- **Simple/silent**: director answers from context and re-invokes verifier
- **Complex/escalate**: director asks operator, then re-invokes verifier with the answer

**Rules**:
- Maximum one `CLARIFY` per verifier run. If still unclear after one round, produce a report with an "intent too vague to evaluate" section and exit with `VERIFIED:intent-unclear` status instead of looping. The `intent-unclear` status is a **blocking signal** — the director must not converge the session on this PR.
- **Enforcement**: the director passes `--clarify-answered` on re-invocation after routing a CLARIFY. In Step 2, when `--clarify-answered` is present and intent is still vague, skip CLARIFY and emit `VERIFIED:intent-unclear` directly. This prevents infinite loops — a fresh Skill instance has no memory of prior runs, so the flag is the protocol-level enforcement mechanism.
- `CLARIFY` is only for intent ambiguity — discipline checks never need clarification.
- The director logs clarification requests to `decisions.md` with category `verifier-clarification`.
- `CLARIFY` is checked at Step 2 (after reading intent, before fetching PR data) to avoid wasting API calls on an intent that can't be evaluated.

## Session Dir Output

In addition to posting a top-level PR comment, write the report to:

```
<session_dir>/verify-pr-<N>.md
```

where `<N>` is the PR number. This local copy lets the director include it in the Phase 5 summary and the session retro.

## Decision Framework Categories

The director uses these categories when logging verifier-related decisions:

| Category | When |
|----------|------|
| `verifier-clarification` | Director answered or escalated a `CLARIFY` request |
| `intent-update` | Director updated a locked intent file (scope expansion approved by operator) |
