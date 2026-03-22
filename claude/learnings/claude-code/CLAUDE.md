Claude Code platform mechanics, agent infrastructure, and orchestration patterns.

| File | When to read |
|------|-------------|
| platform-permissions.md | Bash prefix matching, Write/Edit gotchas, settings merge, .claude/ protection |
| platform-worktrees-and-isolation.md | Task tool isolation, CWD pinning, subagent context, cross-repo ops |
| platform-tools-and-automation.md | @ references, cron/polling, file operation prerequisites, symlink resolution |
| hooks.md | PreToolUse/PostToolUse hook authoring and configuration |
| skill-platform-portability.md | Official skill features, frontmatter, context fork, shell preprocessing |
| agent-definitions.md | Custom agent definitions (~/.claude/agents/), memory scopes, skill preloading |
| plugin-packaging.md | Plugin caching, settings limits, namespace, cross-platform compatibility |
| ralph-loop.md | Ralph loop mechanics, resuming, state management |
| explore-repo.md | Parallel multi-agent exploration for unfamiliar repos |
| cross-repo-sync.md | Cross-repo sync patterns and path-mismatch gotchas |

## Sub-clusters

- `multi-agent/CLAUDE.md` — Orchestration, coordination, quality, parallelization, autonomous patterns
