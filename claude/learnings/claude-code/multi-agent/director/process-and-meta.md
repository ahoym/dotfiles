Process principles and meta-patterns for the director role: paradigm, decision discipline, scope management, escalation composition.
- **Keywords:** supervisor, decision-matrix, computable-state, orchestrate, replicate, escalation, intent, directive-timing, adjacent-items, severity-calibration, persona-attribution, dissent-vs-divergence
- **Related:** none

---

## Director-as-Supervisor Paradigm

Three orchestration patterns exist, each with different tradeoffs:

| Pattern | Workers | Communication | Visibility |
|---------|---------|---------------|------------|
| Single agent | Self | n/a | Full |
| Agent tool subagents | In-memory children | Return values, SendMessage | Partial |
| **Director + parallel `claude -p`** | Independent OS processes | Files (live.md, directives, status) | Full via stream-monitor |

The director pattern is unique: the agent generates infrastructure (bash scripts), not code. It writes runner scripts that create a fleet of `claude -p` workers, then shifts into a monitoring/steering role.

## Directives to Running Agents Are Timing-Dependent

Writing `directives.md` after launch only works if the agent hasn't passed Step 2 yet. Mitigation: re-check directives before the implement step (not just at startup), or kill + relaunch.

## Map Full Call Chain Before Patching One Layer

Multi-layer systems (assessment → runner → agent) can have the same bug manifest at multiple layers. Before fixing the first instance found, trace the full flow and identify all places the defense should exist. Patching one layer reactively leads to discovering the next gap only after testing — mapping upfront catches them in one pass.

## Director State Is Mostly Computable; Only Decisions Need Logging

Most director-layer state is derivable from worker artifacts: cycle counts from `state.md` timestamps, convergence flags from `status.md` milestones, monitoring snapshots from synthesis. The genuinely uncomputable part is the *director's decision history* — `relaunched address at 14:51 because review found 4 findings`. Append decisions to `<RUN_DIR>/director-decisions.log` on non-routine events (relaunch, escalation, convergence call, directive write), not on a periodic clock. Natural agent behavior — write when something happens, not on a heartbeat. Same shape applies one tier up: a VP managing multiple directors reads each director's decision log + the workers' `state.md` files; no per-tier state file needed.

## Active Intent Capture: Draft, Lock, Update

Capture intent at session start as a structured artifact (`<session_dir>/intents/<id>.md`), not as conversation context. Director drafts from item metadata, operator confirms or revises, result is locked. In-session scope expansion goes through an explicit update step (append revision section, log to `decisions.md`) — never silent mutation. The locked artifact survives context compaction and grounds decision-making: "is this in scope?" becomes a checkable question against the file, not a subjective recall.

## Directors Orchestrate, Never Replicate

Directors must always invoke sweep skills for assessment — never generate artifacts directly, even when the director "already knows" the PR state and metadata schema. Direct generation bypasses platform detection, skip filtering, persona discovery, and the full assessment flow. The predictability cost outweighs the performance gain: deterministic director behavior enables layering a higher orchestration tier above. The sweep skill is the single source of truth for assessment logic; the director is the single source of truth for convergence and relaunch decisions.

## Decision Matrix Is Trust, Not Suggestion

When a decision falls within the documented matrix (routine, in-scope, taste-based), execute and report — don't ask. Prompting the operator for a decision the matrix already covers forces them to re-grant trust they already codified. The pattern "I see X, the matrix says Y, should I do Y?" is worse than just doing Y and saying "did Y because X." Uncertainty is fine for genuinely ambiguous cases, but conflict resolution, convergence calls, and directive writes are explicitly routine. The decision framework exists to empower autonomous action — defaulting to "ask the human" under context pressure negates its purpose. Route through the addresser via directives, not by doing the git work directly.

## Standalone Worktree Agent for Bootstrap Infrastructure

When fixing infrastructure that the sweep flow itself depends on (e.g., the runner template), prefer `Agent(isolation: "worktree")` over generating sweep artifacts. The sweep flow would need to manually patch the very template being fixed — a chicken-and-egg. The worktree agent gets a clean checkout, implements from a fully-specified plan, and pushes a branch. The director still doesn't touch the working tree; the worktree agent is just a different execution vehicle than `claude -p` with metadata.json artifacts.

## Compose Escalation Through Existing Decision Frameworks

Secondary agents that need to escalate (verifier asking for clarification, validator finding ambiguity) should route through whatever decision framework already governs the primary loop — not build a parallel escalation channel. Verifier mid-run clarification flows through the same operator-cession framework the director uses (silent for routine, decide-with-report for partial, escalate to operator for ambiguous). Composability over duplication: one escalation surface for the operator to learn, one set of categories, one log location.

## Stage-1 Implement Bypass When All Decision Signals Present

`sweep:work-items` mandates "no prior Sweeper comment → always clarify" for stage 1. Operator explicitly invoking the sweep on a richly-specified issue is the analog of the stage-4 "explicit invocation = implicit approval" rule. Apply the same decision rule the skill uses at later stages:

