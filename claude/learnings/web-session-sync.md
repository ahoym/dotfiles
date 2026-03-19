# Web Session Sync

## When Sync Is Needed vs. Not

- **Needs sync**: Any repo that relies on `~/.claude/commands/` but doesn't contain them (e.g., application repos)
- **Doesn't need sync**: Repos where `.claude/commands/` already lives in the repo (e.g., dotfiles, which IS `~/.claude/` via symlinks) — skills are already available in web sessions
- **Guard workflow**: Only needed for repos where `.claude/commands/` shouldn't be in main. Not needed for the dotfiles repo itself since commands belong there.

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

## Future Simplification

`/web-create-pr` is fully repo-agnostic — no project-specific references. Candidate for promotion to dotfiles (`~/.claude/commands/`), which would reduce per-project setup from 3 files to 2 (just the workflows). Deferred until the pattern is validated across multiple repos.

## Branch Naming Convention

Web session branches follow the pattern: `claude/branch-off-web-session-<sessionId>`. The branch name must start with `claude/` and end with a matching session ID, otherwise pushes will fail with 403.

## Build Verification in Web Sessions

`pnpm build` may fail in sandboxed web environments when the build process fetches external resources (e.g., Google Fonts). Use `pnpm typecheck` instead to verify compilation:

```bash
pnpm typecheck   # works in sandbox — runs tsc --noEmit
pnpm build       # may fail — external resource fetches blocked
```

## Context Window Management for Large Sessions

For large refactoring sessions that touch 10+ files:
- Commit frequently (every logical unit of work) so progress isn't lost if the session hits context limits
- If the session is compacted mid-edit, the continuation summary preserves enough detail to resume, but partially-edited files are the main risk
- Use `pnpm typecheck && pnpm test` after each commit to catch issues early

## Available Tools in Web Sessions

| Tool | Available | Notes |
|---|---|---|
| `git` | Yes | Via local proxy, push/pull work |
| `gh` | Installable | `apt-get install gh`, but no auth token |
| `pnpm` / `npm` | Yes | npm registry access may be limited |
| `node` / `npx` | Yes | |
| `curl` | Yes | Outbound via egress proxy, rate-limited for GitHub API |
| `apt-get` | Yes | Can install system packages |

## See also

- `~/.claude/learnings/cross-repo-sync.md` — bidirectional sync patterns (web-session sync is a one-directional specialization)
- `~/.claude/learnings/skill-platform-portability.md` — platform-neutral skill design (reduces what needs syncing)
