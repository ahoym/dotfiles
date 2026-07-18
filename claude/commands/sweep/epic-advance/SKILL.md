---
name: epic-advance
description: "Walk a Jira epic, classify each child by state, and produce a dispatch plan + manifest + runner — emits let-it-rip.sh that delegates to sweep:address-prs / sweep:review-prs / sweep:work-items per action, with tranche-sequenced stacking support."
argument-hint: "PROJ-101 [--plan-only] [--no-stack] [--cloud=<host>]"
---

## Context
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`
- Remote: !`git remote get-url origin 2>/dev/null`
- Default cloudId: `<your-site>.atlassian.net` (replace with your site, or rely on the Phase 1 resource-discovery fallback)

# Epic Advance

Take a Jira epic, classify everything in it, and emit a dispatch plan + manifest + runner. Operator runs the runner manually:

```
/sweep:epic-advance PROJ-101    →  generates artifacts under tmp/claude-artifacts/epic-advance-PROJ-101-<ts>/
bash <RUN_DIR>/let-it-rip.sh     →  executes the dispatch
```

Three artifacts emitted per run:

- **`plan.md`** — markdown for humans (tables, dependency map, stacking tree)
- **`manifest.json`** — structured representation, consumed by the runner
- **`let-it-rip.sh`** — bash runner that executes tranches sequentially, delegating each action to its sweep:* skill

## Usage

| Form | Effect |
|---|---|
| `/sweep:epic-advance PROJ-101` | Emit plan + manifest + runner. **Review/address items default to converge mode** (single `/director review+address` loop). Operator inspects, then runs `bash <RUN_DIR>/let-it-rip.sh` |
| `/sweep:epic-advance PROJ-101 --no-converge` | Disable converge mode — review/address items dispatch as one-shot `sweep:review-prs` / `sweep:address-prs` sessions instead of a /director loop |
| `/sweep:epic-advance PROJ-101 --plan-only` | Skip runner generation — useful when you only want the plan + manifest for inspection |
| `/sweep:epic-advance PROJ-101 --no-stack` | Disable stacking — implement-tickets with open-PR blockers get deferred instead of stacked |
| `/sweep:epic-advance PROJ-101 --cloud=other.atlassian.net` | Override cloudId |
| `bash <RUN_DIR>/let-it-rip.sh --dry-run` | Print the actual claude -p invocations the runner would fire, without executing |

## Prerequisites

- Atlassian MCP available
- `glab` CLI authenticated
- Repo's origin is GitLab

## Mental model

**Tranche-sequenced dispatch.** Items are partitioned into tranches by stack level. Within a tranche, items dispatch in parallel across delegate skills. Between tranches, the runner waits for the previous tranche to terminate before starting the next. Most epics have only Tranche 0 (no same-run stacking). Tranche N>0 only exists when ticket B in this run is stacked on ticket A also in this run.

**Pure delegation.** Each action maps to exactly one sweep skill: `address-comments` → `sweep:address-prs`, `team-review` → `sweep:review-prs`, `implement` → `sweep:work-items`. The runner spawns one `claude -p` per (delegate × tranche), each session does its own assess + execute (single combined session, A1).

**Stacking via directive injection.** When ticket B is stacked on ticket A in the same run, the sweep:work-items invocation prompt for B includes a directive that tells sweep:work-items to write `directives.md` into its per-item dir for B, which the implementer reads and uses to add a "Stacked on: A — base will flip to main when its MR merges" footer to B's MR description.

**Idempotent re-runs handle drift.** State changes during a dispatch are not re-fetched mid-run. Running the dispatcher again later picks up wherever things landed; tickets that progressed get re-classified, newly-eligible work gets dispatched. Watermarking lives inside delegate skills' own state files.

**Three buckets:**
- **Active** — dispatched this run, with action + base branch + tranche resolved
- **Deferred** — explicitly held, with a reason: blocked-no-MR, diamond dependency, draft author still working
- **Skipped** — terminal classifications (merged, mr-closed, done-no-MR, draft-mr)

## Pipeline

### Phase 1: Parse args

Parse `$ARGUMENTS`:
- First positional matching `[A-Z]+-\d+` → `EPIC_KEY` (required)
- `--plan-only` → `SKIP_RUNNER=true` (skip Phase 8 runner generation)
- `--no-stack` → `NO_STACK=true`
- `--always-clarify` → `ALWAYS_CLARIFY=true` (suppress the DoR-ready bypass — every ticket goes through clarify even when DoR predicts implement)
- `--converge` (default) / `--no-converge` → `CONVERGE` defaults to `true`. When converge is on, all `team-review` + `address-comments` items in this dispatch are aggregated into a single `/director review+address --converge --prs=...` invocation that owns the review → address → review loop until convergence. `implement` items still dispatch in parallel via sweep:work-items regardless. Pass `--no-converge` to fall back to one-shot `sweep:review-prs` / `sweep:address-prs` sessions per delegate (no address follow-up loop).
- `--include-downstream` → `INCLUDE_DOWNSTREAM=true` (when unset — the default — review/address only fires on **frontier** MRs whose `target_branch` is `main` or an already-merged branch; MRs stacked on unmerged branches are demoted to deferred with reason `downstream of !<iid>` so the cycle isn't wasted on content that will shift when upstream lands. When set, all open MRs in the epic dispatch regardless of stack depth.)
- `--cloud=<host>` → `CLOUD_ID` (default `<your-site>.atlassian.net`; when no default is configured, resolve via Atlassian MCP resource discovery — `getAccessibleAtlassianResources` — and take the first accessible site)

### Phase 2: Run fetch + classify pipeline

Execute `~/.claude/skill-references/epic-fetch-classify.md` with:

- `EPIC_KEY` = parsed
- `CLOUD_ID` = parsed
- `SKIP_MRS` = `false`
- `WITH_COMMENT_THREADS` = `true` — required to split `awaiting-review` vs `review-comments-pending`

Result is an `EpicClassifyResult` (schema in the reference). All subsequent phases consume that in-memory.

### Phase 3: Resolve action per child

Map classification → action. Three actions; each maps to one delegate skill:

| Classification | Action | Target | Delegate skill |
|---|---|---|---|
| `merged` | skip | — | (terminal) |
| `mr-closed` | skip | — | (terminal — flag for triage) |
| `done-no-mr` | skip | — | (terminal — flag as orphan) |
| `draft-mr` | skip | — | (author still working) |
| `review-comments-pending` | `address-comments` | MR | `sweep:address-prs` (which uses `git:address-request-comments`) |
| `awaiting-review` | `team-review` | MR | `sweep:review-prs` (which uses `git:team-review-request`) |
| `blocked` | defer | — | (no action — surface reason) |
| `not-started` (unblocked) | `implement` | ticket | `sweep:work-items` |
| `in-progress-no-mr` (unblocked) | `implement` | ticket | `sweep:work-items` |

**No `clarify` action.** All `implement`-targeted tickets go to `sweep:work-items`, which has its own clarify → confirm → implement conversation lifecycle (driven by Sweeper-comment state, not ticket-content readiness). Re-implementing that decision here would duplicate sweep:work-items's logic. The DoR check (Phase 4) becomes **informational** — surfaced in the plan so operators see which tickets sweep:work-items is likely to clarify first vs. implement directly — but does not affect routing.

### Phase 4: Definition of Ready (informational)

For each `implement`-routed ticket, apply the Definition of Ready heuristic in `~/.claude/skill-references/definition-of-ready.md`. Capture the `verdict` + `reason` per ticket.

**DoR drives routing.** Tickets where the DoR verdict is `implement` are passed to `sweep:work-items` with the `--dor-ready=<KEY>` flag, which causes sweep:work-items to skip its always-clarify gate on first contact and route directly via the stage-3 decision rule (file targets / behavior change / verification method). Tickets where the DoR verdict is `clarify` are passed without the flag — they go through the normal `clarify → confirm → implement` cycle.

**Safety net.** sweep:work-items applies the stage-3 decision rule itself before implementing. If our DoR was a false positive (ticket looked ready but isn't), the rule fails on missing file targets / behavior / verification and sweep:work-items falls back to clarify. So an aggressive DoR doesn't produce broken implementations — at worst it costs an extra round-trip.

**Operator override.** Pass `--always-clarify` to /sweep:epic-advance to suppress the bypass entirely — every implement-routed ticket then goes through the full clarify cycle regardless of DoR verdict.

The reference defines detection patterns, output schema (`DoRResult`), and a worked example (PROJ-110).

### Phase 5: Resolve base branches + tranche assignment

For each `implement`-routed ticket, determine the base branch AND assign a tranche level. Tranches are sequential — within a tranche, items dispatch in parallel; between tranches, the runner waits for the previous tranche to complete before starting the next.

```
Tranche 0 (parallel):
  - All MR-targeted items (address-comments, team-review)
  - All implement-routed tickets with no blockers OR all blockers already merged
  - base_branch = main