| Signal | Source in issue body |
|--------|----------------------|
| Specific file targets | `## Scope` or "What's in" sections naming files/modules |
| Expected behavior change | acceptance criteria, what's-in/what's-not |
| Verification method | acceptance criteria checkboxes, test/runbook callouts |

All three present + operator explicitly named the issue → role=`implement` is decide-with-report (log to `decisions.md`). Missing any one → fall back to clarify. Skip the AskUserQuestion round-trip — the matrix already covers this.

Empirical: 4-of-4 MNQ Plz Algo issues (over-specified plan-children with full acceptance criteria) converged on attempt 1 in implement mode. None benefitted from a clarify round.

## Issue-Authoring Source Affects Bypass Reliability

The Stage-1 bypass rule checks **structural signals**, not factual accuracy of those signals. Plan-children drift slowly (body and code stay in sync via the plan); operator-authored "I noticed X" issues drift fast — file lists, counts, claims about "every other module already does Y" go stale between filing and sweep.

Empirical (5/5 operator-authored issues this session, all stage-1): every clarifier surfaced body-vs-code contradictions — positional callers were inside `indicators.py`, not tests as the body claimed; `restatements=396` was actually ≥795; "every other module uses shared logger" — already organic migration in 5+ modules; port 88 was vestigial despite the body's "HTTP interface on port 88"; the polling loop was sync `time.sleep`, not async.

Adjustment: weight clarify higher for operator-authored issues even when all three structural signals are present. One comment round-trip is cheaper than mid-implement reversal driven by a stale body claim. Plan-children remain bypass-eligible.

## Pre-Check Adjacent Items When Re-Scoping A Sweep

When the operator names a subset for a re-sweep ("re-run on #101 and #103") AND signals suggest fresh activity on nearby items (recent replies, active back-and-forth on related issues, timestamps within the last ~10 minutes), surface the gap BEFORE executing: *"I notice #100 was also replied to just now — include it?"*

Scope typos and omissions are common in fast conversations. The director has more signal than the operator in the moment (last-comment timestamps from earlier fetches, session history). Proactively verify rather than processing the literal request and then discovering the gap mid-cycle. One extra line pre-launch beats one aborted session and one operator correction.

## Review Persona ≠ Addresser Persona — Don't Auto-Propagate at Initial Handoff

Review personas (architecture, correctness, security, etc.) are the *reviewer's* finding lens. The addresser needs the *engineering* lens that matches the changed domain — often a different shape. Resist writing a director directive setting `addresser persona = first review persona` just because the review signal is fresh and uncertainty feels uncomfortable. When the assessment-time persona match isn't confident, leave the addresser at `none` and let the addresser-prompt's per-finding judgment carry the work. If cycle-1 re-review reveals weak/generic responses, *then* write a persona directive for cycle-2.

Distinct from the matrix's "Persona propagation — carry forward persona from prior runs": that rule covers *subsequent* runs on the same item. This rule covers the *initial* review→address handoff. Empirical: compound session on PRs #197/#198 left both addressers at `none`; both produced clean implementations (12 of 15 findings auto-implemented, 1 well-reasoned partial, 2 explicit no-change with context) — confirming the no-directive default earns its keep.

## Severity Calibration on Concern-Aligned, Severity-Divergent Findings

When two reviewer personas independently surface the same underlying concern but disagree on severity by 3+ levels (e.g., HIGH vs INFO), the gap usually reflects domain-knowledge asymmetry — one persona's lens encodes prior-incident severity, the other rates the surface-level change. This is **not** the dissent pattern (incompatible recommendations); it's the same recommendation calibrated to different priors.

**Merge rule:** take the higher severity with combined attribution (`HIGH (java-fintech) / INFO (correctness-reviewer): <finding>`). Don't trigger the dissent-deliberation flow — there's nothing to deliberate, just different calibration. The attribution preserves the calibration delta for the addresser; downgrading to the lower severity loses the domain signal.

Triggers the dissent flow only when one persona says "fix" and the other says "don't fix" — incompatible action, not just different urgency.

## Docs-Consolidation Sweeps Surface Gaps In The Docs Being Changed

When sweeping a PR that consolidates authoritative docs (learnings indexes, playbooks, header specs), expect workers to identify missing rules, conventions, or detection heuristics in the very files being changed. Empirical (PR #108, learnings/skills/guidelines consolidation): reviewer + addresser surfaced 7 candidates including the `**Related:**` (header, pre-load sniff) vs `## Cross-Refs` (footer, post-load lateral discovery) distinction — invisible to the docs themselves but load-bearing for the search pipeline.

**Phase 5 triage priority:** docs-consolidation sweeps produce higher-than-usual learning yield because the workers operate against the conventions they're consolidating — they have ground truth in their context. Promote these aggressively; they're the kind of insight the operator wouldn't independently discover without re-reading the entire PR.
