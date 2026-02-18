# Web Session Sync

## `.claude/web-skills/` Pattern

Web sessions can't access `~/.claude/` — they only see files checked into the repo. To make skills available in web sessions without polluting main:

- Store project-specific web skills in `.claude/web-skills/<skill-name>/SKILL.md` on main (version-controlled, reviewable via normal PRs)
- A sync workflow (`sync-web-session.yml`) rebuilds a `web-session` branch on each push to main:
  1. Clones dotfiles repo, copies `~/.claude/commands/` (user-level skills)
  2. Copies `.claude/web-skills/*` into `.claude/commands/` (project-level web skills)
  3. Commits with message `[web-session] sync skills`, force-pushes
- Result: `web-session` = main HEAD + exactly 1 commit with all skills merged
- A guard workflow (`guard-commands.yml`) blocks PRs to main that contain `.claude/commands/` files

### Adding New Web Skills

Drop a new skill into `.claude/web-skills/<name>/SKILL.md` on main — the sync workflow picks it up automatically on next push.

### `/web-create-pr` Skill

Lives in `.claude/web-skills/web-create-pr/SKILL.md`. When invoked from a web session branch:
1. Identifies the skills commit by its `[web-session] sync skills` message
2. Rebases `--onto origin/main` to drop it
3. Prompts user on conflicts (no auto-resolve)
4. Pushes with `--force-with-lease` and creates a clean PR against main
