# Multi-Agent Execution

Patterns and insights for parallel agent orchestration using `/make-parallel-plan` and `/execute-parallel-plan`.

## Subagent Session Isolation

Subagent sessions are isolated — the orchestrator only sees the final output message and files on disk, not the agent's internal reasoning or tool call history. This means:

- Discoveries made during implementation are lost unless explicitly reported
- Agents must produce a structured **Completion Report** at the end of their output
- Completion Report format: Files created/modified, TDD steps completed (N/N), Checkpoint (last completed step), Discoveries (gotchas, patterns, edge cases)
- The orchestrator captures discoveries from Completion Reports and can forward relevant ones to pending agents' prompts

## Background Agent Permissions

Background agents (launched with `run_in_background: true`) CAN use Bash, but they **cannot prompt for permissions interactively**. If a Bash command doesn't match a pre-configured allow pattern in `.claude/settings.local.json`, it silently fails with a permission denied error — the agent has no way to ask the user.

This means:
- Any Bash command a background agent needs must have a matching wildcard pattern pre-configured
- When a background agent fails with no output or "permission denied", check the allow patterns first
- Use wildcard patterns (e.g., `Bash(uv run pytest *)`) to cover all invocations of common commands
- Skills that launch background agents should document required permission patterns as prerequisites
- Test commands, build commands, and lint commands all need matching allow patterns for TDD to work in background agents

## File Tools Accept Tilde Paths

Read, Write, and Edit tools accept `~` in file paths and expand it to the user's home directory automatically. Background agents can use `~/.claude/learnings/topic.md` directly — no need for the orchestrator to resolve absolute paths or pass a `BASE_DIR` parameter. This makes skills portable across machines with different home directory paths.

## Remote Sessions (`&` prefix)

- Start any message with `&` to send a task to run on Claude web (claude.ai) as an independent session
- Also available via CLI: `claude --remote "Your task here"`
- Each `&` task gets its own independent web session running on Anthropic cloud infrastructure
- You can continue working locally while remote tasks run
- Monitor progress with `/tasks` or interact directly on claude.ai

### Teleporting Sessions (`/teleport`)

- `/teleport` or `/tp` pulls a web session back into your terminal
- Session handoff is **one-way: web -> terminal only** — you cannot push an existing local session to the web
- Always start with `&` if you think you might want to switch to web later
- Requirements: clean git state, same repo (not a fork), branch pushed to remote, same Claude account

### Remote Session Limitations

- Remote sessions operate within the context of the current repo
- They **cannot** write to local paths like `~/.claude/` (cloud infrastructure doesn't have access to local filesystem)
- They **can** write to the git repo, commit, and push
- Cross-repo access (cloning a different repo in a web session) may work if auth allows, but is unverified

