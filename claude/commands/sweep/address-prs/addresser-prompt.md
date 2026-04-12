# Addresser Agent Prompt Template

**Usage:** Assembled by `fill-template.sh` — do not fill placeholders manually.

**Placeholders (from metadata.json):** `{PR_NUMBER}`, `{PR_TITLE}`, `{PR_URL}`, `{OWNER_REPO}`, `{BRANCH}`, `{BASE}`, `{MODE}`, `{RESOLVE_CONFLICTS}`, `{WORKTREE_PATH}`, `{PERSONA_INSTRUCTION}`, `{RUN_DIR}`, `{PR_DIR}`, `{LAST_SHA_FIELD}`
**File inclusions:** `{@../sweep-pr-preflight.md}` (Steps 1-4: directives, watermark, state check, status update)

---

## Prompt

You are an autonomous addresser agent. Your job is to address review comments on a pull request and write structured artifacts for the orchestration layer.

## Artifact Paths

- Run directory: {RUN_DIR}
- PR directory: {PR_DIR}

{@../sweep-pr-preflight.md}

## PR Context

- **#{PR_NUMBER}**: {PR_TITLE}
- **URL**: {PR_URL}
- **Branch**: {BRANCH} → {BASE}
- **Mode**: {MODE}

## Step 5: Enter Worktree

`cd` into the worktree directory: `{WORKTREE_PATH}`

Verify the working directory is correct:
```bash
pwd
git branch --show-current
```

## Step 6: Resolve Conflicts (conditional)

**Only run this step when `{RESOLVE_CONFLICTS}` is `true`.**

Check whether the PR has merge conflicts with the base branch (run `gh pr view {PR_NUMBER} --json mergeable --jq .mergeable`). If CONFLICTING, resolve:
1. Update `{PR_DIR}/status.md` milestone to `resolving-conflicts`
2. Use the Skill tool: `skill="git:resolve-conflicts"`, `args="{BASE}"`

If no conflicts exist at runtime, proceed to the next step.

If `{RESOLVE_CONFLICTS}` is `false`, skip this step entirely.

## Step 7: Search Learnings

Derive search terms from PR title, branch name, and comment content. Read `~/.claude/learnings-providers.json` to discover all provider directories. For each provider, read its `localPath`'s `CLAUDE.md` index (when it exists). Also check `docs/learnings/CLAUDE.md` for project-local learnings. Sniff matching cluster headers (`Read(file, limit=3)`), load fully if relevant. Load top 3; announce with `[pre-address]` tags.

## Step 8: Activate Persona

{PERSONA_INSTRUCTION}

## Step 9: Invoke Address Skill — MANDATORY

You MUST use the Skill tool: `skill="git:address-request-comments"`, `args="{PR_NUMBER}"`.

Do NOT address comments manually — the skill handles platform-specific API quirks.

Update `{PR_DIR}/status.md` milestone: `addressing` → `pushing` → `done`.

## Step 10: Write Artifacts

Follow **Result & Learnings Append Pattern** and **status.md Watermark** in `sweep-scaffold.md`. Mode-specific result fields:

```markdown
## Address — <ISO timestamp>

**Trigger**: <first run | N new comments since last pass | new commits (old_sha → new_sha) | both | directive>

| Field | Value |
|-------|-------|
| Status | success / skipped / error |
| Conflicts resolved | yes / no / n/a |
| Auto-implemented | <count> |
| Escalated | <count> |
| Commits | <count> |
| Address SHA | <HEAD SHA> |
| Last Comment ID | <latest comment ID> |
| Error | <none or message> |
```

Use `last_addressed_sha` as the watermark SHA key in `status.md`. On error, still write `milestone: errored`.

## Step 11: Write Learnings

Append a dated section to `{PR_DIR}/learnings.md`. Include:
- Which learnings files you loaded and how they influenced addressing
- Domain observations: patterns, gotchas, or conventions discovered in the code
- Addressing observations: what was straightforward to implement, what required escalation and why

Identify at least one constraint, pattern, or surprise you encountered that wasn't in the learnings you loaded. If genuinely nothing new, explain what made this pass routine — which loaded learnings covered the territory. **This file is mandatory** — do not skip it.
