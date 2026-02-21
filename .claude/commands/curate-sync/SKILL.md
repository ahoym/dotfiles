---
description: Intelligently sync and merge Claude skills, learnings, and guidelines between dotfiles and mahoy-claude-stuff
---

# Curate Sync

Intelligently merge diverged content between `dotfiles` and `mahoy-claude-stuff` repos. Unlike a blunt rsync, this preserves improvements from both sides by doing content-aware merging of diverged files.

## Usage

- `/curate-sync` - Full sync with interactive merge
- `/curate-sync diff` - Preview only (no changes applied)

## Configuration

```
DOTFILES="/Users/malcolmahoy/WORKSPACE/dotfiles"
MAHOY="/Users/malcolmahoy/WORKSPACE/mahoy-claude-stuff"

SYNC_DIRS=(
  ".claude/commands/"
  ".claude/guidelines/"
  ".claude/learnings/"
  "docs/claude-learnings/"
)

EXCLUDES=(
  "settings.json"
  "settings.local.json"
  "README.md"
  "lab/"
  "personas/"
  "worktrees/"
)
```

## Parallel Execution

| Opportunity | When | How |
|---|---|---|
| **Inventory both repos** | Always | Glob all sync dirs in both repos in one parallel batch |
| **Read file pairs** | Diverged files detected | Read both versions of each file in parallel |
| **Apply merges** | After approval | Write to independent files as parallel tool calls |

## Instructions

### 1. Inventory both repos

**⚡ Parallel:** Glob all sync directories in both repos simultaneously — 8 Glob calls in one batch.

For each directory in `SYNC_DIRS`:
- Glob `<DOTFILES>/<dir>**/*.md` and `<MAHOY>/<dir>**/*.md`
- Exclude files/dirs matching `EXCLUDES`
- Build a unified file list keyed by relative path (relative to the sync dir)

### 2. Classify each file

For each unique relative path found across both repos:
1. Check if it exists in dotfiles, mahoy, or both
2. If both exist, read both files and compare content

**⚡ Parallel:** Read all file pairs for comparison in a single batch.

Classify into:

| Status | Meaning |
|--------|---------|
| **Identical** | Same content in both repos — no action needed |
| **Only in dotfiles** | Exists only in dotfiles — candidate to copy to mahoy |
| **Only in mahoy** | Exists only in mahoy — candidate to copy to dotfiles |
| **Diverged** | Both exist with different content — needs merge |

For **diverged** files, further assess:
- Which version is larger (more content)
- Identify sections unique to each version (by H2/H3 headers for learnings/guidelines, by numbered steps for skills)
- Determine if one is a **strict superset** of the other (simple overwrite) vs both have unique content (needs content-aware merge)

### 3. Display merge plan

**ALWAYS use a markdown table** — never prose paragraphs to list items.

```
## Sync Plan: dotfiles ↔ mahoy-claude-stuff

### Files needing action: N (of M total)

| # | File | Status | Action | Detail |
|---|------|--------|--------|--------|
| 1 | learnings/skill-design.md | Diverged | Merge → both | dotfiles +6 sections, mahoy +0 unique |
| 2 | learnings/observability-workflow.md | Only in mahoy | Copy → dotfiles | 1KB, observability patterns |
| 3 | commands/curate-learnings/SKILL.md | Diverged | Merge → both | Both have unique edits |
| 4 | learnings/parallel-plans.md | Diverged | Overwrite mahoy | dotfiles is strict superset |

K files identical (skipped).
```

**Action** column values:
- `Copy → dotfiles` — file only exists in mahoy, copy it
- `Copy → mahoy` — file only exists in dotfiles, copy it
- `Merge → both` — both versions have unique content, produce merged version for both repos
- `Overwrite mahoy` — dotfiles is a strict superset, copy dotfiles version to mahoy
- `Overwrite dotfiles` — mahoy is a strict superset, copy mahoy version to dotfiles

Use `AskUserQuestion` with multi-select to let user choose which items to sync.
Include status and action detail in each option's `description` field.

**Do NOT proceed until user selects.** If no items selected, inform user and exit.

If `$ARGUMENTS` is "diff", display the table and exit without prompting.

### 4. Execute sync

For each selected item:

**Copy items** (only in one repo):
- Read the source file
- Write to the destination path
- Create parent directories if needed

**Overwrite items** (one is a strict superset):
- Read the superset version
- Write to the other repo's path

**Diverged items** (both have unique content) — this is the core value of this skill:

1. Read both versions fully
2. Identify the document structure:
   - Learnings/guidelines: H2/H3 sections
   - Skills (SKILL.md): YAML frontmatter + titled sections + numbered instruction steps
   - Reference files: varies — use heading structure
3. For each section:
   - **Only in version A**: Include in merged output
   - **Only in version B**: Include in merged output
   - **In both, identical**: Include once
   - **In both, different content**: Merge:
     - For learnings/guidelines: union the bullet points, deduplicate, keep the more detailed version of overlapping points
     - For skills: preserve the more refined version of each step while including steps unique to either version
     - For reference files: prefer the more complete version, append unique content from the other
4. Write the merged version to **both repos**

**⚡ Parallel:** Writes to independent files can run as parallel tool calls.

### 5. Verify and report

Read back a sample of written/updated files to confirm content was saved correctly.

```
## Sync Complete: dotfiles ↔ mahoy-claude-stuff

**Actions taken:**
- learnings/skill-design.md — merged (6 sections from dotfiles + 0 from mahoy)
- learnings/observability-workflow.md — copied to dotfiles
- commands/curate-learnings/SKILL.md — merged (preserved unique edits from both)

Synced N items. K files were already identical.
```

## Prerequisites

For prompt-free execution, add these allow patterns to **user-level** `~/.claude/settings.local.json`:

```json
"Read(~/WORKSPACE/dotfiles/.claude/**)",
"Read(~/WORKSPACE/dotfiles/docs/**)",
"Read(~/WORKSPACE/mahoy-claude-stuff/.claude/**)",
"Read(~/WORKSPACE/mahoy-claude-stuff/docs/**)",
"Write(~/WORKSPACE/dotfiles/.claude/**)",
"Write(~/WORKSPACE/dotfiles/docs/**)",
"Write(~/WORKSPACE/mahoy-claude-stuff/.claude/**)",
"Write(~/WORKSPACE/mahoy-claude-stuff/docs/**)",
"Edit(~/WORKSPACE/dotfiles/.claude/**)",
"Edit(~/WORKSPACE/dotfiles/docs/**)",
"Edit(~/WORKSPACE/mahoy-claude-stuff/.claude/**)",
"Edit(~/WORKSPACE/mahoy-claude-stuff/docs/**)"
```

## Important Notes

- **User approval required**: Always use `AskUserQuestion` before applying changes — never auto-merge without consent
- **Both repos get the merged version**: Diverged files are merged and written to both repos, keeping them in sync going forward
- **Excludes respected**: settings.json, settings.local.json, README.md, lab/, personas/, worktrees/ are never synced
- **Non-destructive**: Files only in one repo are copied to the other, never deleted from the source
- **Content-aware merge**: Claude reads and understands both versions to produce a clean union, rather than picking a winner
- **Strict superset detection**: When one version contains everything the other has plus more, skip the merge and just overwrite — simpler and faster
- **Complements curate-learnings**: Run `/curate-learnings` after sync to prune or reorganize the merged content
- **Replaces sync-claude-skills.sh**: This skill supersedes the old rsync-based script
