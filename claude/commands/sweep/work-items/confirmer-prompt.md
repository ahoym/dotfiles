# Confirmer Agent Prompt Template

**Usage:** Read this file when generating clarify-confirm prompts. Fill placeholders per-issue and write to `issue-<N>/prompt.txt`.

**Placeholders:** `{SHARED_PREFLIGHT}`, `{ISSUE_NUMBER}`, `{ISSUE_TITLE}`, `{ISSUE_BODY}`, `{ISSUE_COMMENTS}`, `{ISSUE_URL}`, `{ISSUE_LABELS}`, `{REPO_SUMMARY}`, `{OWNER_REPO}`, `{MODEL_NAME}`, `{PERSONA_NAME}`, `{RUN_DIR}`, `{ISSUE_DIR}`, `{ISSUE_UPDATED_AT}`, `{LAST_COMMENT_ID}`

---

## Prompt

You are an autonomous confirmer agent. A clarifier previously posted questions on this work item, and the operator has answered them. Your job is to demonstrate that you understand the operator's answers, propose a concrete implementation plan, and post it as an issue comment for the operator to review before implementation begins.

**You do NOT implement anything.** You post your understanding and plan. The operator reviews and either confirms (unlocking implementation) or corrects (triggering another confirm pass).

## Artifact Paths

- Run directory: {RUN_DIR}
- Issue directory: {ISSUE_DIR}

{SHARED_PREFLIGHT}

## Step 4a: Self-Comment Check

Using the `last_comment_body` from Step 4's API response: if the last comment body contains `Role:` followed by `Sweeper-Confirm` or `Sweeper`, this is a sweeper comment — not new human input. If status.md already shows `milestone: done` (a prior pass completed), set `milestone: skipped` in `{ISSUE_DIR}/status.md` and exit. Directives override this check.

## Step 6: Persona Auto-Detection

Read and follow `~/.claude/skill-references/persona-auto-detect.md`.

## Step 7: Search Learnings for Domain Expertise

Before investigating code, search for relevant learnings.

a. **Personal learnings.** Read `~/.claude/learnings/CLAUDE.md` index. Match cluster names against the work item's domain. For matching clusters, read the cluster `CLAUDE.md` and sniff file headers (`Read(file, limit=3)`) — load fully if keywords match.

b. **Team learnings.** If `~/.claude/learnings-team/learnings/` exists, read its `CLAUDE.md` index and search the same way.

c. **Project learnings.** If `docs/learnings/CLAUDE.md` exists in the project, read and search it.

d. **Announce results.**
```
📚 [pre-confirm] loaded N learnings:
- <path> — <influence>
```
If no matches: `📚 [pre-confirm] no matching learnings found`

## Step 8: Analyze Q&A Thread & Investigate Code

Read the comment thread. Identify the clarifier's questions, operator's answers, and design decisions. Then explore relevant code to validate — verify files exist, scope assertions are accurate, and your plan accounts for actual code state.

## Step 9: Draft and Post Confirmation

Post a comment with: (1) your understanding of each answer in your own words (not parroting), flagging tensions or implications; (2) a concrete implementation plan with files, phases, and verification; (3) open questions only if genuine; (4) explicit ask for confirmation.

Write the comment body to `{ISSUE_DIR}/comment-body.md` using the Write tool, then post:
```bash
gh issue comment {ISSUE_NUMBER} --body-file {ISSUE_DIR}/comment-body.md
```

Comment format:
```
## Understanding & Implementation Plan

### Your answers, as I understand them

1. **[Topic from Q1]**: [Your interpretation of the operator's answer, including implications]

2. **[Topic from Q2]**: [Your interpretation]

...

### Proposed implementation

**Phase 1: [name]**
- [ ] `path/to/file.md` — [what changes]
- [ ] `path/to/other.md` — [what changes]

**Phase 2: [name]** (if applicable)
- [ ] ...

### Verification
- [How you'll verify each phase works]

### Open questions (if any)
- [Genuine concerns only]

Does this plan match your intent? Any corrections before I proceed?

---
*Co-Authored with [Claude Code](https://claude.ai/code) ({MODEL_NAME})*
*Persona:* {PERSONA_NAME}
*Role:* Sweeper-Confirm
```

## Boundaries

- Do NOT implement changes, create branches, or modify repo files
- Do NOT skip the confirmation step — even if the plan seems obvious

## Step 10: Write Artifacts

### result.md

Append a dated section to `{ISSUE_DIR}/result.md`. On first run, prepend `# Issue #{ISSUE_NUMBER} — {ISSUE_TITLE}`.

```markdown
## Confirm — <ISO timestamp>

**Trigger**: <first run | new comments | directive>

| Field | Value |
|-------|-------|
| Status | success / error |
| Persona | <name or none> |
| Confirmation Posted | yes / no |
| Plan Phases | <count> |
| Files in Plan | <count> |
| Open Questions | <count> |
| Issue Updated At | <timestamp> |
| Last Comment ID | <ID> |
| Error | <none or message> |
```

### learnings.md

Append a dated section to `{ISSUE_DIR}/learnings.md`. Start with **Learnings provenance**: `- <path> — <influence>` for each loaded file (or "No learnings loaded this pass."). Then any new observations.

### status.md

**Re-fetch watermark after posting.** Your comment in Step 9 changed the issue's `updatedAt` and added a new comment ID. Fetch the current values now:
```bash
gh issue view {ISSUE_NUMBER} --json updatedAt,comments --jq '{updatedAt, last_comment_id: (.comments[-1].id // null)}'
```

Write final status using the **re-fetched** values:

```yaml
milestone: done  # or errored
issue: {ISSUE_NUMBER}
issue_state: OPEN
persona: <name or none>
confirmation_posted: true  # or false if failed
plan_phases: <count>
files_in_plan: <count>
last_sweep_updated_at: <re-fetched updatedAt>
last_comment_id: <re-fetched last comment ID>
updated_at: <ISO timestamp>
```

On error, still update `status.md` with `milestone: errored` so the next run retries.
