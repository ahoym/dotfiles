# Mission Brief Library

A persistent library of **mission-briefs** — operator-approved descriptions of what a class of work converges to. Mission Briefs encode predictable business inputs and outputs so the director can match new items against existing patterns and apply them with judgment, instead of negotiating intent from scratch every session.

## Why this exists

Today's intent capture (see `convergence-verifier.md` → "Intent capture") is per-session: every new item triggers a fresh negotiation. Patterns repeat — over time, the same kinds of work converge to the same shapes. Negotiating each one from scratch wastes operator time and produces inconsistent results.

A mission-brief library captures those repeated shapes once. The director matches new items against the library, applies mission-briefs that fit, and only escalates when no mission-brief matches or a partial match needs operator confirmation. Over many sessions, the library grows; the director's negotiation surface shrinks; the operator only sees novel cases.

This is the substrate that lets the operator-cession framework keep evolving — early sessions surface lots of negotiation, later sessions auto-apply because the corpus of approved patterns is larger.

## What a mission-brief is (and is not)

A mission-brief is **looser than a contract**. It describes the shape of expected deliverables and acceptance criteria for a class of work — not the steps to execute or the implementation path. The implementation is up to the agents; the mission-brief just defines what done looks like. Mission Briefs are checkable but not prescriptive.

Compare to existing content types:

| Type | Encodes | Read by |
|---|---|---|
| **Skill** | Repeatable procedure (steps to execute) | Operator (`/skill-name`) or another skill |
| **Persona** | Judgment lens (priorities, tradeoffs) | Subagent at activation |
| **Learning** | Patterns and gotchas (knowledge) | Reactive search at gates |
| **Mission Brief** (new) | Expected business inputs/outputs (shape of done) | Director at intent capture, verifier at convergence |

A mission-brief is neither a procedure nor a knowledge gotcha. It's the operator-approved answer to "what does done look like for this kind of work?" — applied automatically by the director when a new item matches.

## Per-item, optional session-level

Mission Briefs operate at the **item level** by default. Each PR/issue/work-item gets one mission-brief that describes its shape of done.

A **session-level mission-brief** is optional. If the items in a director session cohere into one piece of work (e.g., compound mode on a single PR with ambient learnings commits), the operator can offer one and the director writes it to `<session_dir>/mission-briefs/_session.md`. But /director is a multi-purpose orchestrator — sessions can legitimately span unrelated work, so coherent session-level mission-briefs are the exception, not the rule.

The verifier checks **per-item only**. Session-level mission-briefs, when they exist, are useful for retro narrative and `decisions.md` grounding but don't constrain the per-item verifier checks. Keeps the verifier simple — one check per item, regardless of session shape.

## Where mission-briefs live

Cluster within the existing learnings tree to avoid introducing a new content type:

```
~/.claude/learnings/mission-briefs/
  CLAUDE.md                           # cluster routing table — maps trigger conditions to mission-brief files
  claude-config-convergence.md
  downstream-agent-usability.md
  security-finding-resolution.md
  hot-path-refactor.md
  learnings-batch-import.md
  ...
```

The cluster CLAUDE.md is a routing table:

```markdown
# Mission Briefs — class-of-work definitions

| Mission Brief | Triggers when |
|-------|---------------|
| claude-config-convergence.md | PR title mentions skills/guidelines/learnings/personas; touches `claude/commands/`, `claude/learnings/`, `claude/skill-references/`, or `claude/guidelines/` |
| downstream-agent-usability.md | Session goal mentions "downstream agents", "agent usability", "discoverability"; PR touches files agents read at runtime |
| security-finding-resolution.md | PR title mentions security/CVE/vulnerability; touches auth/crypto/security files |
| ... | ... |
```

## Mission Brief file shape

```markdown
# Mission Brief: <class of work — short, descriptive>

**Triggers when:** <signals — keywords, file paths, label patterns, PR title patterns>
**Auto-apply when:** <stricter signals — silent application, no operator prompt>
**Confirm with operator when:** <partial signals — apply as draft, ask for confirmation>
**Fall through to negotiation when:** <none of the above match>
**Source:** distilled from N sessions (link to retros where this pattern emerged)

## Goal
<one or two sentences — what done looks like for this class of work>

## Default acceptance criteria
- [ ] <criterion 1 — checkable at convergence>
- [ ] <criterion 2 — checkable at convergence>

## Default out-of-scope
- <thing the operator typically defers to follow-up issues for this class of work>

## Default success signals
<observable outputs the verifier checks at convergence — not internal states>

## Notes for the director
<judgment hints — when to relax a criterion, when to escalate early, common drift patterns to watch for>
```

