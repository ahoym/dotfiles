---
description: Pull and merge Claude skills, learnings, and guidelines from a sync source into the current repo
---

# Curate Sync

Pull content from a configured sync source into the current repo. Analyzes incoming changes for relevance and redundancy before offering them, and does content-aware merging for diverged files.

## Usage

- `/curate-sync` - Pull and merge from sync source
- `/curate-sync diff` - Preview only (no changes applied)

## Configuration

The sync source is configured in the current repo's `CLAUDE.md` via a `sync-source:` field:

```markdown
sync-source: ~/WORKSPACE/mahoy-claude-stuff
```

The skill reads this on startup. If missing, it errors with instructions to add it.

```
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

## Reference Files (conditional)

- `~/.claude/commands/_shared/corpus-cross-reference.md` — Read in step 3 for corpus loading and cross-referencing procedure
- `~/.claude/commands/curate-learnings/classification-model.md` — Read in step 3 for classifying incoming content

## Parallel Execution

| Opportunity | When | How |
|---|---|---|
| **Inventory both dirs** | Always | List all sync dirs in both source and target in one parallel batch |
| **Read file pairs** | Diverged files detected | Read both versions of each file in parallel |
| **Git history + content reads** | Analysis phase | Check git history and read incoming content in parallel |
| **Apply merges** | After approval | Write to independent files as parallel tool calls |

## Instructions

### 0. Detect source and target

1. Run `git rev-parse --show-toplevel` to find the current repo root → `TARGET`
2. Read `<TARGET>/CLAUDE.md` and parse the `sync-source:` value → `SOURCE`
   - Expand `~` to the user's home directory
   - Verify `SOURCE` exists and contains at least one of the `SYNC_DIRS`
   - If `sync-source:` is not found, error:
     ```
     No sync source configured. Add this to your CLAUDE.md:

     sync-source: /path/to/source/repo
     ```

### 1. Inventory both directories

**⚡ Parallel:** List all sync directories in both source and target simultaneously.

For each directory in `SYNC_DIRS`:
- List all `*.md` files recursively in `<SOURCE>/<dir>` and `<TARGET>/<dir>`
- Exclude files/dirs matching `EXCLUDES`
- Build a unified file list keyed by relative path

### 2. Classify each file

For each unique relative path found:
1. Check if it exists in source, target, or both
2. If both exist, read both files and compare content

**⚡ Parallel:** Read all file pairs for comparison in a single batch.

Classify into:

| Status | Meaning |
|--------|---------|
| **Identical** | Same content in both — skip |
| **Only in source** | Exists only in source — needs analysis before offering |
| **Only in target** | Exists only in current repo — local-only, leave it alone |
| **Diverged** | Both exist with different content — needs analysis + merge |

For **diverged** files, further assess:
- Which version is larger (more content)
- Identify sections unique to each version (by H2/H3 headers for learnings/guidelines, by numbered steps for skills)
- Determine if source is a **strict superset** of target (simple overwrite candidate) vs both have unique content (needs content-aware merge)
- For strict supersets where target is already ahead: skip — nothing new to pull

### 3. Analyze incoming content

This step evaluates every candidate before presenting it. Read `classification-model.md` for the full classification criteria.

**⚡ Parallel:** Run git history checks and content reads in one batch.

#### 3a. Check git history for "only in source" files

For each file that exists only in source:
- Run `git log --all --oneline -- <relative-path>` in the target repo
- If commits are found → file was **previously removed** from target (intentional curation)
- If no commits → file is **genuinely new** (never existed in target)

#### 3b. Assess incoming content

Read `_shared/corpus-cross-reference.md` and follow its procedure to load the target corpus and cross-reference incoming content.

For each candidate (new files + source-unique sections from diverged files):

1. **Read the incoming content** — the full file for "only in source", or just the source-unique sections for diverged files
2. **Cross-reference against target's corpus** using the procedure in `corpus-cross-reference.md`:
   - Load the corpus (skills, guidelines, learnings) if not already loaded
   - For each incoming section, assess coverage using the match types (exact, partial, thematic, no match)
   - Use the confidence levels to determine how certain the assessment is
3. **Assign a recommendation:**

| Recommendation | Criteria | Default action |
|----------------|----------|----------------|
| **Pull** | New content, not covered in target, passes relevance check | Include in selection |
| **Merge** | Diverged file where source has valuable unique sections | Include in selection |
| **Skip (previously removed)** | File has git history in target — was intentionally curated out | Exclude from selection, mention in summary |
| **Skip (redundant)** | Content is already fully covered elsewhere in target | Exclude from selection, mention in summary |
| **Skip (outdated)** | Content references stale patterns or is superseded | Exclude from selection, mention in summary |
| **Review** | Uncertain — could be valuable or redundant, medium confidence | Include in selection with note |

### 4. Display merge plan

**ALWAYS use a markdown table** — never prose paragraphs to list items.

```
## Sync Plan: pulling from <SOURCE> into <TARGET>

