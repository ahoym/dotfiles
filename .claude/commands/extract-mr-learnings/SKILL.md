---
description: Extract learnings from GitHub PRs in batches — review patterns, architectural decisions, conventions, and engineering insights from discussions and metadata.
---

# Extract PR Learnings

Systematically extract learnings from GitHub pull request history. Processes PRs in batches using parallel subagents, capturing patterns from discussion threads, reviewer feedback, and PR metadata.

## Usage

- `/extract-mr-learnings` - Continue from where the last session left off (reads plan file for progress)
- `/extract-mr-learnings init` - Initialize a new extraction plan for the current repo

## Reference Files (conditional — read only when needed)

- extractor-prompt.md — Read when spawning extractor subagents
- writer-prompt.md — Read when spawning the writer subagent

## Instructions

### Init mode (`init` arg)

1. **Verify GitHub access**:
   ```bash
   gh api "repos/{owner}/{repo}/pulls?state=all&per_page=1" | jq length
   ```

2. **Count total PRs**:
   ```bash
   gh api "repos/{owner}/{repo}/pulls?state=all&per_page=1" -i 2>&1 | grep -i 'link:'
   ```

3. **Create plan file** at `docs/plans/pr-learnings-extraction.md`:
   - Use the template in `plan-template.md`
   - Fill in repo name, PR count, output locations
   - Create output directories: `docs/learnings/`, `~/.claude/learnings/`, and `~/.claude/learnings-private/` (if not existing)

4. **Confirm with user** before proceeding to first batch.

### Continue mode (default)

1. **Read the plan file** (`docs/plans/pr-learnings-extraction.md`). If it doesn't exist, tell the user to run `/extract-mr-learnings init` first.

2. **Check progress** — find the last completed batch in the progress tracker. Calculate `NEXT_PAGE`.

3. **Glob existing learnings files** in both output locations to build `EXISTING_CATEGORIES` for subagent prompts.

4. **Fetch metadata** (1 bash call):
   ```bash
   gh api "repos/{owner}/{repo}/pulls?state=all&sort=created&direction=asc&per_page=BATCH_SIZE&page=NEXT_PAGE" | jq -c '.[] | {number, title, state, comments: .comments, user: .user.login, head_branch: .head.ref, requested_reviewers: [.requested_reviewers[].login], created_at: .created_at[:10], merged_at: (.merged_at // "n/a")[:10], body: (.body // "(none)")[:400]}'
   ```
   Store as `BATCH_METADATA`. Read `BATCH_SIZE` from the plan file (default: 10).

5. **Spawn extractor subagents** in parallel — one per PR. Read `extractor-prompt.md` and use it as a **verbatim template** — fill in placeholders but do not abbreviate, paraphrase, or add ad-hoc instructions. Every PR gets the identical template structure. **Research only — no file writes.**

6. **Spawn 3 writer subagents in parallel** with all extractor outputs concatenated to all. Read `writer-prompt.md` and use it as a **verbatim template** — fill in placeholders per writer:
   - **Project writer**: `WRITER_SCOPE=project`, `SCOPE_FILTER=project-specific`, `LEARNINGS_PATH=docs/learnings/`, files from step 3
   - **General writer**: `WRITER_SCOPE=general`, `SCOPE_FILTER=general`, `LEARNINGS_PATH=~/.claude/learnings/`, files from step 3
   - **Private writer**: `WRITER_SCOPE=private`, `SCOPE_FILTER=private`, `LEARNINGS_PATH=~/.claude/learnings-private/`, files from step 3
   - **DEDUP_GUIDANCE**: pull from the plan file's progress tracker notes (recurring pattern mentions). Do not improvise — use what's written.
   Each writer independently deduplicates against its own file set.

7. **Verify writes** — after writers complete, run targeted checks (not full file reads):
   ```bash
   # Confirm files exist and line counts grew
   wc -l docs/learnings/*.md ~/.claude/learnings/code-review-general.md ~/.claude/learnings/spring-boot.md
   # Confirm batch PR numbers appear in project files
   grep -c '#FIRST_NUMBER\|#LAST_NUMBER' docs/learnings/*.md
   # Spot-check one new entry (5 lines)
   grep -A5 'PR #<LAST_NUMBER>' docs/learnings/code-review-patterns.md | head -6
   ```
   Report any discrepancies before updating progress. Do NOT read full files — use grep for targeted checks only.

8. **Update progress tracker** — edit the plan file's progress table. This is the only write the main context performs. Include a brief note on key findings.

9. **Report batch summary** — 2-3 sentences on signal level, recurring patterns, and new categories. Keep it brief to preserve context.

## Important Notes

- **No python3 in bash commands** — use `jq` for JSON parsing. Python triggers permission prompts.
- **Context budget**: ~4 tool rounds per batch (metadata fetch, N+1 subagent spawns, verification, progress edit). Aim for 3-4 batches per session.
- **All PR states**: Include open, merged, and closed. Closed PRs capture "why not" decisions.
- **Oldest-first ordering**: Resilient to new PRs being pushed during extraction.
- **Categories emerge organically**: Don't predefine — let them form from the data. Pass existing categories to subagents so they can classify or suggest new ones.
