---
name: init
description: "Initialize an autonomous consolidation loop with worktree, output scaffolding, and pre-flight checks."
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
---

# Initialize Consolidation Loop

Create a worktree for autonomous consolidation, scaffold output files from templates, run pre-flight checks, and print the launch command.

## Instructions

### 1. Derive names

- **Date**: today's date in `YYYY-MM-DD` format
- **Worktree path**: `.claude/worktrees/consolidate-<date>`
- **Branch**: `consolidate/<date>`

### 2. Check for existing worktree

If `.claude/worktrees/consolidate-<date>/` already exists, offer:
1. **Reuse** — keep existing worktree, skip creation
2. **Remove and recreate** — `git worktree remove` then create fresh
3. **Abort** — do nothing

### 3. Create worktree

```bash
git worktree add .claude/worktrees/consolidate-<date> -b consolidate/<date> HEAD
```

If the branch `consolidate/<date>` already exists, use it without `-b`:
```bash
git worktree add .claude/worktrees/consolidate-<date> consolidate/<date>
```

### 4. Scaffold output files

Create the output directory in the worktree:
```bash
mkdir -p .claude/worktrees/consolidate-<date>/.claude/consolidate-output
```

Read each template from `~/.claude/ralph/consolidate/templates/` and write to the worktree's `.claude/consolidate-output/`:

| Template | Destination |
|----------|-------------|
| `spec.md` | `.claude/consolidate-output/spec.md` |
| `progress.md` | `.claude/consolidate-output/progress.md` |
| `decisions.md` | `.claude/consolidate-output/decisions.md` |
| `blockers.md` | `.claude/consolidate-output/blockers.md` |
| `report.md` | `.claude/consolidate-output/report.md` |
| `lows.md` | `.claude/consolidate-output/lows.md` |
| `compounded-learnings.md` | `.claude/consolidate-output/compounded-learnings.md` |

Copy each template as-is first. Pre-flight data is populated next.

### 5. Run pre-flight

Gather collection metrics:

1. **Recent commits**: `git log --oneline -10` — check if collection was recently curated
2. **File counts** (use Glob in the worktree):
   - Learnings: `.claude/worktrees/consolidate-<date>/.claude/learnings/*.md`
   - Skills: `.claude/worktrees/consolidate-<date>/.claude/commands/**/SKILL.md`
   - Guidelines: `.claude/worktrees/consolidate-<date>/.claude/guidelines/*.md`
   - Personas: `.claude/worktrees/consolidate-<date>/.claude/commands/set-persona/*.md`

3. **Cadence analysis** — scan the last 10 commits for curation-related keywords (`curate`, `compress`, `fold`, `genericize`, `deduplicate`, `prune`, `consolidat`). Count how many of the last 5 commits are curation commits. Classify:
   - **Recent** (3+ of last 5): suggest 10 iterations — corpus likely clean
   - **Moderate** (1-2 of last 5): suggest 15 iterations — some staleness possible
   - **Stale** (0 of last 5): suggest 20 iterations — full sweep warranted

4. **Update progress.md** — replace the Pre-Flight section placeholders with actual values:
   ```
   Recent commits: <last 3 commit summaries>
   Learnings files: N
   Skills count: N
   Guidelines files: N
   Persona files: N
   Cadence: <recent|moderate|stale> (<X> curation commits in last 5)
   Suggested iterations: N
   ```

5. **Update report.md** — populate Run Info and Collection Health "Before" column:
   - Started: current timestamp
   - Branch: `consolidate/<date>`
   - Worktree: `.claude/worktrees/consolidate-<date>`
   - Collection Health Before: file counts from step 2

### 6. Confirm to user

```
Consolidation loop initialized.

  Worktree: .claude/worktrees/consolidate-<date>/
  Branch:   consolidate/<date>

  Pre-flight:
    Recent commits: <summary — note if recently curated>
    Learnings:  N files
    Skills:     N directories
    Guidelines: N files
    Personas:   N files

  Cadence: <recent|moderate|stale> (<X> curation commits in last 5)

  To launch:
    cd .claude/worktrees/consolidate-<date>
    bash ~/.claude/ralph/consolidate/wiggum.sh <suggested_iterations>
```

## Example

```
/ralph:consolidate:init

Consolidation loop initialized.

  Worktree: .claude/worktrees/consolidate-2026-02-26/
  Branch:   consolidate/2026-02-26

  Pre-flight:
    Recent commits: ce44582 Compress allowed-tools... (curation 2 commits ago)
    Learnings:  12 files
    Skills:     23 directories
    Guidelines: 3 files
    Personas:   4 files
    Cadence: recent (3 curation commits in last 5)

  To launch:
    cd .claude/worktrees/consolidate-2026-02-26
    bash ~/.claude/ralph/consolidate/wiggum.sh 10
```