Tranche N (sequential, N > 0):
  - implement-routed tickets stacked on a Tranche N-1 ticket whose MR is being created in this run
  - base_branch = the Tranche N-1 ticket's eventual sweep branch (sweep/<KEY>-<slug>)
  - Assigned only when the blocker is itself in this run; cross-run stacking still defers
```

**Stacking rules:**

```
For ticket T with blockedBy = [B1, B2, ...]:

  if NO_STACK == true:
    if any blocker has open MR or unmerged status → DEFER
    else → tranche 0, base = main

  else (stacking enabled):
    let openPRBlockers = blockers with state==opened MR (existing, not from this run)
    let mergedBlockers = blockers with state==merged MR or statusCategory==done
    let inRunBlockers = blockers that are themselves implement-routed in this dispatch

    if blockedBy empty OR all in mergedBlockers:
        tranche 0, base = main

    else if openPRBlockers.length == 1 and rest in mergedBlockers:
        tranche 0, base = openPRBlockers[0].sourceBranch
        (stacked on existing MR, not on a same-run ticket)

    else if inRunBlockers.length == 1 and rest in mergedBlockers:
        tranche = (inRunBlockers[0].tranche) + 1
        base = sweep/<inRunBlockers[0].key>-<derived-slug>
        (stacked on a same-run ticket — sequential dependency)

    else if openPRBlockers.length > 1 OR inRunBlockers.length > 1:
        DEFER (diamond — too risky to auto-stack)

    else (some blockers have no MR and aren't in this run):
        DEFER (blocker not resolved)
```

**Tranche numbering** is per-dispatch-run. Tranche 0 is always non-empty (always at least one MR-targeted action or unblocked implement). Tranche N (N>0) exists only when same-run stacking is detected. Most epics have only Tranche 0.

This logic is documented also in `~/.claude/skill-references/jira-issue-mapping.md` § Base-branch determination for stacking. When an item gets deferred, capture the human-readable reason and surface in the Deferred section.

### Phase 5.5: Frontier filter (review/address only)

Skip when `INCLUDE_DOWNSTREAM=true` (the operator opted into reviewing the full stack).

For each active item with `action ∈ {team-review, address-comments}`, classify the underlying MR as **frontier** or **downstream**:

```
For MR M:
  if M.target_branch == repo.default_branch:
    M.frontier = true
    continue

  # Look up the target branch's merged-state. Reuse data already fetched in
  # Phase 4 when possible; otherwise issue a single glab call:
  #   glab api projects/:id/repository/branches/<url-encoded target> -R <project>
  # and cache by branch name. 404 → treat as removed; assume merged-then-deleted
  # (the common cause).
  branch_state = lookup_or_fetch(M.target_branch)

  if branch_state.merged or branch_state == 404:
    M.frontier = true
  else:
    M.frontier = false
    # Find the open MR (if any) whose source_branch == M.target_branch — that's
    # the upstream blocker. Search the full open-MR set, not just in-epic
    # children, since blockers can be sibling-of-epic foundational tickets.
    M.blocker_mr = lookup_open_mr_with_source(M.target_branch)
```

**Demote downstream items.** When `M.frontier == false` and `INCLUDE_DOWNSTREAM=false`:

- Move the item from `active` to `deferred`
- Set the deferral reason: `downstream of !<blocker_iid>` (or `downstream of unmerged branch <name> — no open MR found` when the blocker can't be located)
- Keep the per-item directory; downstream items still get `metadata.json` for inspection but are not in any tranche

**Implement-routed items are unaffected.** Frontier reasoning is about which existing MRs to *review* — implement creates new code and is independent. (sweep:work-items handles its own stacking via base-branch selection in Phase 5.)

**Why default-on:** reviewing a downstream MR before its base lands burns cycles on content that will shift after rebase. The reviewer's findings may go stale; the addresser may end up patching code that gets reorganized. Deferring downstream review until the chain unwinds is the cheaper default. Pass `--include-downstream` when you explicitly want eyes on the full stack — e.g., for a coordinated review pass before any merge.

### Phase 5.6: Render pre-artifact baseline

Before writing any files, render a baseline view to stdout so the operator has a snapshot of where the epic stands while later phases generate artifacts. Two parts, in this order:

**1. Stacking / dependency ASCII diagram.** Same shape as the `## Stacking chains` section in Phase 6's plan, but rendered now (not after artifact write). Show:
- Top-level node = `main`
- Open MRs in the chain — both in-epic and out-of-epic blockers (e.g., sibling-of-epic foundational MRs that downstream items target)
- Each node tagged with its short status icon (`✓` merged · `▶` active in this dispatch · `⏸` deferred · `⊘` skipped · `🔒` open MR out-of-epic)
- Indent children by their target_branch parent so the operator can see the chain depth at a glance
- When the epic has no stacking (everything targets `main`), render a flat list rooted at `main` instead

**2. Per-child status table.** One row per child of the epic. Columns:

| Ticket | Type | Status | MR | Classification | Action |
|---|---|---|---|---|---|

- `Ticket` — `<KEY>`
- `Type` — Story/Task/Bug/Subtask
- `Status` — Jira status name (e.g., `To Do`, `In Progress`, `Done`)
- `MR` — `!<iid> (<state>)` if linked, `—` if none
- `Classification` — the taxonomy label from `mr-state-classification.md`
- `Action` — the resolved action (`team-review` / `address-comments` / `implement` / `defer: <reason>` / `skip: <reason>`)

Sort: active items first (by tranche then key), then deferred (by reason category), then skipped.

**Then proceed to Phase 6** (artifact writes). The baseline view is for reading only — don't write it to a file (Phase 6's plan.md already serializes equivalent content).

