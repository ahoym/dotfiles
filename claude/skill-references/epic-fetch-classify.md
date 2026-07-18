---
description: "Live fetch + classify pipeline for a Jira epic and its children. Walks epic → children → issue links → remote MRs → glab state → classification. Consumed by epic-state, epic-advance plan emitter, and dispatcher — all three live-fetch (no snapshot reuse)."
---

# Epic Fetch + Classify Pipeline

Canonical implementation of the live-fetch pipeline that turns an epic key into a fully-classified result set. Skills source the pipeline from this file rather than re-deriving it; this guarantees the assessor, plan emitter, and dispatcher all classify identically.

**Live fetch only.** This pipeline is the source of truth at run-time. No skill should consume a previously-written `data.json` as authoritative state — Jira and MR state drift in seconds, not days. The classify result may be written to disk for human inspection, but never read back as input by another pipeline run.

## Inputs

| Param | Required | Default | Notes |
|---|---|---|---|
| `EPIC_KEY` | yes | — | Jira key like `PROJ-1` |
| `CLOUD_ID` | no | — (resolved in Phase 1) | Atlassian cloudId / site, e.g. `<your-site>.atlassian.net` |
| `SKIP_MRS` | no | `false` | When true, skips Phases 3-4 (no glab calls) |
| `WITH_COMMENT_THREADS` | no | `false` | When true, Phase 4 also fetches MR discussions (needed to split `awaiting-review` vs `review-comments-pending`) |
| `MR_BRANCH_PATTERN` | no | `sweep/<KEY>-*` | Branch pattern for the git-host fallback search |

## Pipeline

### Phase 1: Resolve cloudId

If `CLOUD_ID` wasn't provided, or the first MCP call with it fails, resolve via `mcp__claude_ai_Atlassian__getAccessibleAtlassianResources` and pick the first matching site. Cache the resolved cloudId for the rest of the run.

### Phase 2: Fetch epic + children

**Epic header:**

```
mcp__claude_ai_Atlassian__getJiraIssue(
    cloudId=CLOUD_ID,
    issueIdOrKey=EPIC_KEY,
    fields=["summary", "status", "issuetype", "labels", "updated", "duedate", "assignee"],
    responseContentFormat="markdown"
)
```

Verify `fields.issuetype.name == "Epic"`. If not, warn and continue — caller may have passed a story key intentionally.

**Children** — epics use `parent`; some Jira projects also use the legacy `"Epic Link"` customfield. Try both:

```
mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql(
    cloudId=CLOUD_ID,
    jql="parent = {EPIC_KEY} OR \"Epic Link\" = {EPIC_KEY} ORDER BY created ASC",
    fields=["summary", "status", "issuetype", "priority", "labels", "updated", "assignee", "issuelinks", "subtasks"],
    maxResults=100
)
```

For each story-level child with subtasks (`fields.subtasks` non-empty), recurse one level: `getJiraIssue` per subtask to pull `issuelinks` and `status`. Subtasks of subtasks are out of scope.

Field extraction for each issue follows `~/.claude/skill-references/jira-issue-mapping.md` § Field extraction quick-ref.

### Phase 3: Fetch remote MR links per child

Skip if `SKIP_MRS=true`.

**Per child:**

```
mcp__claude_ai_Atlassian__getJiraIssueRemoteIssueLinks(
    cloudId=CLOUD_ID,
    issueIdOrKey=<KEY>
)
```

Filter to entries whose `object.url` matches `gitlab.*/-/merge_requests/\d+`. Then **also filter by title** — keep only entries whose `object.title` contains the child's issue key (e.g. `[PROJ-2]`). Jira's remote-links endpoint returns cross-references too: sibling tickets' MRs that mentioned this ticket in commits or descriptions show up under every key they touched. Without the title-key filter, every ticket in a stacked chain appears to have multiple MRs. Extract `(project_path, mr_iid)` from the URL of surviving entries.

**Branch-pattern fallback** — Jira's Development panel is eventually-consistent. Also search by branch convention:

```
glab api projects/:id/merge_requests -F source_branch={MR_BRANCH_PATTERN} -F state=all
```

(Substitute `<KEY>` into `MR_BRANCH_PATTERN`.) Use the project from `git remote get-url origin`. Combine with Jira remote-link results, dedupe by MR URL.

### Phase 4: Inspect each MR

For each unique MR `(project_path, mr_iid)`:

```bash
glab mr view <mr_iid> -R <project_path> --output json
```

Extract fields per `~/.claude/skill-references/mr-state-classification.md` § glab fields needed. Edge-case handling per the same reference.

**If `WITH_COMMENT_THREADS=true`**, additionally fetch discussions:

```bash
glab api projects/<id>/merge_requests/<iid>/discussions
```

Apply the unaddressed-thread heuristic from `mr-state-classification.md` § glab fields needed (resolvable=true, resolved=false, latest note from non-author).

**Batch helper.** Prefer the wrapper `~/.claude/skill-references/epic-fetch-mr-states.sh <project_path> <iid> [<iid> ...]` over hand-rolled glab loops. It emits JSONL (one record per IID) with both the core-fields set AND the `unaddressed_threads` count computed against the canonical heuristic (including the self-posted team-review override). Pass all IIDs in one invocation so the helper handles per-MR sequencing internally.

