---
description: Analyze a large PR and propose how to split it into smaller, reviewable units
---

# Split Large PR

Analyze a large PR and propose how to split it into smaller, reviewable PRs for easier human review.

## Usage

- `/git-split-pr <PR number>` - Analyze PR and propose split strategy
- `/git-split-pr` - Analyze current branch's PR

## Instructions

1. **Fetch PR details**:
   ```bash
   gh pr view <PR> --json title,body,additions,deletions,changedFiles,files
   gh pr checkout <PR>
   git log main..HEAD --oneline
   git diff main --stat
   ```

2. **Analyze changes** - Categorize each file/change into logical units:
   - **Pure refactors**: Helper method extraction, variable renames (no behavior change)
   - **Utilities**: New standalone utility functions
   - **Package restructuring**: Moving/splitting files without new functionality
   - **New features**: Actual new functionality with tests
   - **Documentation**: README, guidelines, comments

3. **Identify dependencies** - Determine which changes depend on others:
   - Can this change be reviewed independently?
   - Does this change modify files created by another change?
   - What's the minimum merge order?

4. **Propose split** - Present a table to the user:
   ```
   | PR | Description | Branch | Target | ~Lines | Dependencies |
   |----|-------------|--------|--------|--------|--------------|
   | 1  | Extract helper methods | refactor/helpers | main | ~50 | None |
   | 2  | Add utilities | refactor/utils | main | ~40 | None |
   | 3  | Package restructure | refactor/package | main | ~600 | None |
   | 4  | New feature + tests | feature/name | PR 3 | ~1000 | PR 3 |
   ```

5. **Ask for confirmation**:
   - Present the proposal
   - Ask if user wants to proceed, modify, or post as PR comment
   - Confirm branching strategy (independent vs stacked)

6. **For stacked PRs** (when PR B modifies files PR A creates):
   - Branch B off A's branch (not main)
   - Target A as B's merge base
   - After A merges, retarget B to main

7. **Empty stubs technique** - When restructuring into a new package:
   - Create package structure with existing code
   - Add empty stub files for planned future modules
   - Merge restructure PR first
   - Implement stubs in follow-up PR

## Example Output

```
## Proposed Split: 4 PRs

### PR 1: OrderProcessor Helper Extraction (~50 lines)
**Branch:** `refactor/order-helpers` off `main` → `main`
- Extract `_validate_order()`, `_record_transaction()` helpers
- Pure refactor, no behavior change

### PR 2: Package Restructure with Stubs (~600 lines)
**Branch:** `refactor/pipeline-package` off `main` → `main`
- Split pipeline.py into package structure
- Add empty stubs for future modules

### PR 3: New Feature Implementation (~1000 lines)
**Branch:** `feature/batch-processing` off `refactor/pipeline-package` → PR 2
- Implement stub files with actual functionality
- Add tests

**Merge order:** PRs 1-2 can merge independently. After PR 2 merges, retarget PR 3 to main.
```

## Important Notes

- Use `/git-explore-pr` first if you need to understand the PR before splitting
- Aim for PRs under 400 lines when possible
- Each PR should pass all tests independently
- Keep backwards compatibility in restructuring PRs
- Include tests with their corresponding features, not in separate PRs
