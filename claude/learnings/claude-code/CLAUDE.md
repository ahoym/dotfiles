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
| ralph-loop.md | Ralph loop mechanics, resuming, state management, worktree patterns |
| ralph-curation.md | Ralph curation patterns: compounding, deep dives, convergence, staged-learnings |
| explore-repo.md | Parallel multi-agent exploration for unfamiliar repos |
| cross-repo-sync.md | Cross-repo sync patterns and path-mismatch gotchas |
| shell-patterns.md | Shell expansion safety: $(cat) non-recursive expansion, injection prevention |
| web-session-sync.md | Web session sync: when sync is needed vs not, branch workflows |
| sweep-sessions.md | Sweep director patterns: claude -p learnings-team gate gaps, GitLab/GitHub state casing |
| skill-design-patterns.md | Skill architecture: standalone-first design, reference file placement, conditional mode loading |

## Sub-clusters

- `multi-agent/CLAUDE.md` — Orchestration, coordination, quality, parallelization, autonomous patterns
