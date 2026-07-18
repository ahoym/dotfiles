---
description: "Canonical classification taxonomy for a Jira ticket × MR state, plus the glab/gh fields needed to compute it. Used by epic-state and the future epic-advance dispatcher to ensure runners are dispatched against a single shared state model."
---

# MR State Classification

Canonical taxonomy for classifying a work item by combining its Jira state with its linked MR/PR state. Skills reference this file so the dispatcher and the assessor agree on the same labels.

## Taxonomy

Eight terminal classifications. Priority order — first match wins:

| # | Classification | Rule | Recommended next action |
|---|---|---|---|
| 1 | `merged` | Any linked MR has `state=merged` | None — done |
| 2 | `awaiting-review` | Open MR (`state=opened`), `draft=false`, no unaddressed reviewer comments | Run `git:team-review-request` |
| 3 | `review-comments-pending` | Open MR with unaddressed reviewer comments (see Comment-thread analysis below) | Run `git:address-request-comments` |
| 4 | `draft-mr` | Open MR, `draft=true` | Continue authoring — likely needs human |
| 5 | `mr-closed` | All linked MRs are `state=closed`, none merged, none open | Triage — orphaned closed MR usually means scope changed |
| 6 | `blocked` | Has unresolved `is blocked by` link (per `jira-issue-mapping.md` Blocked-by Resolution) | Wait or unblock |
| 7 | `in-progress-no-mr` | Jira `statusCategory.key == "indeterminate"`, no MR found | Continue implementing |
| 8 | `done-no-mr` | Jira `statusCategory.key == "done"`, no MR found | Triage — orphan, may indicate code lives elsewhere or ticket was admin-closed |
| 9 | `not-started` | Jira `statusCategory.key == "new"`, no MR found | Implement |

`review-comments-pending` requires comment-thread analysis (skipped in lighter-weight modes — collapses into `awaiting-review` then). When comment analysis is disabled, classes 2 and 3 merge.

## glab fields needed

Per MR, fetch via `glab mr view <iid> -R <project-path> --output json` and extract:

| Field | Used for |
|---|---|
| `state` | Class 1, 2, 3, 4, 5 (opened/merged/closed) |
| `draft` | Class 4 vs 2 |
| `target_branch` | Stack detection / report |
| `source_branch` | Branch convention check (`sweep/<KEY>-*`) |
| `web_url` | Report links |
| `merged_at` | Sort/recency for "unblocked by recent merges" |
| `updated_at` | Stale-draft detection |
| `author.username` | Report attribution |
| `assignee.username` | Report attribution |
| `user_notes_count` | Cheap signal for "has discussion" — not a substitute for thread analysis |

For comment-thread analysis (needed to distinguish `review-comments-pending` from `awaiting-review`):

```
glab api projects/<project-id>/merge_requests/<iid>/discussions
```

A reviewer thread is **unaddressed** when:
- `notes[0].author` is not the MR author, AND
- `resolvable=true` AND `resolved=false`, AND
- The most recent note in the thread is not from the MR author

**Self-posted team-review override.** Skills like `git:team-review-request` post their findings under the operator's account (= MR author), so the author-check rules above silently skip every thread. To compensate: when a top-level non-system note exists from the MR author whose body starts with `## Team Review:`, treat any `resolvable=true`, `resolved=false` thread on that MR as unaddressed regardless of who authored it. Without this override, MRs with N team-review findings classify as `awaiting-review` and waste cycles on a redundant review pass.

False positives in the base heuristic include:
- Reviewers who post a final "looks good" without resolving the thread.
- **CI/scanner bots** (GitLab pattern `group_<id>_bot_<hash>`, also security scanners, dependency bots): their notes are `author != MR author`, so a single unresolved bot finding flips the MR to `review-comments-pending` even when no human reviewer has engaged. Pragmatically, the action is still "address the bot's finding before merge" — but be aware the classification is bot-driven, not reviewer-driven. Skills that pre-filter on reviewer engagement (e.g. "skip if no human reviewer has commented") should special-case bot usernames.
- **Addresser auto-implement + reply.** `git:address-request-comments` / director sweep-mode address cycles commit fixes and post replies but typically do NOT toggle `resolved=true` per thread. After a converged dispatch, `unaddressed_threads` still equals the new finding count — re-running the classifier loops on the same MRs. Cross-check MR-level `blocking_discussions_resolved`: if `true`, treat the threads as acknowledged and downgrade to `awaiting-review` (or skip re-dispatch entirely) — per-thread `discussion.resolved=false` alone is unreliable for exactly this reason.

## gh fields needed (GitHub equivalents)

Skills targeting GitHub instead of GitLab use `gh pr view <num> --json state,isDraft,headRefName,baseRefName,url,mergedAt,updatedAt,author,assignees,comments`. The `state` values are uppercase: `OPEN`, `CLOSED`, `MERGED`. Map to the same taxonomy.

For comment-thread analysis: `gh api repos/<owner>/<repo>/pulls/<num>/comments` returns review comments; resolved threads are exposed differently (via GraphQL `pullRequest.reviewThreads.nodes[].isResolved`). GitHub support is deferred in current skills.

## Multi-MR per ticket

Tickets sometimes have multiple linked MRs (split work, retries, abandoned attempts). Resolution rule:

1. If any MR is `merged`, classify as `merged`.
2. Else if any MR is `opened`, use the most recently `updated_at` open MR for classes 2/3/4.
3. Else (all closed without merge), classify as `mr-closed`.

Report the count when >1 MR is linked, e.g., "MR: !42 (opened) +2 closed".

## Edge cases

- **MR view fails (404, perms):** record `state=unknown`, retain the URL, skip classification rules 1-5 for that MR. Fall through to Jira-status-only classes (6-9).
- **MR linked but branch deleted:** `glab mr view` still returns the MR record. Treat normally.
- **Jira closed but MR open:** rare — usually means MR was merged elsewhere or ticket reopened/closed admin-style. Classify by MR state (rules 1-5) over Jira state.
- **MR detection misses:** when relying on Atlassian's "Development" panel via `getJiraIssueRemoteIssueLinks`, results are eventually-consistent. Fallback to git-host branch search (`sweep/<KEY>-*`) catches MRs the panel hasn't indexed yet. Combine and dedupe by URL.

## Cross-Refs

- `~/.claude/learnings/gitlab/CLAUDE.md` — `glab` CLI gotchas (flag deprecations, list arg parsing, `-F` for GET parameters). Sniff if a `glab` invocation surprises.
- `~/.claude/learnings/bash-patterns.md` — shell expansion in URL construction (`?` glob in `glab api projects/.../merge_requests?source_branch=...`).
