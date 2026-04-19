Director patterns specific to orchestrating `sweep:work-items`. Lazy-loaded — read when running `/director` for work-items mode.
- **Keywords:** director, work-items, sweep, clarify, confirm, implement, worktree, role transition, convergence per role, monitoring table, BASE_BRANCH, IMPLEMENT_ISSUES
- **Related:** ~/.claude/learnings/claude-code/multi-agent/director-patterns.md, ~/.claude/learnings/claude-code/sweep-sessions.md

---

# Work-Items Director Patterns

## Lifecycle: clarify → confirm → implement

Every issue starts at `clarify`. Implementation requires passing through `confirm` — no exceptions.

| Round outcome | Operator action | Next role |
|---------------|-----------------|-----------|
| Sweeper posted clarifying questions | Operator answers | `clarify-confirm` (restate understanding + plan) |
| Sweeper-Confirm posted plan | "implement" / "LGTM" | `implement` |
| Sweeper-Confirm posted plan | Asks for re-elaboration | `clarify-confirm` (another pass) |
| Sweeper-Confirm posted plan | Partial answer + "implement with this in mind" | `implement` (agent absorbs answer) |

**Confirm → implement decision rule:** all three of (a) specific file targets, (b) expected behavior change, (c) verification method present → implement. Any missing → another clarify-confirm.

## Convergence per role

| Role | Converged when |
|------|----------------|
| Clarifier | `comment_posted: true` |
| Confirmer | `confirmation_posted: true` |
| Implementer | `pr_opened: true` |

`milestone: errored` is NOT converged — director may write retry directives. Single-pass default: rerun only if issue updated since last pass.

## Monitoring table

| Issue | Role | State | Milestone | Worker | Worktree | PR |
|-------|------|-------|-----------|--------|----------|-----|
| #97 | implement | running | running | claude-opus-4-6 | worktrees/issue-97 | (pending) |
| #102 | clarify-confirm | completed | done | claude-sonnet-4-6 | -- | -- |

## Mixed-mode runs (clarify-confirm + implement)

Mixed runs use opus globally. `work-items-runner-template.sh` sets up worktrees only for `IMPLEMENT_ISSUES` — confirmers run from project root, implementers from per-issue worktree.

Tradeoff: mixed runs pay opus rate for everyone. Many confirmers + few implementers → split into two runners (sonnet confirms + opus implements). Few of each → single runner wins on simplicity.

## BASE_BRANCH and stacked dependencies

Each issue's metadata.json carries `BASE_BRANCH`:
- `main` → fresh worktree, PR targets main
- Dependency PR's branch (e.g., `sweep/97-tda-rename`) → worktree stacked on that branch, PR targets it (stacked PR)

**Diamond dependency:** multiple blockers with open PRs on different branches → assessment falls back to `main` and flags `⚠️ diamond dependency`. Operator should merge one blocker before stacking the dependent.

## Wrap-up: invoke `/sweep:compound-agent-learnings`

Before final summary, run `/sweep:compound-agent-learnings <RUN_DIR>` — without it, agent observations die in `tmp/`.