**Parallelism:** when >5 MRs need inspection, batch glab calls (Bash subshells with `&`, or one Bash call with multiple lines). Cap concurrency at ~10 to avoid rate-limit issues.

### Phase 5: Classify

Apply the taxonomy in `~/.claude/skill-references/mr-state-classification.md`. Effective output set depends on mode:

| Mode | Class set |
|---|---|
| `WITH_COMMENT_THREADS=false` (default) | 7 classes: `merged` · `awaiting-review` · `draft-mr` · `mr-closed` · `blocked` · `in-progress-no-mr` · `done-no-mr` · `not-started` (class 3 collapses into class 2) |
| `WITH_COMMENT_THREADS=true` | 8 classes — adds `review-comments-pending` |
| `SKIP_MRS=true` | 4 classes: `blocked` · `in-progress-no-mr` · `done-no-mr` · `not-started` (everything else requires MR data) |

State normalization (`statusCategory.key` → `OPEN`/`CLOSED`) and blocked-by resolution: `~/.claude/skill-references/jira-issue-mapping.md`.

**Sibling-first blocker resolution:** when checking whether a blocker is resolved, first look in the already-fetched children of this epic. Most blockers within an epic are siblings — saves an extra `getJiraIssue` call per blocker.

## Output schema

The pipeline produces a structured result that consumers render to markdown, manifest, or anything else. Schema:

```typescript
interface EpicClassifyResult {
  epic: {
    key: string;
    summary: string;
    status: { name: string; category: "new" | "indeterminate" | "done" };
    assignee: string | null;
    updated: string;  // ISO
    duedate: string | null;
    url: string;
    labels: string[];
  };
  cloudId: string;
  fetchedAt: string;  // ISO — when this pipeline run executed
  mode: { skipMrs: boolean; withCommentThreads: boolean };
  children: ChildRecord[];
  // Stats are computed post-classification for caller convenience
  stats: { total: number; byClass: Record<Classification, number> };
}

interface ChildRecord {
  key: string;
  type: "Story" | "Task" | "Subtask" | "Bug" | string;
  summary: string;
  status: { name: string; category: "new" | "indeterminate" | "done" };
  assignee: string | null;
  updated: string;
  url: string;
  labels: string[];
  parentKey: string | null;  // for subtasks; null for direct epic children
  // Issue links — only "is blocked by" + "blocks", others dropped
  blockedBy: string[];  // keys
  blocks: string[];     // keys
  blockerStatus: "resolved" | "unresolved" | "none";  // computed
  // MR records, deduped by URL
  mrs: MrRecord[];
  // Final classification per mr-state-classification.md
  classification: Classification;
  baseBranch: string;  // computed per jira-issue-mapping.md base-branch determination — defaults to repo default branch
  diamondDependency: boolean;  // multiple blockers with open PRs on different branches
}

interface MrRecord {
  iid: number;
  projectPath: string;
  state: "opened" | "merged" | "closed" | "unknown";
  draft: boolean;
  targetBranch: string;
  sourceBranch: string;
  webUrl: string;
  authorUsername: string;
  assigneeUsername: string | null;
  mergedAt: string | null;
  updatedAt: string;
  userNotesCount: number;
  // Only populated when WITH_COMMENT_THREADS=true
  unaddressedThreads?: number;
}

type Classification =
  | "merged"
  | "awaiting-review"
  | "review-comments-pending"
  | "draft-mr"
  | "mr-closed"
  | "blocked"
  | "in-progress-no-mr"
  | "done-no-mr"
  | "not-started";
```

This schema is the in-memory contract between the pipeline and its consumers. The same schema can be serialized to `data.json` for human inspection; it must never be deserialized as authoritative input by another pipeline run.

## Performance notes

- **Single JQL with `issuelinks` in fields** avoids N+1 issue-link fetches. Verify the JQL response actually populates `fields.issuelinks[]` before falling back to per-child `getJiraIssue` calls.
- **Subtask recursion costs one `getJiraIssue` per subtask.** Bounded at one level. For epics with many subtasks, this dominates the wall clock — consider whether the consumer needs subtask granularity.
- **`glab mr view` is the long pole** when MR count is high. Parallel batches help; keep the cap at ~10 to stay friendly with the API.
- **CloudId resolution failure cost:** one extra MCP call when the default fails. Cache the resolved cloudId.
- **Comment-thread analysis doubles glab calls per MR.** Only enable when the consumer actually needs the `review-comments-pending` split.

## Cross-Refs

- `~/.claude/skill-references/jira-issue-mapping.md` — state mapping, blocked-by detection, field extraction
- `~/.claude/skill-references/mr-state-classification.md` — classification taxonomy, glab/gh fields, multi-MR resolution
- `~/.claude/learnings/gitlab/CLAUDE.md` — `glab` CLI gotchas (flag deprecations, paginate vs `-F`, `--state` flag changes). Sniff before Phase 4 if a `glab` invocation surprises.
- `~/.claude/learnings/bash-patterns.md` — shell expansion safety (`?` glob in `glab api ...?param=...` URLs, quoting, redirects). Sniff if shell-call retry needed.
