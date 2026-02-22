---
description: "Close a redundant PR and extract unique content into a new focused PR."
---

# Close Redundant PR

Close a PR that became redundant after a similar PR merged, then extract any unique content worth preserving.

## Usage

- `/close-redundant-pr <pr-number>` - Process the specified PR
- `/close-redundant-pr` - Will prompt for PR number

## When to Use

Two PRs modify the same files differently, one merges first, and the other has content worth preserving.

## Reference Files (conditional — read only when needed)

- @../_shared/platform-detection.md - Platform detection for GitHub/GitLab

## Instructions

0. **Detect platform** — follow `@../_shared/platform-detection.md` to determine GitHub vs GitLab. Set `CLI`, `REVIEW_UNIT`, and API command patterns accordingly. All commands below use GitHub (`gh`) syntax; substitute GitLab equivalents if on GitLab.

1. **Get PR number**:
   - If `$ARGUMENTS` provided, use as PR number
   - Otherwise, ask: "Which PR number should be closed as redundant?"

2. **Get context**:
   - Ask: "Which PR was merged that made this one redundant? (e.g., #XX)"
   - Store as `MERGED_PR`

3. **Compare branches to identify unique content**:
   ```bash
   gh pr view <pr-number> --json headRefName --jq '.headRefName'
   ```
   Store as `REDUNDANT_BRANCH`

   ```bash
   git fetch origin main <REDUNDANT_BRANCH>
   git diff origin/main origin/<REDUNDANT_BRANCH>
   ```

4. **Analyze the diff**:
   - Identify which changes are already in main (from the merged PR)
   - Identify which changes are unique to this PR
   - Report findings to user

5. **Ask user about unique content**:
   - If unique content found: "Found unique content in: <files>. Create a new PR for this content?"
   - If no unique content: "No unique content found. Proceed to close the PR?"

6. **Close the redundant PR**:
   ```bash
   gh pr close <pr-number> --comment "Closing as redundant after #<MERGED_PR> merged. Unique content will be cherry-picked to a new PR."
   ```

   Or if no unique content:
   ```bash
   gh pr close <pr-number> --comment "Closing as redundant after #<MERGED_PR> merged."
   ```

7. **Create new branch for unique content** (if applicable):
   ```bash
   git checkout main && git pull
   git checkout -b feature/<descriptive-name>
   ```

   Ask user: "What should the new branch be named?"

8. **Apply unique content**:
   - Manually add the unique content (don't cherry-pick if files diverged)
   - Stage and commit changes
   - Push and create focused PR:
   ```bash
   git push -u origin <new-branch>
   gh pr create --base main
   ```

## Example

```
Processing PR #15...

Comparing feature/full-implementation to main...

Already in main (from #12):
  - backtesting/metrics.py: CAGR calculation
  - backtesting/result.py: Trade dataclass

Unique to PR #15:
  - backtesting/charts.py: Drawdown visualization
  - docs/metrics.md: Documentation

Create a new PR for the unique content? (y/n)
> y

Branch name for new PR: feature/drawdown-charts

Created branch, applied changes, and opened PR #16.
Closed PR #15 with comment referencing #12.
```

## Important Notes

- Use `/git:explore-pr` first if you need to understand the PR before closing
- Always compare against main to see what's truly unique
- Don't cherry-pick if files have diverged significantly - manually apply changes instead
- Reference the merged PR in the close comment for traceability