This phase is mandatory in default mode AND `--plan-only` mode. The point is to give operators a fast preview before any disk I/O so they can interrupt early if the classification surprised them.

### Phase 6: Render dispatch plan

Output to stdout AND to `<RUN_DIR>/plan.md`. Compute `<RUN_DIR>` once at the start of the write phases: `tmp/claude-artifacts/epic-advance-<EPIC_KEY>-<ts>` where `<ts>` comes from a separate Bash call: `date +%Y-%m-%d-%H%M`. Reuse the same `<RUN_DIR>` for the manifest in Phase 7.

Plan structure:

```markdown
# Dispatch Plan: <EPIC_KEY> — <summary>

**Generated:** <ISO timestamp>
**Mode:** plan-only · stacking <enabled|disabled> · downstream <filtered|included>

## Summary

<N> children · <A> active · <D> deferred · <S> skipped

Active breakdown: <X> address-comments · <Y> team-review · <Z> implement
Tranches: 0 (<N> parallel)<, 1 (<M> sequential after T0) — only if stacking in play>

<When the frontier filter demoted any items, append:>
Frontier filter: <K> downstream review/address items deferred. Pass `--include-downstream` to dispatch on the full stack.

## Active (<N>)

| Ticket | Type | Summary | Action | Target | Base | T | Notes |
|---|---|---|---|---|---|---|---|
| PROJ-121 | Story | Fix loader metrics | address-comments | !42 | (MR branch) | 0 | 2 unresolved threads from @reviewer-a |
| PROJ-125 | Story | Wire metrics aspect | team-review | !55 | (MR branch) | 0 | open, no reviewers requested |
| PROJ-131 | Task | Add OpenAPI sample endpoint | implement | ticket | main | 0 | DoR: implement (clear AC + slice design) |
| PROJ-132 | Task | Define Vendor SPI | implement | ticket | main | 0 | DoR: clarify (vague AC, open API Q) — sweep:work-items likely clarifies first |
| PROJ-133 | Task | Implement Vendor SPI | implement | ticket | sweep/PROJ-131-... | 1 | stacked on PROJ-131 |

## Deferred (<D>)

| Ticket | Classification | Reason |
|---|---|---|
| PROJ-134 | not-started | diamond dependency — blocked by PROJ-131 + PROJ-132, planned MRs on different branches |
| PROJ-140 | not-started | blocked by PROJ-131 (no MR yet — cannot stack) |
| PROJ-145 | blocked | blocker OTHER-99 is out-of-epic, not resolved |
| PROJ-113 | awaiting-review | downstream of !135 (target=feat/PROJ-103-...) — frontier filter, pass --include-downstream to dispatch |
| PROJ-114 | review-comments-pending | downstream of !139 (target=sweep/PROJ-113-...) — frontier filter |

## Skipped (<S>)

- **Merged:** PROJ-121, PROJ-122, PROJ-123 (3)
- **Draft author still working:** PROJ-114 (!49, last updated 21d ago — flagged for stale-draft check)
- **Closed without merge:** PROJ-130 (!51 — flagged for triage)
- **Done-no-MR (orphan):** PROJ-113 — verify code lives elsewhere

## Dependency map

```
Legend: ✓ merged · ▶ active · ⏸ deferred · ⊘ skip · → blocks

  ✓ PROJ-102 SPI definition            →  ▶ PROJ-110, ▶ PROJ-111
  ✓ PROJ-103 Cache skeleton            →  ▶ PROJ-110
  ▶ PROJ-110 DbLoader                  →  ⏸ PROJ-112
  ▶ PROJ-111 InMemoryLoader            →  ⏸ PROJ-112
  ⏸ PROJ-112 lookups (diamond — blocked by 110 + 111 on different branches)
  ⊘ PROJ-113 done-no-MR — orphan
