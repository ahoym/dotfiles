---
description: Rebase a chain of stacked/dependent branches when main is updated
---

# Cascade Rebase

Rebase a chain of compound feature branches when the base (main) is updated.

## Usage

- `/cascade-rebase <branch1> <branch2> ...` - Rebase branches in order
- `/cascade-rebase` - Will prompt for branch chain

## Instructions

1. **Get branch chain**:
   - If `$ARGUMENTS` provided, parse as space-separated branch names
   - Otherwise, ask: "List your branches in order from closest to main to furthest (e.g., `feature/phase1 feature/phase2 feature/phase3`)"

2. **Fetch and validate**:
   ```bash
   git fetch origin main <all-branches>
   ```
   Verify all branches exist.

3. **Record current commit hashes** (needed for `--onto`):
   ```bash
   git rev-parse origin/<branch>
   ```
   Store as `old_hash_<branch>` for each branch.

4. **Rebase first branch onto main**:
   ```bash
   git checkout <branch1>
   git rebase origin/main
   ```
   Record new hash: `new_hash_<branch1>=$(git rev-parse HEAD)`

5. **Cascade to subsequent branches**:
   For each remaining branch:
   ```bash
   git checkout <branchN>
   git rebase --onto <new_hash_prev> <old_hash_prev> <branchN>
   ```
   Record: `new_hash_<branchN>=$(git rev-parse HEAD)`

   The `--onto` syntax:
   - `<new_hash_prev>`: Where to attach (tip of rebased previous branch)
   - `<old_hash_prev>`: Old parent to detach from
   - `<branchN>`: Current branch being rebased

6. **Handle conflicts**:
   - If rebase conflicts occur, pause and help resolve
   - After resolution: `git rebase --continue`
   - User can abort: `git rebase --abort`

7. **Push all branches**:
   Ask user: "Rebase complete. Push all branches with --force-with-lease?"
   ```bash
   git push origin <branch1> --force-with-lease
   git push origin <branch2> --force-with-lease
   # ... etc
   ```

8. **Summary**:
   Show old → new commit hashes for each branch.

## Example

```
Cascade rebase: main → feature/phase1 → feature/phase2 → feature/phase3

Step 1: Rebasing feature/phase1 onto main...
  Done: abc123 → def456

Step 2: Rebasing feature/phase2 onto feature/phase1...
  Done: 111aaa → 222bbb

Step 3: Rebasing feature/phase3 onto feature/phase2...
  Done: 333ccc → 444ddd

All branches rebased. Ready to push.
```

## Important Notes

- This rewrites history - ensure no one else is working on these branches
- Always use `--force-with-lease` (not `--force`) for safety
- If conflicts occur mid-chain, resolve before continuing