## How the director uses mission-briefs

Mission Brief matching becomes the **fourth and highest-preference source** for intent capture (the others are described in `convergence-verifier.md`):

1. **Mission Brief-applied** (highest preference when matched): director searches the mission-brief library against item metadata. Match handling depends on confidence:
   - **High-confidence match** (all auto-apply triggers fire): director writes the mission-brief's defaults to `intents/<id>.md` with `Source: mission-brief-applied (<mission-brief-name>)`, decision logged to `decisions.md`. **No operator prompt.**
   - **Partial match** (some triggers fire, some don't): director uses the mission-brief as the draft and presents it to the operator: "I think this matches mission-brief X. Confirm or revise." Same shape as today's negotiation, but starting from a populated draft instead of a blank.
   - **No match**: fall through to director-led negotiation (the current preferred path).
2. **Director-negotiated**: fallback when no mission-brief matches.
3. **Agent prompt as intent**: unchanged — for mid-session built PRs.
4. **PR description fallback**: unchanged — lowest confidence.

The decision framework applies to mission-brief application:

| Match confidence | Director behavior | Decision tier |
|---|---|---|
| Auto-apply triggers all fire | Apply silently, log to decisions.md | Decide silently |
| Partial match | Confirm with operator, log result | Decide-with-report |
| No match | Negotiate from scratch | Standard negotiation |
| Match conflict (two mission-briefs claim the same item) | Surface to operator with both mission-briefs and the conflict | Escalate |

## Accumulation pattern

Mission Briefs are not built upfront. They emerge from session retros — "we negotiated intent for this same class of work three sessions in a row, the negotiation always lands on the same shape, let's distill it into a mission-brief."

The session-retro skill should add a "mission-brief candidates" step: scan this session's negotiated intents against the mission-brief library. For any intent that doesn't match an existing mission-brief but resembles intents from prior sessions, prompt the operator: "this looks like a recurring pattern. Promote to a mission-brief, or skip?"

When promoting:
1. Operator confirms the pattern is recurring.
2. Director drafts a mission-brief from the negotiated intents (using the per-item mission-briefs from this and prior sessions as seed material).
3. Operator confirms or revises the trigger conditions and acceptance criteria.
4. Mission Brief is written to `~/.claude/learnings/mission-briefs/<name>.md`.
5. Cluster CLAUDE.md routing table is updated.
6. Future sessions matching the triggers will auto-apply or confirm-apply the new mission-brief.

## Worked example

Operator's example phrasing: "Review, address to convergence and ensure that new Agents can easily and predictably understand and use the new claude configs."

This decomposes into **two mission-briefs** that often get used together in claude-config sessions:

### Mission Brief 1: `claude-config-convergence.md`

```markdown
# Mission Brief: Claude config convergence

**Triggers when:** PR touches `claude/commands/`, `claude/learnings/`, `claude/skill-references/`, `claude/guidelines/`, or `claude/CLAUDE.md`; PR title mentions skills, guidelines, learnings, personas, or templates
**Auto-apply when:** PR scope is contained to claude/ tree AND no security-relevant files touched
**Confirm with operator when:** PR also touches non-claude/ files (mixed scope)
**Fall through when:** No claude/ files touched

## Goal
Land claude config changes through a full review/address compound loop, ending in a state where every reviewer finding is resolved or explicitly deferred, and no in-flight cycle has unaddressed activity.

## Default acceptance criteria
- [ ] Review/address loop reaches convergence (0 new findings, 0 unaddressed threads)
- [ ] All in-scope files have valid structural conventions (headers, cross-refs, index registration)
- [ ] No stale cross-references introduced (file refs resolve to actual files)
- [ ] PR description matches the actual delivered scope (no drift)

## Default out-of-scope
- Refactoring unrelated config files
- Adding new content types or skills not directly required by the change
- Performance optimization

## Default success signals
- Verifier reports 0 discipline violations
- Verifier reports 0 intent acceptance failures
- All reviewer findings have rocket reactions or explicit defer logs

## Notes for the director
- Body discipline rules (no per-finding ledger, reaction-only resolutions) apply automatically when this mission-brief is in effect
- Persona used by reviewers should be claude-config-reviewer — if not auto-detected, the director should set it before launching review
- Watch for stale-ref class bugs — they're the #1 maintenance issue in claude/ and the verifier should specifically check
```

### Mission Brief 2: `downstream-agent-usability.md`

```markdown
# Mission Brief: Downstream agent usability

**Triggers when:** Session goal mentions "downstream agents", "agent usability", "discoverability"; PR touches files agents read at runtime (CLAUDE.md, learnings indexes, skill-references); session is negotiating with the operator about how agents will use new content
**Auto-apply when:** Operator session goal explicitly includes the phrase "agent usability" or "downstream agents"
**Confirm with operator when:** Session touches files agents read but operator hasn't explicitly invoked the usability lens
**Fall through when:** No agent-readable files touched

## Goal
Ensure new content can be discovered and used by future agent sessions through the standard discovery mechanisms (cluster CLAUDE.md indexes, keyword search, persona cross-refs, @-loaded guidelines).

## Default acceptance criteria
- [ ] New files have valid headers (description, Keywords, Related)
- [ ] New files are listed in their cluster CLAUDE.md index
- [ ] New behavioral rules are @-referenced from the appropriate CLAUDE.md (not orphaned)
- [ ] Persona cross-refs updated if new files target a specific persona's domain
- [ ] No @-references introduced that resolve to non-existent files

## Default out-of-scope
- Renaming existing files (separate concern)
- Cluster reorganization
- Index format changes

## Default success signals
- Future-session search protocol can find the new content via gates (session-start glob, keyword, pre-edit)
- A clean session reading the cluster CLAUDE.md sees the new files in the routing table

## Notes for the director
- This mission-brief commonly pairs with claude-config-convergence — apply both when they both match
- The verifier should specifically check that new files appear in the relevant cluster CLAUDE.md, not just that they exist
```

A session matching both mission-briefs (e.g., a compound mode session on a PR landing new learnings + skill updates) gets both applied. Per-item intents inherit from both. The verifier checks each item against the union of acceptance criteria from both mission-briefs.

## Cross-references

- `convergence-verifier.md` — the consumer of mission-briefs at convergence time. Mission Briefs feed the "intent capture" section as the highest-preference source.
- `~/.claude/learnings/claude-authoring/routing-table.md` — should eventually be updated to include "Mission Brief" as a content sub-type within the learnings cluster (not a new top-level type).

## Open questions to revisit when building

- **Mission Brief versioning**: when a mission-brief evolves (operator updates the acceptance criteria after a retro), should the verifier compare against the version in effect when the session started, or the latest version? Lean: latest at convergence — operators want their newest understanding applied.
- **Multiple mission-brief matches**: handled via the decision framework (escalate on conflict). But what's the right resolution for two mission-briefs that both match cleanly with non-overlapping acceptance criteria? Lean: apply both, union the criteria.
- **Mission Brief retirement**: when does an obsolete mission-brief get removed? Probably during retro when a mission-brief hasn't fired in N sessions or its triggers have stopped matching real work.
- **Mission Brief discoverability for the operator**: how does the operator browse the library, see what exists, and decide whether to invoke the director with a specific mission-brief in mind? Could be as simple as `~/.claude/learnings/mission-briefs/CLAUDE.md` being the entry point.

## Implementation sketch (rough order, depends on convergence-verifier landing first)

1. Create the cluster: `~/.claude/learnings/mission-briefs/CLAUDE.md` (empty routing table to start).
2. Update `convergence-verifier.md` plan to add mission-brief-applied as the fourth intent capture source.
3. Add a "match mission-briefs" step to director skill Phase 1, before the negotiation flow. If a mission-brief matches, skip negotiation and apply.
4. Add a "mission-brief candidates" step to session-retro skill — scan session intents for promotion to mission-briefs.
5. Write the first 2-3 mission-briefs from real session patterns (the claude-config-convergence + downstream-agent-usability examples above are good seeds, distilled from this very session and prior ones).
6. Iterate as the library grows.
