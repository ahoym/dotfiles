---
name: split-request
description: "Analyze a large request (PR or MR) and propose how to split it into smaller, reviewable units."
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Split Large Review

Analyze a large review and propose how to split it into smaller, reviewable units for easier human review.

## Usage

- `/git:split-request <number>` - Analyze review and propose split strategy
- `/git:split-request` - Analyze current branch's review

## Reference Files (conditional — read only when needed)

- @~/.claude/skill-references/platform-detection.md
- `~/.claude/skill-references/github-commands.md` / `gitlab-commands.md` — Platform-specific command templates (read the one matching detected platform)

## Instructions

1. **Detect platform** — follow `@~/.claude/skill-references/platform-detection.md` to determine GitHub vs GitLab. Then read `~/.claude/skill-references/github-commands.md` or `gitlab-commands.md` (matching detected platform) for exact command templates.

2. **Fetch review details**:
   ```bash
   $VIEW_CMD <number> $VIEW_JSON_FLAGS
   $CHECKOUT_CMD <number>
   git log main..HEAD --oneline
   git diff main --stat
   ```

3. **Analyze changes** — Categorize each file/change into logical units:
   - **Pure refactors**: Helper method extraction, variable renames (no behavior change)
   - **Utilities**: New standalone utility functions
   - **Package restructuring**: Moving/splitting files without new functionality
   - **New features**: Actual new functionality with tests
   - **Documentation**: README, guidelines, comments

4. **Identify dependencies** — Determine which changes depend on others:
   - Can this change be reviewed independently?
   - Does this change modify files created by another change?
   - What's the minimum merge order?

5. **Propose split** — Present a table to the user:
   ```
   | $REVIEW_UNIT | Description | Branch | Target | ~Lines | Dependencies |
   |--------------|-------------|--------|--------|--------|--------------|
   | 1  | Extract helper methods | refactor/helpers | main | ~50 | None |
   | 2  | Add utilities | refactor/utils | main | ~40 | None |
   | 3  | Package restructure | refactor/package | main | ~600 | None |
   | 4  | New feature + tests | feature/name | $REVIEW_UNIT 3 | ~1000 | $REVIEW_UNIT 3 |
   ```

6. **Ask for confirmation**:
   - Present the proposal
   - Ask if user wants to proceed, modify, or post as review comment
   - Confirm branching strategy (independent vs stacked)

7. **For stacked reviews** (when review B modifies files review A creates):
   - Branch B off A's branch (not main)
   - Target A as B's merge base
   - After A merges, retarget B to main

8. **Empty stubs technique** — When restructuring into a new package:
   - Create package structure with existing code
   - Add empty stub files for planned future modules
   - Merge restructure review first
   - Implement stubs in follow-up review

## Example Output

```
## Proposed Split: 4 $REVIEW_UNITs

### $REVIEW_UNIT 1: OrderProcessor Helper Extraction (~50 lines)
**Branch:** `refactor/order-helpers` off `main` → `main`
- Extract `_validate_order()`, `_record_transaction()` helpers
- Pure refactor, no behavior change

### $REVIEW_UNIT 2: Package Restructure with Stubs (~600 lines)
**Branch:** `refactor/pipeline-package` off `main` → `main`
- Split pipeline.py into package structure
- Add empty stubs for future modules

### $REVIEW_UNIT 3: New Feature Implementation (~1000 lines)
**Branch:** `feature/batch-processing` off `refactor/pipeline-package` → $REVIEW_UNIT 2
- Implement stub files with actual functionality
- Add tests

**Merge order:** $REVIEW_UNITs 1-2 can merge independently. After $REVIEW_UNIT 2 merges, retarget $REVIEW_UNIT 3 to main.
```

## When to Use This vs `/git:repoint-branch`

- **`/git:split-request`** — You have a large review and need help figuring out *how* to split it. This skill analyzes the diff, categorizes changes, identifies dependencies, and proposes a split strategy.
- **`/git:repoint-branch`** — You already know which files to extract. This skill creates a new branch from main with those specific files and optionally opens a review.

Typical flow: `/git:split-request` to plan → `/git:repoint-branch` to execute each proposed split.

## Important Notes

- Use `/git:explore-request` first if you need to understand the review before splitting
- Aim for reviews under 400 lines when possible
- Each review should pass all tests independently
- Keep backwards compatibility in restructuring reviews
- Include tests with their corresponding features, not in separate reviews
