---
description: "Canonical Jira issue field mapping: state normalization via statusCategory and blocked-by detection via issuelinks. Consumed by sweep:work-items/platform-jira.md, epic-state, and the future epic-advance dispatcher."
---

# Jira Issue Mapping

Canonical rules for normalizing Jira issue state and resolving blocked-by relationships across skills that operate on Jira tickets. Skills reference this file rather than re-deriving the rules.

## State mapping

Use `fields.status.statusCategory.key`, **not** `fields.status.name`. Status names are project-configurable (e.g., "In Review", "Code Review", "Awaiting Validation") but categories are canonical across Jira instances.

| `statusCategory.key` | Normalized | Typical names |
|---|---|---|
| `new` | `OPEN` | To Do, Open, Backlog, Selected for Dev |
| `indeterminate` | `OPEN` | In Progress, In Review, In Test, Blocked |
| `done` | `CLOSED` | Done, Closed, Won't Do, Cancelled |

`indeterminate` is still actionable — agents should treat it as open work. The `done` category is terminal regardless of label (Won't Do is closed even though no code shipped).

## Blocked-by detection

Jira has typed issue links — use them, **not** body-text parsing. Body-text "Blocked by:" lines are a fallback only when `issuelinks` is empty (sometimes the case for tickets created from prose plan docs).

Fetch with:

```
mcp__claude_ai_Atlassian__getJiraIssue(
    cloudId=<CLOUD_ID>,
    issueIdOrKey=<KEY>,
    fields=["issuelinks"]
)
```

Or include `"issuelinks"` in the `fields` array of a `searchJiraIssuesUsingJql` call to batch-fetch.

Iterate `fields.issuelinks[]`:

| Link shape | Meaning |
|---|---|
| `link.type.inward == "is blocked by"` AND `link.inwardIssue` present | `inwardIssue.key` is a **blocker** of this issue |
| `link.type.inward == "blocks"` AND `link.outwardIssue` present | This issue **blocks** `outwardIssue.key` (informational on this side, not a blocker) |

Other link types (`relates to`, `clones`, `duplicates`) are not blockers.

### Resolution rules

A blocker is **resolved** when any of:

1. Blocker's `statusCategory.key == "done"`, OR
2. Blocker has a **merged** MR/PR (search the repo's git host by branch pattern `sweep/<BLOCKER-KEY>-*` and check state), OR
3. Blocker has an **open** MR/PR with `sweep/<BLOCKER-KEY>-*` branch (open MR is enough — dependents can stack on it)

A blocker is **unresolved** only when statusCategory is open AND no MR/PR exists for the blocker's branch.

### Base-branch determination for stacking

When all blockers are resolved, the dependent's base branch follows:

| Blocker state pattern | Base branch |
|---|---|
| All blockers' code on main (closed or merged PR) | repo default branch |
| Exactly one blocker has an open PR | that PR's `headRefName` (stack) |
| Multiple blockers have open PRs on different branches | repo default branch + flag `⚠️ diamond dependency` |

Diamond dependencies are unsafe to auto-stack — operator should merge at least one blocker first.

## Field extraction quick-ref

For the common fields skills need from a `getJiraIssue` or `searchJiraIssuesUsingJql` response:

| Skill field | Source |
|---|---|
| `id` / `key` | `key` (e.g., `PROJ-2`) — full key, NOT a number |
| `title` | `fields.summary` |
| `body` | `fields.description` (markdown when `responseContentFormat="markdown"`) |
| `status name` | `fields.status.name` (display only) |
| `state` (normalized) | derived from `fields.status.statusCategory.key` (table above) |
| `assignee` | `fields.assignee.displayName` (or `null` if unassigned) |
| `assignee account ID` | `fields.assignee.accountId` |
| `labels` | `fields.labels` (array of strings) |
| `updated` | `fields.updated` (ISO timestamp) |
| `due` | `fields.duedate` (ISO date or `null`) |
| `issuetype` | `fields.issuetype.name` (e.g., "Story", "Task", "Subtask", "Epic") |
| `subtasks` | `fields.subtasks` (array; recurse for full data) |
| `issuelinks` | `fields.issuelinks` (see Blocked-by section) |
| `web URL` | `webUrl` (top-level, not under `fields`) |

Comments are **not** in default responses — fetch separately via `mcp__claude_ai_Atlassian__fetch(url="/rest/api/3/issue/<KEY>/comment")`.
