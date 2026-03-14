---
description: Extract learnings from request history (GitHub PRs or GitLab MRs) in batches — review patterns, architectural decisions, conventions, and engineering insights from discussions and metadata.
---

# Extract Review Learnings

Systematically extract learnings from pull request (GitHub) or merge request (GitLab) history. Processes reviews in batches using parallel subagents, capturing patterns from discussion threads, reviewer feedback, and review metadata.

## Usage

- `/extract-request-learnings` - Continue from where the last session left off (reads plan file for progress)
- `/extract-request-learnings init` - Initialize a new extraction plan for the current repo

## Reference Files (conditional — read only when needed)

- @~/.claude/skill-references/platform-detection.md
- `~/.claude/skill-references/github-commands.md` / `gitlab-commands.md` — Platform-specific command templates (read the one matching detected platform)
- `extractor-prompt.md` — Read when spawning extractor subagents
- `writer-prompt.md` — Read when spawning the writer subagent
- `plan-template.md` — Read when initializing a new extraction plan

## Prerequisites

Writer subagents run in the background and cannot prompt for permissions. Add these allow patterns to **project-level** `.claude/settings.local.json`:

```json
"permissions": {
  "allow": [
    "Bash(gh api:*)",
    "Bash(glab api:*)",
    "Bash(jq:*)",
    "Bash(wc:*)",
    "Bash(grep:*)",
    "Read(docs/learnings/**)",
    "Read(docs/plans/**)",
    "Write(docs/learnings/**)",
    "Write(docs/plans/**)",
    "Edit(docs/learnings/**)",
    "Edit(docs/plans/**)",
    "Read(~/.claude/learnings/**)",
    "Read(~/.claude/learnings-private/**)"
  ]
}
```

General/private writers use staging directories inside the project (`docs/learnings/_staging/`) to avoid background agent write restrictions on `~/.claude/`. The orchestrator copies staged files to final locations in step 8.

## Instructions

### Init mode (`init` arg)

1. **Detect platform** — follow `@~/.claude/skill-references/platform-detection.md` to determine GitHub vs GitLab. Then read `~/.claude/skill-references/github-commands.md` or `gitlab-commands.md` (matching detected platform) for exact command templates.

2. **Verify platform access** — use **"Verify Platform Access (Batch)"** from the platform commands file, substituting `$API_CMD`.

3. **Count total reviews** — use **"Count Total Reviews"** from the platform commands file, substituting `$API_CMD`.

4. **Create plan file** at `docs/plans/$PLAN_FILENAME`:
   - Use the template in `plan-template.md`
   - Fill in repo name, review count, output locations
   - Create output directories: `docs/learnings/`, `~/.claude/learnings/`, and `~/.claude/learnings-private/` (if not existing)

5. **Confirm with user** before proceeding to first batch.

### Continue mode (default)

1. **Detect platform** (same as init step 1).

2. **Sync with remote** — `git fetch origin main`. If the current branch is behind or diverged from `origin/main`, tell the user and suggest creating a fresh branch from `origin/main`. Multi-session workflows accumulate PRs between sessions — stale branches are the expected case.

3. **Read the plan file** (`docs/plans/$PLAN_FILENAME`). If it doesn't exist, tell the user to run `/extract-review-learnings init` first.

4. **Check progress** — find the last completed batch in the progress tracker. Calculate `NEXT_PAGE`.

5. **Glob existing learnings files** in all output locations to build `EXISTING_CATEGORIES` for subagent prompts.

6. **Fetch metadata** (1 bash call) — use **"Fetch Review Metadata (Batch)"** from the platform commands file, substituting `$API_CMD`, `BATCH_SIZE`, and `NEXT_PAGE`. Store result as `BATCH_METADATA`. Read `BATCH_SIZE` from the plan file (default: 10).

7. **Spawn extractor subagents** in parallel — one per review. Read `extractor-prompt.md` and use it as a **verbatim template** — fill in placeholders but do not abbreviate, paraphrase, or add ad-hoc instructions. Every review gets the identical template structure. **Research only — no file writes.**