```

Render rules:
- One row per ticket. Roots (no blockers in this epic) come first; deeper dependents follow.
- Status icon left-aligns ticket key + summary. Right side shows what the ticket blocks (`→ <key>`).
- Tickets with no blockers AND no blocks (isolated) appear in their own group at the end.
- Truncate summary at ~30 chars to keep alignment readable.

## Stacking chains

(Only render this section when at least one active ticket has a non-`main` base branch.)

```
main
 ├── feat/sweep/PROJ-102-spi (!42, opened)
 │    └── ▶ PROJ-110 DbLoader  (stacked — rebase when !42 merges)
 └── ▶ PROJ-111 InMemoryLoader  (base: main)
```

Render rules:
- Top-level node is `main`.
- Each child is either an open MR's source branch (with MR ref) or a new active ticket's planned branch.
- Stacked tickets nest under their base MR's branch. Note in parens: `(stacked — rebase when !X merges)`.
- Tickets without stacking dependencies attach directly to `main`.
- Skip this section entirely when no stacking is in play — it's noise otherwise.

## Stacking notes

(Only if any active ticket has a non-`main` base branch.)

- PROJ-133 → stacked on PROJ-131 (!?). When !? merges:
  - PROJ-133's MR target branch flips to `main`
  - PROJ-133's branch needs rebase onto `main`
  - The PROJ-133 implement-runner will add `Stacked on: !? — base will flip to main when !? merges` to the MR description (auto-flag, option b)
  - Operator runs `/git:cascade-rebase` or equivalent when the base merges

## Concurrency note

When this plan is dispatched (next slice), all <A> active actions fire in parallel subject to a concurrency cap (default 5). State drift during the run is not re-fetched mid-run; re-running the dispatcher later picks up new state.
```

### Phase 7: Emit manifest

Always write `<RUN_DIR>/manifest.json` with the schema below — the manifest is the structured representation of the same plan rendered in `plan.md`. The runner-generation slice will consume it directly; this slice exists so the schema can be validated against real epic data first.

**Live-fetch caveat applies** — the manifest is a snapshot at time of generation; the runner re-validates per-item state at dispatch start. Re-run epic-advance to refresh.

#### Manifest schema

```json
{
  "epic": {
    "key": "PROJ-101",
    "summary": "...",
    "url": "https://<your-site>.atlassian.net/browse/PROJ-101",
    "status": "In Progress"
  },
  "generated_at": "<ISO 8601>",
  "run_dir": "<absolute path>",
  "cloud_id": "<your-site>.atlassian.net",
  "repo": {
    "project_path": "<gitlab project path, e.g. <group>/<project>>",
    "default_branch": "main"
  },
  "stacking_enabled": true,
  "include_downstream": false,

  "stats": {
    "total": 12,
    "active": 8,
    "deferred": 2,
    "skipped": 2,
    "by_action": { "address-comments": 2, "team-review": 1, "implement": 5 },
    "frontier_filtered": 0
  },

  "tranches": [
    {
      "level": 0,
      "items": ["PROJ-121", "PROJ-122", "PROJ-125", "PROJ-131", "PROJ-132"]
    },
    {
      "level": 1,
      "items": ["PROJ-133"]
    }
  ],

  "active": [
    {
      "ticket_key": "PROJ-121",
      "ticket_url": "...",
      "summary": "Fix loader metrics",
      "labels": ["backend"],
      "action": "address-comments",
      "delegate_skill": "sweep:address-prs",
      "delegate_args": ["!42"],
      "target": { "type": "mr", "iid": 42, "url": "...", "project_path": "..." },
      "base_branch": "main",
      "frontier": true,
      "blocker_mr": null,
      "tranche": 0,
      "stacking": null
    },
    {
      "ticket_key": "PROJ-131",
      "ticket_url": "...",
      "summary": "Add OpenAPI sample endpoint",
      "labels": ["api"],
      "action": "implement",
      "delegate_skill": "sweep:work-items",
      "delegate_args": ["PROJ-131"],
      "target": { "type": "ticket", "key": "PROJ-131" },
      "base_branch": "main",
      "tranche": 0,
      "stacking": null,
      "dor": { "verdict": "implement", "reason": "Concrete AC + slice design; no blockers" }
    },
    {
      "ticket_key": "PROJ-132",
      "ticket_url": "...",
      "summary": "Define Vendor SPI",
      "labels": ["api"],
      "action": "implement",
      "delegate_skill": "sweep:work-items",
      "delegate_args": ["PROJ-132"],
      "target": { "type": "ticket", "key": "PROJ-132" },
      "base_branch": "main",
      "tranche": 0,
      "stacking": null,
      "dor": { "verdict": "clarify", "reason": "AC vague + no slice-design + open API question with no recommendation. sweep:work-items will likely clarify first." }
    },
    {
      "ticket_key": "PROJ-133",
      "ticket_url": "...",
      "summary": "Implement Vendor SPI",
      "labels": ["api"],
      "action": "implement",
      "delegate_skill": "sweep:work-items",
      "delegate_args": ["PROJ-133"],
      "target": { "type": "ticket", "key": "PROJ-133" },
      "base_branch": "sweep/PROJ-131-add-openapi-sample",
      "tranche": 1,
      "stacking": {
        "stacked_on_ticket": "PROJ-131",
        "stacked_on_mr_iid": null,
        "auto_flag_text": "Stacked on: PROJ-131 — base will flip to main when its MR merges"
      },
      "dor": { "verdict": "implement", "reason": "..." }
    }
  ],

  "deferred": [
    {
      "ticket_key": "PROJ-134",
      "summary": "...",
      "classification": "not-started",
      "reason": "diamond dependency — blocked by PROJ-131 + PROJ-132, planned MRs on different branches"
    }
  ],

  "skipped": [
    { "ticket_key": "PROJ-102", "reason": "merged" },
    { "ticket_key": "PROJ-113", "reason": "done-no-MR (orphan)" }
  ]
}
```