### Files to pull: N

| # | File | Status | Action | Assessment | Detail |
|---|------|--------|--------|------------|--------|
| 1 | learnings/skill-design.md | Diverged | Merge | Pull — 4 new sections not in target | source +4, target +82 |
| 2 | commands/curate-learnings/SKILL.md | Diverged | Merge | Review — source has minor edits, unclear value | source +15, target +149 |
| 3 | learnings/new-topic.md | New | Copy in | Pull — genuinely new, not covered | 2KB, new patterns |

### Skipped: M files

| File | Reason |
|------|--------|
| learnings/observability-workflow.md | Previously removed (curated out in commit abc123) |
| learnings/old-patterns.md | Redundant — covered by skill-design.md |

K files identical. J files local-only.
```

**Action** column values:
- `Copy in` — file only exists in source, copy to target
- `Merge` — both versions have unique content, produce merged version for target
- `Overwrite` — source is a strict superset of target, replace target's version

**Assessment** column: the recommendation from step 3 with a brief rationale.

Use `AskUserQuestion` with multi-select to let user choose which items to pull.
Include the assessment and detail in each option's `description` field.

**Do NOT proceed until user selects.** If no items selected, inform user and exit.

If `$ARGUMENTS` is "diff", display both tables and exit without prompting.

### 5. Execute sync

For each selected item:

**Copy items** (only in source):
- Read the source file
- Write to the target path
- Create parent directories if needed

**Overwrite items** (source is a strict superset):
- Read the source version
- Write to the target path

**Diverged items** (both have unique content) — this is the core value of this skill:

1. Read both versions fully
2. Identify the document structure:
   - Learnings/guidelines: H2/H3 sections
   - Skills (SKILL.md): YAML frontmatter + titled sections + numbered instruction steps
   - Reference files: varies — use heading structure
3. For each section:
   - **Only in source**: Include in merged output
   - **Only in target**: Include in merged output (preserve local additions)
   - **In both, identical**: Include once
   - **In both, different content**: Merge:
     - For learnings/guidelines: union the bullet points, deduplicate, keep the more detailed version of overlapping points
     - For skills: preserve the more refined version of each step while including steps unique to either version
     - For reference files: prefer the more complete version, append unique content from the other
4. Write the merged version to target

**⚡ Parallel:** Writes to independent files can run as parallel tool calls.

### 6. Verify and report

Read back a sample of written/updated files to confirm content was saved correctly.

```
## Sync Complete: <SOURCE> → <TARGET>

**Actions taken:**
- learnings/skill-design.md — merged (4 new sections from source, preserved 6 local sections)
- commands/curate-learnings/SKILL.md — merged (preserved unique edits from both)

**Skipped:**
- learnings/observability-workflow.md — previously removed
- learnings/old-patterns.md — redundant

Pulled N items. K identical. J local-only. M skipped (analyzed).
```

## Prerequisites

For prompt-free execution, ensure allow patterns in `~/.claude/settings.local.json` cover both the source and target paths for Read/Write/Edit on the `SYNC_DIRS`. For example:

```json
"Read(~/WORKSPACE/dotfiles/.claude/**)",
"Read(~/WORKSPACE/dotfiles/docs/**)",
"Read(~/WORKSPACE/mahoy-claude-stuff/.claude/**)",
"Read(~/WORKSPACE/mahoy-claude-stuff/docs/**)",
"Write(.claude/**)",
"Write(docs/**)",
"Edit(.claude/**)",
"Edit(docs/**)"
```

## Important Notes

- **Pull-only**: This skill only writes to the current repo — it never modifies the source
- **Analysis before action**: Every candidate is assessed for relevance, redundancy, and history before being offered
- **Previously removed detection**: Uses git history to identify files that were intentionally curated out — these are skipped by default
- **User approval required**: Always use `AskUserQuestion` before applying changes
- **Local content preserved**: Files only in the current repo are left alone — they're local additions, not deletions
- **Excludes respected**: settings.json, settings.local.json, README.md, lab/, personas/, worktrees/ are never synced
- **Content-aware merge**: For diverged files, Claude reads both versions and produces a clean union rather than picking a winner
- **Strict superset detection**: When the source contains everything the target has plus more, skip the merge and just overwrite — simpler and faster
- **Complements curate-learnings**: Run `/curate-learnings` after sync to prune or reorganize the pulled content
