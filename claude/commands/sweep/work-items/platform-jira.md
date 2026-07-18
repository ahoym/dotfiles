# Platform: Jira

Implementation of the platform contract for Jira issues. Loaded by `SKILL.md` Phase 2 when source detection resolves to `jira`. Note: Jira is the *source* of work items; PRs/MRs still live on GitHub or GitLab — Phase 7+ (PR creation) uses the repo's git host, not Jira.

## 1. Detection

| Signal | Resolution |
|---|---|
| Any arg matches `[A-Z]+-\d+` (Jira key shape, e.g., `PROJ-42`) | `jira` |
| `--epic=[A-Z]+-\d+` flag (epic-children mode) | `jira` |
| `--source=jira` flag | `jira` (override) |

If both Jira keys and `#\d+` issue numbers appear in args, error: **mixed-source unsupported** — split into two skill invocations.

## 2. Fetch single item

Use the Atlassian MCP tool. CloudId resolution: try the site hostname first (e.g., `<your-site>.atlassian.net`); if that fails, call `mcp__claude_ai_Atlassian__getAccessibleAtlassianResources` to list accessible cloud IDs.

```
mcp__claude_ai_Atlassian__getJiraIssue(
    cloudId="<site>.atlassian.net",
    issueIdOrKey="PROJ-42",
    responseContentFormat="markdown"
)
```