#### Schema notes

- **`tranches[]`** drives sequential execution. The runner processes tranche 0 fully (waits for all sub-processes to terminate), then tranche 1, etc. Within a tranche, items dispatch in parallel across delegates.
- **`active[]`** is the flat detail list. Each item carries `tranche` so the runner can resolve the dispatch order without cross-referencing.
- **No `concurrency` field.** Each delegate skill manages its own concurrency. The runner doesn't impose an outer cap.
- **No `mode` field on implement actions.** All `implement`-routed tickets go to `sweep:work-items`, which decides clarify-vs-implement at runtime via its own conversation-stage logic. The `dor` field on each item is **informational** — it tells the operator what we expect sweep:work-items to do, but doesn't bind the runner.
- **`delegate_args`** is the argument list the runner passes to the delegate skill. MR-targeting actions: `["!<iid>"]`. Ticket-targeting actions: `["<KEY>"]`. The runner may aggregate same-delegate items into a single invocation (e.g., `["PROJ-131", "PROJ-132"]` to one sweep:work-items call) or spawn one per item — implementation choice for the runner-generation slice.
- **`stacking.stacked_on_mr_iid`** is `null` when the blocker's MR doesn't yet exist (because the blocker is being created in this same run). The runner constructs the auto-flag footer at MR-creation time using the actual IID. The `auto_flag_text` field carries the templated text minus the IID.
- **`base_branch` for in-run stacked items** uses the predicted sweep branch convention: `sweep/<BLOCKER_KEY>-<slug>`. The runner verifies this matches the actual branch sweep:work-items creates; if convention differs, runner-generation slice handles the mismatch.
- **`frontier`** — populated only on MR-targeting items (`action ∈ {team-review, address-comments}`). `true` when `target_branch` is the repo default branch or a merged branch; `false` otherwise. When `false` and `INCLUDE_DOWNSTREAM=false`, the item lives in `deferred[]`, not `active[]`. `blocker_mr` (sibling field) carries `{ "iid": <int>, "project_path": "<path>" }` of the open upstream MR when the blocker is locatable; `null` when the target branch is unmerged but no source MR was found.
- **`stats.frontier_filtered`** — count of review/address items demoted from active to deferred by the frontier filter this run. Use to surface "you can dispatch on N more MRs by passing `--include-downstream`" hints.
- The schema is intentionally close to but not identical to `sweep:work-items`'s manifest. Common fields (ticket_key, target, base_branch) match; additions (`action`, `delegate_skill`, `tranche`, `stacking`, `dor`, `frontier`, `blocker_mr`) are epic-advance-specific.

#### Per-item directories

Create `<RUN_DIR>/<TICKET_KEY>/` for each active item, populated with:

- **`metadata.json`** — slim per-item record carrying everything the runner needs to dispatch this item without cross-referencing the manifest:
  ```json
  {
    "ticket_key": "PROJ-133",
    "summary": "Implement Vendor SPI",
    "url": "...",
    "action": "implement",
    "delegate_skill": "sweep:work-items",
    "delegate_args": ["PROJ-133"],
    "target": { "type": "ticket", "key": "PROJ-133" },
    "base_branch": "sweep/PROJ-131-add-openapi-sample",
    "tranche": 1,
    "stacking": {
      "stacked_on_ticket": "PROJ-131",
      "stacked_on_mr_iid": null,
      "auto_flag_text": "Stacked on: PROJ-131 — base will flip to main when its MR merges"
    },
    "dor": { "verdict": "implement", "reason": "..." }
  }
  ```

- **`status.md`** — runner-managed milestone tracker. Initial content (queued state):
  ```markdown
  ticket: PROJ-133
  tranche: 1
  state: queued
  delegate_skill: sweep:work-items
  delegate_run_dir:
  started_at:
  ended_at:
  exit_code:
  notes:
  ```

  Runner updates `state` through `running` → `done`/`failed` and fills timestamps + `delegate_run_dir` (the path where the delegate skill wrote ITS sub-artifacts).

- **`output.log`** — runner-captured stdout+stderr from the delegate's `claude -p` session for items in this tranche-group. (The sweep skill itself runs many sub-`claude -p` sessions; their per-item logs live in the sub-RUN_DIR and are pointed to from this file.)

The per-item dir is the operator's debugging entry point. From here they can navigate to `delegate_run_dir` for details when something goes wrong.

#### Inspection-only `data.json`

Also write `<RUN_DIR>/data.json` with the full `EpicClassifyResult` for human inspection. Same caveat as epic-state — never re-input.

### Phase 8: Generate runner

Skip this phase if `SKIP_RUNNER=true` (i.e., `--plan-only` was passed).

Write `<RUN_DIR>/let-it-rip.sh` with the template below. The runner:

1. Reads `manifest.json` for tranche structure and per-item details
2. Loops tranches sequentially (Tranche 0 → 1 → ...)
3. Within each tranche, spawns one `claude -p` per (delegate × tranche) combination in parallel via `& + wait`
4. Each `claude -p` does the full assess-then-execute flow for its delegate skill (single combined session — A1 design)
5. For stacked items, the prompt to `sweep:work-items` includes a **directive injection step**: write `directives.md` into the sub-RUN_DIR's per-item dir telling the implementer to add the auto-flag footer to the MR description (B2 design)
6. Updates `<RUN_DIR>/<TICKET_KEY>/status.md` as items progress

Mark the file executable: `chmod +x <RUN_DIR>/let-it-rip.sh`.

