---
description: Split a commit with mixed changes into separate commits
---

# Split Commit

Split a commit that mixes unrelated changes (e.g., docstrings + features) into separate commits.

## Usage

- `/split-commit` - Split the most recent commit
- `/split-commit <commit-hash>` - Split a specific commit

## Instructions

1. **Identify the commit to split**:
   - If `$ARGUMENTS` is empty, use `HEAD`
   - Otherwise, use the provided commit hash

2. **Show the commit contents**:
   ```bash
   git show <commit> --stat
   git show <commit>
   ```
   Ask the user: "How would you like to split this commit? Describe the two (or more) groups of changes."

3. **Save original files before resetting**:
   ```bash
   # For each file in the commit
   git show <commit>:<filepath> > /tmp/<filename>_original
   ```

4. **Reset to parent commit**:
   ```bash
   git reset --hard <commit>^
   ```

5. **Apply first group of changes**:
   - Using the saved files in `/tmp/` as reference, apply only the first group
   - Ask user for commit message
   ```bash
   git add <files>
   git commit -m "<message>

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
   ```

6. **Apply remaining changes**:
   - Restore full versions from `/tmp/` originals
   - Ask user for commit message
   ```bash
   git add <files>
   git commit -m "<message>

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
   ```

7. **Verify and push**:
   ```bash
   git log --oneline -3
   ```
   Ask user: "Ready to force push these changes?"
   ```bash
   git push origin <branch> --force-with-lease
   ```

## Important Notes

- This rewrites history - only use on commits not yet merged
- Always save files to `/tmp/` BEFORE resetting
- The original commit is replaced by multiple new commits
