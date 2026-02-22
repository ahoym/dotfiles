---
description: Preview merge conflicts between branches without merging
---

# Preview Conflicts

Preview merge conflicts between two branches without actually merging.

## Usage

- `/preview-conflicts` - Check current branch against its base (main)
- `/preview-conflicts <branch>` - Check current branch against specified branch
- `/preview-conflicts <branch-a> <branch-b>` - Check between two specific branches

## Instructions

1. **Parse arguments**:
   - No args: current branch vs `origin/main`
   - One arg: current branch vs specified branch
   - Two args: first branch vs second branch

2. **Fetch latest**:
   ```bash
   git fetch origin <branches>
   ```

3. **Run merge-tree to preview conflicts**:
   ```bash
   git merge-tree $(git merge-base origin/<branch-a> origin/<branch-b>) origin/<branch-a> origin/<branch-b>
   ```

4. **Parse and report results**:
   - Look for "changed in both" sections - these are conflicts
   - If no conflicts: "No conflicts detected. Safe to merge."
   - If conflicts found, summarize:
     - Which files have conflicts
     - Brief description of the conflicting sections

5. **Provide recommendations**:
   - If conflicts are simple (e.g., both added to end of file): suggest resolution approach
   - If conflicts are complex: recommend reviewing the specific files before merging

## Example Output

```
Conflict Preview: feature/my-branch → main

No conflicts detected. Safe to merge.
```

or

```
Conflict Preview: feature/my-branch → main

Conflicts found in 2 files:

1. src/config.py (lines 45-52)
   - main: added new CONFIG_VALUE
   - feature/my-branch: modified existing CONFIG_VALUE

2. README.md (lines 10-15)
   - Both branches modified the "Installation" section

Recommendation: Review src/config.py to decide which CONFIG_VALUE to keep.
```