**Template substitutions** to apply when writing the runner: `<EPIC_KEY>` (parsed in Phase 1), `<ISO timestamp>` (run start time), `<ALWAYS_CLARIFY_VALUE>` (literal `true` or `false` from the parsed `--always-clarify` flag — defaults to `false`), `<CONVERGE_VALUE>` (literal `true` or `false` from the parsed converge flag — **defaults to `true`**; pass `--no-converge` to skill-time to bake `false`). Operators can also flip both flags at run-time by passing `--always-clarify`, `--converge`, or `--no-converge` to the generated runner.

**Converge mode behavior:** when `CONVERGE=true`, the dispatch loop aggregates every active item with `action ∈ {team-review, address-comments}` into a single `/director review+address --converge --prs=!139,!140,...` group rather than spawning separate `sweep:review-prs` / `sweep:address-prs` sessions per delegate. `sweep:work-items` (implement) is unaffected and still dispatches in parallel. The `--prs=` list passed to director is authoritative — it pins director to the MR set this epic-advance run identified, so director won't widen scope to unrelated MRs in the repo. Convergence semantics (when the loop terminates) are owned by `/director` — refer to its sweep-mode.md.

#### Runner template

The runner is generated dynamically at skill-run-time using the manifest data. The structure is bash + jq.