Map response fields:
- `fields.summary` → `title`
- `fields.description` (markdown) → `body`
- `fields.status.name` + `fields.status.statusCategory.key` → state (see #5)
- `fields.labels` → `labels`
- `fields.updated` → `updatedAt`
- `webUrl` → `url`
- `key` → `id` (e.g., `PROJ-42`, NOT a number)

Comments are typically not in the default response — fetch via #4.

## 3. Fetch list

For an epic's children:

```
mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql(
    cloudId="<site>.atlassian.net",
    jql="parent = PROJ-41 ORDER BY created ASC",
    fields=["summary", "description", "status", "issuetype", "priority", "labels", "updated"],
    maxResults=50
)
```

For arbitrary JQL (operator passes `--jql=...`):

```
jql=<operator-supplied>
```

For label filter (`--label=foo`):

```
jql=labels = "foo" AND status != Done
```

## 4. Fetch comments

`getJiraIssue` does not return comments by default. Fetch via:

```
mcp__claude_ai_Atlassian__fetch(
    cloudId="<site>.atlassian.net",
    url="/rest/api/3/issue/PROJ-42/comment"
)
```

Response shape: `{ comments: [{ id, body, author: { accountId, displayName }, created, updated }] }`. Body content format depends on responseContentFormat.

Top-level comments only — Jira does not have inline-on-line comments like GitHub PRs.

## 5. State mapping

See `~/.claude/skill-references/jira-issue-mapping.md` § State mapping for the canonical `statusCategory.key` → `OPEN` / `CLOSED` rules. Summary: use `statusCategory.key`, not `status.name` (names vary per project, categories are canonical).

## 6. Blocked-by detection

See `~/.claude/skill-references/jira-issue-mapping.md` § Blocked-by detection for the canonical rules — link iteration, resolution criteria, and base-branch determination for stacking. Summary: iterate `fields.issuelinks[]`, treat `link.type.inward == "is blocked by"` as the blocker signal, and resolve via blocker statusCategory + branch-pattern MR/PR search.

## 7. Linked-PR detection

PRs/MRs live on the repo's git host, not in Jira. Use the existing GH or GL command appropriate to the repo:

- GitHub repo: `gh pr list --state open --head "sweep/<KEY>-*" --json number,headRefName,url`
- GitLab repo: `glab api projects/:id/merge_requests -F source_branch=sweep/<KEY>-* -F state=all`

Jira's "Development" panel sometimes contains linked branches/MRs (`mcp__claude_ai_Atlassian__getJiraIssueRemoteIssueLinks`), but it's eventually-consistent and unreliable — prefer the git-host search.

## 8. Comment posting (POST_ISSUE_COMMENT_CMD template)

Agents post clarification / confirmation comments to the Jira ticket via MCP:

```
mcp__claude_ai_Atlassian__addCommentToJiraIssue(
    cloudId="<site>.atlassian.net",
    issueIdOrKey="PROJ-42",
    commentBody="<comment markdown — include *Role:* Sweeper footnote>"
)
```

The Sweeper / Sweeper-Confirm footnote convention is unchanged — agents append `\n\n*Role:* Sweeper` (or `Sweeper-Confirm`) to enable Phase 3 skip detection on the next sweep cycle.

Note: agents in `claude -p` headless sessions need MCP tool access. The skill prereq check (Phase 0) must verify the Atlassian MCP server is enabled in the agent's settings.

## 9. Watermark fields

`status.md` keys for Jira:
```yaml
last_comment_id: <max id from rest/api/3/issue/<KEY>/comment>
last_sweep_updated_at: <issue.fields.updated>
```

Skip rule: both must equal current values. Either differs → re-process.

## 10. Implement-time ticket mutation (assign + sprint)

When Phase 5 resolves `role == "implement"` for a Jira-sourced item, mutate the ticket so it reflects "this work has started":

1. **Resolve current user** (once per sweep, cache):

   ```
   mcp__claude_ai_Atlassian__atlassianUserInfo()
   ```

   Capture `accountId`. Reuse for all items in the run.

2. **Resolve the active sprint** (once per sweep, cache by project key):

   Jira's sprint field is a project-scoped custom field whose ID varies per instance. Resolve via the agile API:

   ```
   mcp__claude_ai_Atlassian__fetch(
       cloudId=<site>,
       url="/rest/agile/1.0/board?projectKeyOrId=<projectKey>"
   )
   ```

   Pick the first scrum-type board. Then:

   ```
   mcp__claude_ai_Atlassian__fetch(
       cloudId=<site>,
       url="/rest/agile/1.0/board/<boardId>/sprint?state=active"
   )
   ```

   Pick the first active sprint. Capture `sprint.id`. **If no scrum board or no active sprint exists, skip sprint assignment and log a soft warning** — assignee mutation still proceeds.

3. **Resolve the sprint custom field ID** (once per sweep, cache):

   ```
   mcp__claude_ai_Atlassian__fetch(
       cloudId=<site>,
       url="/rest/api/3/field"
   )
   ```

   Find the entry where `schema.custom == "com.pyxis.greenhopper.jira:gh-sprint"`. Capture `id` (e.g., `customfield_10020`).

4. **Apply mutation** per item:

   ```
   mcp__claude_ai_Atlassian__editJiraIssue(
       cloudId=<site>,
       issueIdOrKey=<KEY>,
       fields={
           "assignee": { "accountId": "<currentUser.accountId>" },
           "<sprintCustomFieldId>": <sprint.id>
       }
   )
   ```

   Either field can be omitted if its resolution failed in step 2 or 3 — never block implementation on these. The mutation is idempotent (re-assigning the same user / re-adding to the same sprint is a no-op).

**When NOT to mutate:**

- `role != "implement"` — clarify and confirm rounds shouldn't claim ownership.
- Item already assigned to someone other than the current user — log a notice and skip (don't steal someone else's work). Use the assessment-phase fetch to check `fields.assignee.accountId` before mutating.
- `--no-claim` flag passed to /sweep:work-items (operator opt-out).

**Failure handling:** mutation failures are logged but don't fail the sweep. Implementation proceeds even if assign/sprint mutation errors — the worst case is a missing sprint tag, which the operator can fix manually.

## 11. Branch naming

`sweep/<KEY>-<slug>` where `<KEY>` is the **full Jira key** (e.g., `PROJ-42`), NOT a number. Slug is kebab-case 3-5 word summary derived from the title.

Example: `PROJ-42` titled "Fix login redirect after timeout" → `sweep/PROJ-42-fix-login-redirect`.

## Permissions (Phase 0 prereq check)

When source resolves to `jira`, the agent's `~/.claude/settings.json` must enable:

```json
"mcp__claude_ai_Atlassian__getJiraIssue",
"mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql",
"mcp__claude_ai_Atlassian__addCommentToJiraIssue",
"mcp__claude_ai_Atlassian__fetch",
"mcp__claude_ai_Atlassian__getAccessibleAtlassianResources",
"mcp__claude_ai_Atlassian__atlassianUserInfo",
"mcp__claude_ai_Atlassian__editJiraIssue"
```

The last two are required for § 10 (implement-time assign + sprint mutation). They are not needed when source is `github` or `gitlab`.

PR-creation patterns (`gh pr create:*` or `glab mr create:*`) are still required from the repo's git-host platform — Jira issues don't replace the PR side of the workflow.

## Implementation notes

- **Mixed-source not supported.** A single sweep invocation must be all-Jira or all-GH/GL. The director can run two separate sweeps if needed.
- **CloudId is per-site, not per-issue.** Cache the cloudId at sweep start; reuse across all items.
- **MCP tool result size.** `getJiraIssue` returns ~50–80KB per call. For batch operations across many issues, consider running the Phase 2 fetch in an `Agent(isolation: "worktree")` to keep verbose payloads out of the main context.
- **No `gh` / `glab` equivalents for Jira CLI.** Everything goes through MCP. There is no Jira-specific shell stub in `~/.claude/platform-commands/`.