8. **Spawn 3 writer subagents in parallel** with all extractor outputs concatenated to all. **Re-read `writer-prompt.md` immediately before spawning** (use offset+limit for the orchestrator section, lines 1-20) — do not rely on an earlier read. Use it as a **verbatim template** — fill in placeholders per writer:
   - **Project writer**: `WRITER_SCOPE=project`, `SCOPE_FILTER=project-specific`, `READ_PATH=docs/learnings/`, `WRITE_PATH=docs/learnings/`, files from step 5
   - **General writer**: `WRITER_SCOPE=general`, `SCOPE_FILTER=general`, `READ_PATH=~/.claude/learnings/`, `WRITE_PATH=docs/learnings/_staging/general/`, files from step 5
   - **Private writer**: `WRITER_SCOPE=private`, `SCOPE_FILTER=private`, `READ_PATH=~/.claude/learnings-private/`, `WRITE_PATH=docs/learnings/_staging/private/`, files from step 5
   - **DEDUP_GUIDANCE**: pull from the plan file's progress tracker notes (recurring pattern mentions). Do not improvise — use what's written.
   Each writer independently deduplicates against its own file set.
   Create staging directories before spawning: `mkdir -p docs/learnings/_staging/general docs/learnings/_staging/private`

9. **Finalize staged files** — copy staged files to their final locations, then clean up:
   ```bash
   # Copy general learnings
   for f in docs/learnings/_staging/general/*.md; do
     [ -f "$f" ] && cp "$f" ~/.claude/learnings/
   done
   # Copy private learnings
   for f in docs/learnings/_staging/private/*.md; do
     [ -f "$f" ] && cp "$f" ~/.claude/learnings-private/
   done
   # Clean up staging
   rm -rf docs/learnings/_staging/
   ```
   This runs in the orchestrator's foreground context where `~/.claude/` is writable.

10. **Verify writes** — after finalization, run targeted checks (not full file reads):

    **GitHub:**
    ```bash
    # Confirm files exist and line counts grew
    wc -l docs/learnings/*.md ~/.claude/learnings/code-review-general.md ~/.claude/learnings/spring-boot.md
    # Confirm batch review numbers appear in project files
    grep -c '#FIRST_NUMBER\|#LAST_NUMBER' docs/learnings/*.md
    # Spot-check one new entry (5 lines)
    grep -A5 'PR #<LAST_NUMBER>' docs/learnings/code-review-patterns.md | head -6
    ```

    **GitLab:**
    ```bash
    # Confirm files exist and line counts grew
    wc -l docs/learnings/*.md ~/.claude/learnings/code-review-general.md ~/.claude/learnings/spring-boot.md
    # Confirm batch review numbers appear in project files
    grep -c '!FIRST_IID\|!LAST_IID' docs/learnings/*.md
    # Spot-check one new entry (5 lines)
    grep -A5 'MR !<LAST_IID>' docs/learnings/code-review-patterns.md | head -6
    ```

    Report any discrepancies before updating progress. Do NOT read full files — use grep for targeted checks only.

11. **Update progress tracker** — edit the plan file's progress table. Include a brief note on key findings.

12. **Report batch summary** — 2-3 sentences on signal level, recurring patterns, and new categories. Keep it brief to preserve context.

## Important Notes

- **No python3 in bash commands** — use `jq` for JSON parsing. Python triggers permission prompts.
- **Context budget**: ~4 tool rounds per batch (metadata fetch, N+1 subagent spawns, verification, progress edit). Aim for 3-4 batches per session.
- **All review states**: Include open, merged, and closed. Closed reviews capture "why not" decisions.
- **Oldest-first ordering**: Resilient to new reviews being pushed during extraction.
- **Categories emerge organically**: Don't predefine — let them form from the data. Pass existing categories to subagents so they can classify or suggest new ones.