```bash
#!/bin/bash
# Generated by /sweep:epic-advance for epic <EPIC_KEY> at <ISO timestamp>
# Run: bash let-it-rip.sh        — execute dispatch
#      bash let-it-rip.sh --dry-run  — print claude -p invocations without executing

set -u
RUN_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="$RUN_DIR/manifest.json"
DRY_RUN=0
ALWAYS_CLARIFY=<ALWAYS_CLARIFY_VALUE>   # baked at skill-time; runtime override below
CONVERGE=<CONVERGE_VALUE>               # baked at skill-time; runtime override below
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --always-clarify) ALWAYS_CLARIFY=true ;;
    --converge) CONVERGE=true ;;
    --no-converge) CONVERGE=false ;;
  esac
done

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$RUN_DIR/run.log"; }

update_status() {
  local key=$1 state=$2 extra=${3:-}
  local f="$RUN_DIR/$key/status.md"
  local ts="$(date -Iseconds)"
  case "$state" in
    running) sed -i.bak "s/^state:.*/state: running/; s/^started_at:.*/started_at: $ts/" "$f" ;;
    done|failed)
      sed -i.bak "s/^state:.*/state: $state/; s/^ended_at:.*/ended_at: $ts/" "$f"
      [[ -n "$extra" ]] && sed -i.bak "s|^delegate_run_dir:.*|delegate_run_dir: $extra|" "$f"
      ;;
  esac
  rm -f "$f.bak"
}

# Build the prompt for a given delegate + ticket-list + tranche.
# Takes ticket_keys (for manifest lookups + per-item-dir resolution); the
# delegate_args fed into the prompt are resolved from the manifest. They differ
# for MR-targeting delegates (delegate_args = "!<iid>", ticket_key = "PROJ-<n>").
build_prompt() {
  local delegate=$1; shift
  local tranche=$1; shift
  local ticket_keys=("$@")

  # Resolve delegate_args ordered the same as ticket_keys.
  local delegate_args=()
  local key
  for key in "${ticket_keys[@]}"; do
    local arg
    arg=$(jq -r --arg k "$key" \
      '.active[] | select(.ticket_key == $k) | .delegate_args[0]' "$MANIFEST")
    delegate_args+=("$arg")
  done

  case "$delegate" in
    sweep:address-prs|sweep:review-prs)
      cat <<EOF
Run /$delegate ${delegate_args[*]}

After it generates its run dir (you'll see "Artifacts written to <PATH>"), run:
  bash <PATH>/let-it-rip.sh

Then capture the <PATH> and report it back as the last line of your output, prefixed with DELEGATE_RUN_DIR=.
EOF
      ;;

    director)
      # Aggregated review+address loop. delegate_args is the MR-IID list
      # (!139 !140 ...) — pass as a comma-separated --prs= for /director.
      local prs_csv
      prs_csv=$(IFS=,; echo "${delegate_args[*]}")
      cat <<EOF
Run /director review+address --converge --prs=$prs_csv

/director will own the convergence loop (review → address → review → ... until its sweep-mode convergence rule fires). When /director exits, capture the session directory it created (typically tmp/claude-artifacts/director-sessions/<timestamp>/) and report it as the last line of your output, prefixed with DELEGATE_RUN_DIR=.
EOF
      ;;

    sweep:work-items)
      # Build directive lines for stacked tickets in this tranche-group.
      # NOTE: never name the per-item directory (e.g. `issue-$key/` or `pr-$key/`)
      # in the directive payload — that path convention is sweep:work-items's
      # internal choice, and it varies by role (clarify uses `pr-`, implement
      # uses `issue-`). Naming a path here implicitly hints a role to the
      # parent assessor and bypasses sweep:work-items's conversation-stage gate.
      # Phrase the instruction so the parent resolves the actual per-item dir
      # at runtime from sweep:work-items's manifest.
      local directive_block=""
      for key in "${ticket_keys[@]}"; do
        local stack_text
        stack_text=$(jq -r --arg k "$key" \
          '.active[] | select(.ticket_key == $k) | .stacking.auto_flag_text // empty' "$MANIFEST")
        if [[ -n "$stack_text" ]]; then
          directive_block+="
After /sweep:work-items generates its run dir and per-item directories, but BEFORE running its let-it-rip.sh:

Locate the per-item directory it created for $key (read its manifest.json — the directory naming varies by role; do not assume \`issue-\` or \`pr-\`). Write a \`directives.md\` file inside that directory with this content:

\`\`\`
Stacking directive for $key:

When creating the MR description, include this section at the bottom:

## Stack
$stack_text
\`\`\`
"
        fi
      done

      # Build --dor-ready=KEY1,KEY2 listing the tickets in this group whose DoR
      # verdict is `implement`. sweep:work-items uses this to skip its always-clarify
      # gate for those keys and apply the stage-3 decision rule directly. Suppressed
      # when ALWAYS_CLARIFY=true.
      local dor_ready_flag=""
      if [[ "${ALWAYS_CLARIFY:-false}" != "true" ]]; then
        local dor_ready_keys=""
        for key in "${ticket_keys[@]}"; do
          local verdict
          verdict=$(jq -r --arg k "$key" \
            '.active[] | select(.ticket_key == $k) | .dor.verdict // empty' "$MANIFEST")
          if [[ "$verdict" == "implement" ]]; then
            [[ -n "$dor_ready_keys" ]] && dor_ready_keys+=","
            dor_ready_keys+="$key"
          fi
        done
        [[ -n "$dor_ready_keys" ]] && dor_ready_flag=" --dor-ready=$dor_ready_keys"
      fi

      cat <<EOF
Run /sweep:work-items ${delegate_args[*]}$dor_ready_flag
$directive_block
After /sweep:work-items generates its run dir (you'll see "Artifacts written to <PATH>"), run:
  bash <PATH>/let-it-rip.sh

Then report the <PATH> as the last line of your output, prefixed with DELEGATE_RUN_DIR=.
EOF
      ;;
  esac
}

# Dispatch one (delegate × tranche) combination.
# Takes ticket_keys: per-item directories and update_status are keyed on
# ticket_key. delegate_args (e.g. !<iid>) are resolved inside build_prompt.
dispatch_group() {
  local delegate=$1
  local tranche=$2
  shift 2
  local ticket_keys=("$@")

  local group_id="${delegate//:/-}-tranche-$tranche"
  local log_file="$RUN_DIR/$group_id.log"
  local prompt
  prompt=$(build_prompt "$delegate" "$tranche" "${ticket_keys[@]}")

  if (( DRY_RUN )); then
    echo "===== $group_id ====="
    echo "$prompt"
    echo "====="
    return 0
  fi

  log "starting $group_id (${#ticket_keys[@]} items: ${ticket_keys[*]})"
  for k in "${ticket_keys[@]}"; do update_status "$k" running; done

  # Run claude -p with the assembled prompt
  local exit_code=0
  echo "$prompt" | claude -p > "$log_file" 2>&1 || exit_code=$?

  # Extract DELEGATE_RUN_DIR= line from output
  local sub_dir
  sub_dir=$(grep -oE 'DELEGATE_RUN_DIR=.*' "$log_file" | tail -1 | cut -d= -f2- || true)

  if (( exit_code == 0 )); then
    log "done $group_id"
    for k in "${ticket_keys[@]}"; do update_status "$k" done "$sub_dir"; done
  else
    log "FAILED $group_id (exit $exit_code) — see $log_file"
    for k in "${ticket_keys[@]}"; do update_status "$k" failed "$sub_dir"; done
  fi
}

# Main loop: walk tranches sequentially
TRANCHE_LEVELS=$(jq -r '.tranches[].level' "$MANIFEST" | sort -n)

for level in $TRANCHE_LEVELS; do
  log "===== Tranche $level ====="
  pids=()

  # When CONVERGE=true, fold sweep:address-prs + sweep:review-prs items into a
  # single virtual delegate (`director`) so the runner spawns one /director
  # session that owns the review→address loop. sweep:work-items still
  # dispatches separately.
  if [[ "$CONVERGE" == "true" ]]; then
    delegates=(director sweep:work-items)
  else
    delegates=(sweep:address-prs sweep:review-prs sweep:work-items)
  fi

  for delegate in "${delegates[@]}"; do
    # Get ticket_keys for this (delegate, tranche). We pass keys (not delegate_args)
    # because per-item directories and update_status are keyed on ticket_key;
    # build_prompt resolves the actual delegate_args from the manifest.
    if [[ "$delegate" == "director" ]]; then
      mapfile -t ticket_keys < <(
        jq -r --argjson lvl "$level" \
          '.active[]
             | select(.tranche == $lvl)
             | select(.delegate_skill == "sweep:address-prs" or .delegate_skill == "sweep:review-prs")
             | .ticket_key' \
          "$MANIFEST"
      )
    else
      mapfile -t ticket_keys < <(
        jq -r --argjson lvl "$level" --arg del "$delegate" \
          '.active[] | select(.tranche == $lvl) | select(.delegate_skill == $del) | .ticket_key' \
          "$MANIFEST"
      )
    fi

    if (( ${#ticket_keys[@]} > 0 )); then
      dispatch_group "$delegate" "$level" "${ticket_keys[@]}" &
      pids+=($!)
    fi
  done

  # Wait for all delegates in this tranche.
  # Note `${pids[@]:-}` — bash 3.2 (macOS default) treats `${arr[@]}` on an
  # empty declared array as unbound under `set -u`, which would crash this
  # loop on tranches where no delegate had work.
  for pid in "${pids[@]:-}"; do
    [[ -z "$pid" ]] && continue
    wait "$pid" || log "WARN: pid $pid in tranche $level returned non-zero"
  done

  # Dry-run never produces `state: done`, so skip the "any-success" gate
  # and let the preview walk every tranche.
  if (( DRY_RUN )); then
    continue
  fi

  # Decide whether to proceed to next tranche
  any_done=0
  while IFS= read -r k; do
    if grep -q '^state: done' "$RUN_DIR/$k/status.md" 2>/dev/null; then
      any_done=1
      break
    fi
  done < <(jq -r --argjson lvl "$level" '.active[] | select(.tranche == $lvl) | .ticket_key' "$MANIFEST")

  if (( any_done )); then
    log "Tranche $level: at least one success, proceeding"
  else
    log "Tranche $level: NO successes — halting before subsequent tranches"
    break
  fi
done

log "Dispatch complete. See per-item status.md files for results."
```

#### Runner template notes

