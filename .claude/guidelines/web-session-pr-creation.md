# Web Session PR Creation

Learnings from creating PRs in web session environments.

## Skills Commit Removal

Web sessions add a `[web-session] sync skills` commit that bundles `.claude/commands/` into the branch. This must be dropped before creating a PR to main.

**Command to drop it:**
```bash
MERGE_BASE=$(git merge-base HEAD origin/main)
SKILLS_COMMIT=$(git log --format="%H %s" "$MERGE_BASE"..HEAD | grep "\[web-session\] sync skills" | awk '{print $1}')
git rebase --onto origin/main "$SKILLS_COMMIT"
```

This rebases all commits after the skills commit directly onto main, effectively removing it.

## Git Proxy Limitations

The web session git proxy (`http://local_proxy@127.0.0.1:PORT/git/...`) only supports git operations:
- `git push` / `git fetch` / `git pull` — work normally
- GitHub API (PR creation, issues, etc.) — **not supported**

The `gh` CLI cannot authenticate through this proxy. PR creation must either:
1. Use a different auth mechanism (if available)
2. Be done manually by the user after the branch is pushed

## Force Push After Rebase

After dropping the skills commit via rebase, the branch must be force-pushed:
```bash
git push --force-with-lease -u origin <branch-name>
```

Use `--force-with-lease` (not `--force`) for safety — it will refuse to push if someone else has pushed to the branch.

## Branch Naming Convention

Web session branches follow the pattern: `claude/branch-off-web-session-<sessionId>`

The branch name must start with `claude/` and end with a matching session ID, otherwise pushes will fail with 403.
