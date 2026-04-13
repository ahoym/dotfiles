---
name: extract-request-learnings
description: Extract learnings from request history (GitHub PRs or GitLab MRs) in batches — review patterns, architectural decisions, conventions, and engineering insights from discussions and metadata.
---

# Extract Review Learnings

Systematically extract learnings from pull request (GitHub) or merge request (GitLab) history. Processes reviews in batches using parallel subagents, capturing patterns from discussion threads, reviewer feedback, and review metadata.

## Usage

- `/extract-request-learnings` - Continue from where the last session left off (reads plan file for progress)
- `/extract-request-learnings init` - Initialize a new extraction plan for the current repo

## Reference Files (conditional — read only when needed)

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
    "Read(~/.claude/learnings*/**)",
    "Read(~/.claude/learnings-providers.json)"
  ]
}
```

General/private writers use staging directories inside the project (`docs/learnings/_staging/`) to avoid background agent write restrictions on `~/.claude/`. The orchestrator copies staged files to final locations in step 8.

## Instructions

### Init mode (`init` arg)

1. **Verify platform access:**
   !`cat ~/.claude/platform-commands/verify-platform-access.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`

2. **Count total reviews:**
   !`cat ~/.claude/platform-commands/count-total-reviews.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`

4. **Create plan file** at `docs/plans/$PLAN_FILENAME`:
   - Use the template in `plan-template.md`
   - Fill in repo name, review count, output locations
   - Read `~/.claude/learnings-providers.json` and create output directories: `docs/learnings/` and each provider's `localPath` directory (if not existing)

5. **Confirm with the operator** before proceeding to first batch.

### Continue mode (default)

1. **Detect platform** (same as init step 1).

2. **Sync with remote** — `git fetch origin main`. If the current branch is behind or diverged from `origin/main`, tell the operator and suggest creating a fresh branch from `origin/main`. Multi-session workflows accumulate PRs between sessions — stale branches are the expected case.

3. **Read the plan file** (`docs/plans/$PLAN_FILENAME`). If it doesn't exist, tell the operator to run `/extract-review-learnings init` first.

4. **Check progress** — find the last completed batch in the progress tracker. Calculate `NEXT_PAGE`.

5. **Glob existing learnings files** in all output locations to build `EXISTING_CATEGORIES` for subagent prompts.

6. **Fetch metadata** (1 bash call) — use the batch fetch command, substituting `BATCH_SIZE` and `NEXT_PAGE`. Store result as `BATCH_METADATA`. Read `BATCH_SIZE` from the plan file (default: 10).
   !`cat ~/.claude/platform-commands/batch-fetch-reviews.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`

7. **Triage and spawn extractor subagents** in parallel. Read `extractor-prompt.md` and use it as a **verbatim template** — fill in placeholders but do not abbreviate, paraphrase, or add ad-hoc instructions. Every review gets the identical template structure. **Research only — no file writes.**

   **Triage into three tiers based on metadata:**
   - **Dedicated extractor** (1 MR per agent): `user_notes_count > 10`, OR description signals a new module/adapter/integration (keywords: "new module", "new adapter", "integration", "implement", "complete implementation"), OR state is `closed` with `user_notes_count >= 5` (rich "why not" signal)
   - **Small-group extractor** (3-5 MRs per agent): `user_notes_count` 2-10, OR zero-discussion but description indicates substantial work (refactors, multi-file fixes, feature additions with filled-in descriptions)
   - **Skip entirely**: Dependency version bumps with empty descriptions, SDK releases with no changes, drafts closed immediately with 0 notes and no commits, reference data additions (asset lists, SQL data inserts)

   **Key principle**: Discussion notes are the easiest signal but not the only one. Implementation patterns in the diff are equally valuable — a 30-file, 0-note MR introducing a new adapter has more signal than a 1-file, 5-note MR where all notes are bot approval + SonarQube. Triage on the *work*, not just the *discussion*.

8. **Spawn 3 writer subagents in parallel** with all extractor outputs concatenated to all. **Re-read `writer-prompt.md` immediately before spawning** (use offset+limit for the orchestrator section, lines 1-20) — do not rely on an earlier read. Use it as a **verbatim template** — fill in placeholders per writer:
   - **Project writer**: `WRITER_SCOPE=project`, `SCOPE_FILTER=project-specific`, `READ_PATH=docs/learnings/`, `WRITE_PATH=docs/learnings/`, files from step 5
   - **General writer**: `WRITER_SCOPE=general`, `SCOPE_FILTER=general`, `READ_PATH=<defaultWriteTarget provider localPath>`, `WRITE_PATH=docs/learnings/_staging/general/`, files from step 5 (read `~/.claude/learnings-providers.json` to find the provider with `defaultWriteTarget: true`)
   - **Private writer**: `WRITER_SCOPE=private`, `SCOPE_FILTER=private`, `READ_PATH=<private provider localPath>`, `WRITE_PATH=docs/learnings/_staging/private/`, files from step 5 (read `~/.claude/learnings-providers.json` to find the provider with `writeScope: "private"`)
   - **DEDUP_GUIDANCE**: pull from the plan file's progress tracker notes (recurring pattern mentions). Do not improvise — use what's written.
   Each writer independently deduplicates against its own file set.
   Create staging directories before spawning: `mkdir -p docs/learnings/_staging/general docs/learnings/_staging/private`

9. **Finalize staged files** — run the finalize script to copy staged files to their final locations and clean up:
   ```bash
   bash ~/.claude/commands/extract-request-learnings/finalize-staging.sh .
   ```
   This script reads `~/.claude/learnings-providers.json` to discover provider directories, copies general learnings to all writable providers with `writeScope: "global"`, private learnings to providers with `writeScope: "private"`, handles `java/` subdirectories, and removes the staging directory. It's pre-allowed via `Bash(bash ~/.claude/commands/**)` so it runs without permission prompts.

   **Do NOT use inline `cp` commands** — the sandbox treats `~/.claude/` as sensitive and will prompt for each file regardless of allow patterns.

10. **Verify writes** — after finalization, run targeted checks (not full file reads):

    **GitHub:**
    ```bash
    # Confirm files exist and line counts grew
    wc -l docs/learnings/*.md ~/.claude/learnings*/*.md
    # Confirm batch review numbers appear in project files
    grep -c '#FIRST_NUMBER\|#LAST_NUMBER' docs/learnings/*.md
    # Spot-check one new entry (5 lines)
    grep -A5 'PR #<LAST_NUMBER>' docs/learnings/*.md | head -6
    ```

    **GitLab:**
    ```bash
    # Confirm files exist and line counts grew
    wc -l docs/learnings/*.md ~/.claude/learnings*/*.md
    # Confirm batch review numbers appear in project files
    grep -c '!FIRST_IID\|!LAST_IID' docs/learnings/*.md
    # Spot-check one new entry (5 lines)
    grep -A5 'MR !<LAST_IID>' docs/learnings/*.md | head -6
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