- **Single `claude -p` per (delegate × tranche)**, not per item. The delegate skill aggregates items into one assessment + sub-runner.
- **Inline prompt construction** — `build_prompt` reads stacking metadata from manifest at runtime. Stacked items get a directive-injection step prepended to their `claude -p` prompt.
- **`DELEGATE_RUN_DIR=...`** sentinel — the runner expects each `claude -p` to print this line as its last output, so the runner can record where the delegate's sub-artifacts live. The build_prompt instructs the session to do this.
- **`--dry-run`** prints the assembled prompts without executing — operator can verify wording before paying for a real run.
- **Failure isolation** — a failed `claude -p` doesn't halt the tranche; other delegates in the same tranche continue. But if NO item succeeded in a tranche, the runner halts before subsequent tranches (likely a systemic problem).
- **No runtime concurrency cap** — confirmed earlier; each delegate manages its own concurrency internally.
- **`jq` and `claude -p` must be on PATH.** The runner doesn't check; if missing, bash will surface the error.

#### Permissions to pre-register (operator)

The runner runs as a top-level bash script invoked by the operator. It does NOT go through Claude Code's permission system itself. But the `claude -p` sub-sessions it spawns DO need permissions, which they read from `~/.claude/settings.json`. The patterns each delegate skill needs are documented in those skills' SKILL.md files (sweep:address-prs, sweep:review-prs, sweep:work-items). Verify those are set before running.

### Phase 9: Announce

Two formats based on `SKIP_RUNNER`:

**Default (runner generated):**

```
Epic <KEY>: <A> active · <D> deferred · <S> skipped.
Mode: <converge | one-shot>

Plan:        <RUN_DIR>/plan.md
Manifest:    <RUN_DIR>/manifest.json
Runner:      <RUN_DIR>/let-it-rip.sh
Per-item:    <RUN_DIR>/<TICKET_KEY>/  (metadata.json + status.md per item)

Tranches:
  Tranche 0: <N> items (parallel) — <breakdown by delegate>
  Tranche 1: <M> items (sequential after Tranche 0) — <breakdown>  [only if stacking in play]

Active breakdown by delegate:
  <one-shot mode:>
    sweep:address-prs   <N> items
    sweep:review-prs    <M> items
    sweep:work-items    <K> items
  <converge mode:>
    director (review+address loop)   <N+M> items
    sweep:work-items                 <K> items

To preview:    bash <RUN_DIR>/let-it-rip.sh --dry-run
To execute:    bash <RUN_DIR>/let-it-rip.sh
To monitor:    watch -n 5 'find <RUN_DIR> -name status.md | xargs grep ^state:'
```

In converge mode, the director session writes its own session dir under `tmp/claude-artifacts/director-sessions/<ts>/`. The runner records that path into each per-item `status.md` as `delegate_run_dir:` once the director session reports completion via the `DELEGATE_RUN_DIR=` sentinel.

#### Then immediately render the "let it rip" preview

After the announce block, render a concise preview of what `bash let-it-rip.sh` will stage. The operator's primary interest is **what tasks are queued and what each one will do** — not orchestration internals, cost, or alternatives. Two parts:

1. **Headline** — one short sentence: `**N task(s) staged across <T> tranche(s).**` For trivial dispatches: `**One task staged.**` Don't elaborate on the (delegate × tranche) execution model unless asked — operators care about tasks, not session shape.

2. **Staged tasks table** — one row per active item (NOT per delegate-group). Columns:

   | T | Ticket | Summary | Action |
   |---|---|---|---|

   - `T` — tranche level
   - `Ticket` — `<KEY>` for implement, `<KEY> / !<iid>` for review/address actions
   - `Summary` — the ticket's one-liner from the manifest (truncate at ~60 chars to keep alignment readable)
   - `Action` — the human-readable action: `Run team review on !<iid>`, `Address N unresolved threads on !<iid>`, `Implement <KEY>` (or `Clarify then implement <KEY>` when DoR verdict is `clarify`).

That's it. Do not include: per-delegate trace, cost estimates, reversibility notes, alternative-flag suggestions, deferred/skipped breakdowns. The plan.md and manifest already cover deferred/skipped — operators who want that detail open the plan.

Skip the preview entirely when `SKIP_RUNNER=true` (`--plan-only`) — there's no runner to preview.

**`--plan-only` (runner skipped):**

```
Epic <KEY>: <A> active · <D> deferred · <S> skipped.

Plan:        <RUN_DIR>/plan.md
Manifest:    <RUN_DIR>/manifest.json
(plan-only — let-it-rip.sh not generated)

Re-run without --plan-only to generate the runner when ready.
```

Stop.

## Cross-Refs

- `~/.claude/skill-references/epic-fetch-classify.md` — fetch + classify pipeline
- `~/.claude/skill-references/jira-issue-mapping.md` — state mapping, blocked-by, base-branch determination
- `~/.claude/skill-references/mr-state-classification.md` — classification taxonomy
- `~/.claude/skill-references/definition-of-ready.md` — DoR heuristic for `implement` vs `clarify` routing

## Out of scope

- **No mid-run re-fetch.** State drift is handled by re-running the skill, not by within-run re-classification. Tranches re-classify implicitly via fresh runs.
- **No automatic rebase.** Stacked MRs are flagged in their own descriptions (auto-flag via directives.md injection) — operator triggers rebase manually when the base merges. A separate `/sweep:cascade-watcher` skill could automate this in future.
- **No GitHub support.** GitLab-only.
- **No comment posting from this skill directly.** This skill writes manifest + runner; the delegate skills (sweep:address-prs etc.) and their inner runners do the actual Jira/GitLab writes.
- **No automatic execution.** Operator runs `bash let-it-rip.sh` manually after inspecting plan/manifest. Matches existing sweep convention.

## Implementation notes

- **DoR is fuzzy by design.** The reference encodes string-matching heuristics, not semantic analysis. False positives in either direction are acceptable — `clarify` is safe (extra step), and `implement` false-positives are recoverable: the implementer-runner re-applies DoR on full ticket content and can fall back to clarify if its read disagrees with the dispatcher's.
- **Diamond dependency is the conservative call.** When in doubt, defer. Stacking on the wrong base creates rebase pain that's worse than a one-day delay.
- **Plan ordering:** within Active, sort by action group (address-comments → team-review → implement → clarify) then by ticket key. Deferred sorts by reason category then key.
