# Ralph Loop

## Resuming a Completed Loop

Each iteration is stateless — `claude --print` with no conversation history. Continuity is only through files on disk (`spec.md`, `progress.md`, output files).

`wiggum.sh` checks for `WOOT_COMPLETE_WOOT` in `progress.md` after every iteration. If present, the loop exits immediately. **To resume**: remove the completion signal, update pending tasks/answers, then re-run the script.

## Question Tracking in progress.md

Use `**ANSWER:**` prefix inline on answered questions rather than changing the section header (e.g., `(Answered)`). This keeps the "Questions Requiring User Input" header stable — new questions can be added below without conflicting with a header that implies everything is resolved. Agents distinguish answered vs unanswered by presence/absence of the `**ANSWER:**` prefix.

## Worktree Isolation for Settings Scoping

Git worktrees give each ralph loop its own `settings.local.json`. Claude loads **user-level** (`~/.claude/settings.local.json` — symlinks to main repo, untouched) + **project-level** (`<worktree>/.claude/settings.local.json` — isolated copy). Hooks injected into the worktree's settings only apply to that loop's `claude --print` invocations.

This also eliminates the fragile `git stash → checkout → branch → stash pop → commit → push → checkout back` dance. With worktrees: `git worktree add` → loop in worktree → commit+push from worktree → `git worktree remove`. No stashing, no branch switching in the main tree, concurrent-safe.
