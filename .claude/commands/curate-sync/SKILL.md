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
| **Inventory** | Always | Single `inventory.sh` call handles inventory, classification, git history, and source-unique diffs |
| **Targeted reads** | Analysis phase | Read specific target files for cross-reference in parallel |
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

### 1. Inventory and classify

Run the inventory script to get the full picture in one pass — file bucketing, classification, git history checks, and source-unique diffs:

```bash
bash <TARGET>/.claude/commands/curate-sync/inventory.sh "<SOURCE>" "<TARGET>"
```

The script outputs structured sections that feed directly into step 2:
- `=== ONLY IN SOURCE ===` / `=== ONLY IN TARGET ===` — file lists
- `=== COMMON FILES CLASSIFICATION ===` — per-file status lines (`SUPERSET:source|...`, `BOTH_UNIQUE|...`, etc.) plus summary counts
- `=== GIT HISTORY CHECK ===` — `PREVIOUSLY_REMOVED` / `GENUINELY_NEW` for source-only files
- `=== SOURCE-UNIQUE DIFFS ===` — the actual diff content for candidates (up to 30 lines each)

Classification results:

| Status | Meaning | Next step |
|--------|---------|-----------|
| **Identical** | Same content — skip | Count for summary |
| **Only in source** | Candidate to pull — needs analysis (step 3) | Analyze |
| **Only in target** | Local content — skip | Count for summary |
| **SUPERSET:source** | Source has everything target has + more — overwrite candidate | Analyze (step 3) |
| **SUPERSET:target** | Target is already ahead — nothing to pull | Skip, count for summary |
| **BOTH_UNIQUE** | Both have unique content — merge candidate | Analyze (step 3) |

**Only these need analysis in step 3:** "only in source", "SUPERSET:source", and "BOTH_UNIQUE" files. Skip everything else.

### 2. Analyze incoming content

This step evaluates the candidates identified in step 1. Read `classification-model.md` for the full classification criteria.

#### 2a. Parse inventory output

The inventory script (step 1) already provides git history checks and source-unique diffs. Parse its output:
- `PREVIOUSLY_REMOVED: <file>` → was intentionally curated out of target
- `GENUINELY_NEW: <file>` → never existed in target, candidate to pull
- Source-unique diff content → use for the assessment in 2b

#### 2b. Assess incoming content

**Scale the analysis to the number of candidates.** Don't load the entire corpus for 2-3 candidates — use targeted checks instead.

**For ≤5 candidates (typical):**
1. For each candidate with **≤15 source-unique lines**, extract the source-unique content from the inventory diff output and use targeted `grep` searches in the target repo to check coverage
2. For each candidate with **>15 source-unique lines**, read both the source and target versions in full yourself (do NOT delegate to subagents — structural comparison requires understanding document shape, and subagents can confuse source/target directionality). Compare document structure (headings, numbered steps, format sections), not just line content. Diff excerpts hide structural gaps like missing sections, instruction steps, or format rules.
3. Read specific target files that match grep hits (not the entire corpus)

**For >5 candidates:**
1. Read `_shared/corpus-cross-reference.md` and follow its full corpus loading procedure
2. Bulk-load target skills, guidelines, and learnings
3. Cross-reference all candidates against the loaded corpus
4. Still apply the >15-line threshold — read both full files for large diffs

**For each candidate, determine:**

| Assessment | How to verify |
|------------|---------------|
| **Already covered** | `grep` for key terms/concepts in target files — if found, read that file and confirm full coverage |
| **Partially covered** | Related content exists in target but incoming adds new detail |
| **Not covered** | No matches found in target — genuinely new |
| **Outdated** | Incoming references patterns/tools that target has moved past (e.g., target genericized a Python-specific version) |

**Watch for genericization:** If the target has a stack-agnostic version of what the source has as stack-specific, the target version is better — mark source as redundant.

**Watch for structural gaps:** A term appearing in the target ecosystem doesn't mean the *same file* covers it. If the source adds a section to file X, check whether file X in the target has that section — not just whether *some other file* mentions the concept. Producer/consumer contracts (e.g., a planner skill producing a section that an executor skill consumes) are especially easy to miss with grep-only checks.

#### 2c. Assign recommendations

| Recommendation | Criteria | Default action |
|----------------|----------|----------------|
| **Pull** | New content, not covered in target, passes relevance check | Include in selection |
| **Merge** | Diverged file where source has valuable unique sections | Include in selection |
| **Skip (previously removed)** | File has git history in target — was intentionally curated out | Exclude, mention in summary |
| **Skip (redundant)** | Content is already fully covered elsewhere in target | Exclude, mention in summary |
| **Skip (outdated)** | Content references stale patterns or is superseded | Exclude, mention in summary |
| **Skip (target ahead)** | Target is already a strict superset of source | Exclude, count in summary |
| **Review** | Uncertain — could be valuable or redundant, medium confidence | Include in selection with note |

### 3. Display merge plan

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

K files identical. J files local-only. P files where target is already ahead.
```

**Action** column values:
- `Copy in` — file only exists in source, copy to target
- `Merge` — both versions have unique content, produce merged version for target
- `Overwrite` — source is a strict superset of target, replace target's version

**Assessment** column: the recommendation from step 2 with a brief rationale.

Use `AskUserQuestion` with multi-select to let user choose which items to pull.
Include the assessment and detail in each option's `description` field.

**Do NOT proceed until user selects.** If no items selected, inform user and exit.

If `$ARGUMENTS` is "diff", display both tables and exit without prompting.

### 4. Execute sync

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

### 5. Verify and report

Read back a sample of written/updated files to confirm content was saved correctly.

```
## Sync Complete: <SOURCE> → <TARGET>

**Actions taken:**
- learnings/skill-design.md — merged (4 new sections from source, preserved 6 local sections)
- commands/curate-learnings/SKILL.md — merged (preserved unique edits from both)

**Skipped:**
- learnings/observability-workflow.md — previously removed
- learnings/old-patterns.md — redundant

Pulled N items. K identical. J local-only. P target-ahead. M skipped (analyzed).
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
- **Genericization awareness**: If target has a stack-agnostic version of stack-specific source content, the target version is better — source is marked redundant
- **User approval required**: Always use `AskUserQuestion` before applying changes
- **Local content preserved**: Files only in the current repo are left alone — they're local additions, not deletions
- **Excludes respected**: settings.json, settings.local.json, README.md, lab/, personas/, worktrees/ are never synced
- **Content-aware merge**: For diverged files, Claude reads both versions and produces a clean union rather than picking a winner
- **Strict superset detection**: When the source contains everything the target has plus more, skip the merge and just overwrite — simpler and faster
- **Complements curate-learnings**: Run `/curate-learnings` after sync to prune or reorganize the pulled content
