---
description: Read a planning doc with a waffle section (verticals × layers ticket grid) and create the corresponding Jira tickets via the Atlassian MCP. Use when a markdown planning artifact already exists and the next step is to translate it into tickets.
---

# tickets-from-plan

Translate a `<repo>/docs/plans/<initiative>/` planning artifact into Jira tickets. Mechanical translation, not architectural design — the doc has already locked decisions; this skill only creates the tickets that implement them.

## Usage

- `/tickets-from-plan <path-to-planning-doc>` — explicit path
- `/tickets-from-plan` — auto-discover (look for `docs/plans/*/README.md` in CWD; if multiple, ask operator)

## When to use

- A planning doc with a **waffle section** (markdown table: rows = layers, columns = verticals/features) exists and is locked
- Decisions in the doc are stable — naming, contract shapes, scope inclusions all settled
- Next step is mechanical: translate cells into tickets

## When NOT to use

- Decisions still in flight — DON'T create tickets while architecture is being riffed. Tickets created prematurely cost ~5k tokens per `editJiraIssue` to fix later.
- No planning doc exists — propose one first; the doc IS the source of truth, tickets are the work-tracking surface.
- Single-ticket work — overkill; just create the ticket directly.

## Instructions

### 1. Read the planning doc

Extract:

- **Epic title(s)** from status / overview section. One epic per logical grouping (e.g. one per vertical column if the waffle is large; one per doc if scope fits).
- **Cells from the waffle** — each non-empty cell becomes a ticket. The cell's V-L tag (e.g. `V2-L4`) goes into the ticket title for traceability.
- **Locked decisions** — fold into ticket acceptance criteria where they constrain the cell's work (e.g. "use Option X cache modelling", "return single decision not list").
- **Forward-compat commitments** — same; turn into acceptance-criteria checkboxes.
- **Sequencing diagram** — drives "Blocks / Blocked by" lines in each ticket.
- **References** — surface in each ticket's context section so they link back to the planning doc.

### 2. Discover project conventions

Convention discovery before bulk creation:

- `getAccessibleAtlassianResources` → cloudId
- `getJiraProjectIssueTypesMetadata` → available types and hierarchy levels
- `searchJiraIssuesUsingJql` for recent tickets in target project (last ~30 days) → title prefix, issue type the team uses for atomic work, label patterns, priority defaults

Adopt these conventions for the new tickets. Don't invent conventions where the team has them.

### 3. Pre-flight summary + AskUserQuestion

Show the proposed structure as a table (epic title + child titles + V-L tags) plus detected conventions (issue type, labels, priority). Use `AskUserQuestion` for the 1–2 genuinely ambiguous decisions:

- Inclusions / exclusions (any cells you're uncertain belong in this batch)
- Labels (default to detected convention, or apply initiative-wide labels for cross-epic discoverability)
- Anything not fully specified by the doc

Don't free-form prompt — focused multiple-choice keeps the gate cheap.

### 4. Delegate bulk MCP calls to a subagent

This is the key efficiency move. The Atlassian MCP returns ~5k tokens per `createJiraIssue` / `editJiraIssue` call (custom fields). For a 7-ticket batch, that's 35k+ tokens of response bloat. Delegating to a subagent isolates that cost.

Spawn a `general-purpose` Agent with the full task bundle:

- Cloud ID + project key
- Epic spec (title, description, labels)
- Each child ticket spec (parent: `<epic-key-placeholder>`, title, description, labels)
- Instruction: "Create the epic first, capture the key, then create all child tickets in parallel with `parent: <epic-key>`. Report back: epic key + table of child keys + any errors."

The agent does all the MCP calls, eats the bloat in isolated context, and reports back ~200 tokens. Parent context stays clean.

### 5. Verify and report

Once the subagent returns:

- Surface epic key + child ticket keys (table) to operator
- Confirm any deferred items (cells not turned into tickets, with reason)
- Link back to the planning doc as the source of truth
- Note any conventions adopted (so the operator can verify they match expectations)

## Subagent prompt skeleton

```
Create Jira tickets via Atlassian MCP in project <X>, cloudId <Y>.

Epic to create:
- Title: "<epic title>"
- Issue type: Epic
- Labels: [<labels>]
- Description: <markdown body>

Child tickets to create after epic (in parallel, each with parent: <epic-key>):
1. "<title 1>"  — description: <body 1>
2. "<title 2>"  — description: <body 2>
...

Use contentFormat: "markdown" for all descriptions.
Test the epic creation first to verify rendering, then batch the children in parallel.
Report back:
- Epic key
- Table of child keys with their titles
- Any errors encountered
```

## Bulk edit case

When the operator already has tickets and decisions changed, the same Agent-delegation pattern applies — bundle all `editJiraIssue` calls into a subagent prompt. The 5k-token-per-call response bloat compounds; isolation matters more for edits than for creates.

## Out of scope

- **Creating the planning doc** — separate concern. The doc must exist before this skill runs.
- **Architectural decisions** — locked in the doc; this skill doesn't re-litigate.
- **Issue links beyond Epic-child** — `parent` field handles Epic linking. If the doc has explicit "Blocks" relationships, those are mentioned in ticket descriptions; only create formal `Blocks` issue links if the team uses them (check via `getIssueLinkTypes` and recent ticket sample).
