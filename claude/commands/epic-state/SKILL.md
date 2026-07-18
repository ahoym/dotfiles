---
name: epic-state
description: "Pull a Jira epic with its children, issue links, and remote MRs, then classify implementation state and emit a markdown report. Read-only — no dispatch, no writes to Jira/Git."
argument-hint: "PROJ-101 [--no-mrs] [--write] [--cloud=<site>.atlassian.net]"
---

## Context
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`
- Remote: !`git remote get-url origin 2>/dev/null`
- Default cloudId: discovered via `getAccessibleAtlassianResources` (override with `--cloud=<your-site>.atlassian.net`)

# Epic State

Read-only assessment of a Jira epic. Walks epic → children → issue links → remote MRs, classifies each child by implementation state, and emits a markdown report.

This skill is the **assessment** half of an eventual epic-aware dispatcher. It produces no manifest, opens no MRs, posts no comments. The fetch + classify pipeline is shared with the dispatcher (`~/.claude/skill-references/epic-fetch-classify.md`); this skill only owns the rendering layer.

## Usage

| Form | Effect |
|---|---|
| `/epic-state PROJ-101` | Full report with MR state |
| `/epic-state PROJ-101 --no-mrs` | Skip glab calls — Jira-only state (faster, less precise) |
| `/epic-state PROJ-101 --write` | Also write report to `tmp/claude-artifacts/epic-state-PROJ-101-<ts>/report.md` |
| `/epic-state PROJ-101 --cloud=other.atlassian.net` | Override cloudId |

## Prerequisites

- Atlassian MCP available (`mcp__claude_ai_Atlassian__*` tools)
- `glab` CLI authenticated (only if MR inspection enabled — default)
- Repo's origin is GitLab (this skill currently assumes `glab`; GitHub support is a future add)

If `glab` is missing/unauthenticated and `--no-mrs` is not set, fall back to `--no-mrs` mode and print a warning.

## Pipeline

### Phase 1: Parse args

Parse `$ARGUMENTS`:
- First positional matching `[A-Z]+-\d+` → `EPIC_KEY` (required; abort with usage hint if missing)
- `--no-mrs` → `SKIP_MRS=true`
- `--write` → `WRITE_REPORT=true`
- `--cloud=<host>` → `CLOUD_ID` (default: discover via `getAccessibleAtlassianResources`)

### Phase 2: Run fetch + classify pipeline

Execute the pipeline in `~/.claude/skill-references/epic-fetch-classify.md` with:

- `EPIC_KEY` = parsed
- `CLOUD_ID` = parsed
- `SKIP_MRS` = parsed
- `WITH_COMMENT_THREADS` = `false` (this slice doesn't split `awaiting-review` vs `review-comments-pending` — the dispatcher does)

The result is an `EpicClassifyResult` (schema in the reference). All subsequent phases consume that in-memory object — do not re-fetch.

### Phase 3: Render report

Output the report to stdout (always) and to `tmp/claude-artifacts/epic-state-<EPIC_KEY>-<ts>/report.md` if `--write`. Compute `<ts>` via separate Bash call: `date +%Y-%m-%d-%H%M`.

Report structure:

```markdown
# Epic State: <EPIC_KEY> — <summary>

**Status:** <name> (<statusCategory>)
**Assignee:** <displayName or unassigned>
**Updated:** <relative, e.g. "3 days ago">
**Due:** <duedate or none>
**URL:** <webUrl>

## Summary

<N> children · <merged> merged · <awaiting-review> awaiting review · <draft-mr> draft · <in-progress-no-mr> in progress · <not-started> not started · <blocked> blocked · <done-no-mr> orphan-done

Overall: <X>% merged, <Y>% in flight, <Z>% not started.

## Children

| Key | Type | Summary | Status | Assignee | MR | Classification |
|---|---|---|---|---|---|---|
| PROJ-102 | Story | Define widget API | In Review | mahoy | !42 (opened) | awaiting-review |
| PROJ-103 | Story | Implement data fetcher | Done | mahoy | !38 (merged) | merged |
| PROJ-104 | Story | Wire metrics reporting | To Do | — | — | blocked (PROJ-102) |
| PROJ-105 | Subtask | Add OpenAPI sample | In Progress | jdoe | — | in-progress-no-mr |

(MR column shows `!IID (state)` — link to web_url in the markdown source.)

## Dependency graph

<Only render if any child has issue links. Use a simple text tree.>

```
PROJ-102 (awaiting-review)
  └─ blocks → PROJ-104 (blocked)
  └─ blocks → PROJ-105 (in-progress-no-mr)
PROJ-106 (merged)
  └─ blocks → PROJ-107 (not-started)
```

## Recommended next moves

<Advisory only. One bullet per actionable category, max 5.>

- **Review-ready:** PROJ-102 (`!42`), PROJ-110 (`!47`) — pending team review
- **Implement next (unblocked):** PROJ-111, PROJ-112 — no blockers, no MR
- **Unblocked by recent merges:** PROJ-107 — PROJ-106 just merged
- **Orphan check:** PROJ-113 marked Done in Jira but no MR found — verify
- **Stale drafts:** PROJ-114 (`!49`, draft, last updated 21 days ago)
```

If `--write`, also dump a `data.json` next to `report.md` containing the full `EpicClassifyResult` (schema in the pipeline reference). **`data.json` is for human inspection only** — no skill should read it back as authoritative input. The dispatcher always re-runs the pipeline.

### Phase 4: Announce

Print:

```
Epic <KEY>: <merged>/<total> merged, <eligible-actions> recommended next moves.
<If --write: Report at <path>/report.md>
```

Stop. No further action.

## Cross-Refs

- `~/.claude/skill-references/epic-fetch-classify.md` — fetch + classify pipeline (shared with the dispatcher)
- `~/.claude/skill-references/jira-issue-mapping.md` — state mapping + blocked-by detection
- `~/.claude/skill-references/mr-state-classification.md` — classification taxonomy

## Out of scope (this slice)

- **No dispatch.** No manifest, no `let-it-rip.sh`, no `claude -p` sessions. That's `/sweep:epic-advance`.
- **No comment-thread analysis.** Pipeline is invoked with `WITH_COMMENT_THREADS=false`; the dispatcher will turn it on to split `awaiting-review` vs `review-comments-pending`.
- **No GitHub support.** GitLab-only via `glab`.
- **No cross-epic links.** If a child is blocked by an issue in a different epic, the report shows the blocker key but doesn't recurse.
- **No write actions.** Skill is read-only by design.
