# Claude Code Hooks

## PreToolUse Hook Authoring

Guard hooks receive JSON on stdin with the tool invocation, exit 0 to allow or exit 2 + stderr message to block.

**Stdin format:**
```json
{"tool_name": "Bash", "tool_input": {"command": "ls -la"}}
```

**Hook script pattern:**
```bash
#!/bin/bash
INPUT=$(cat)
FIELD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$FIELD" ] && exit 0

if echo "$FIELD" | grep -qEi 'dangerous_pattern'; then
  echo "BLOCKED: reason" >&2
  exit 2
fi
exit 0
```

**Settings format** (in `.claude/settings.local.json`):
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "bash path/to/guard.sh"}]
      }
    ]
  }
}
```

**Key details:**
- `matcher` is the tool name (e.g., `Bash`, `WebFetch`, `Write`, `Edit`)
- Exit 2 blocks the tool call; stderr message is shown to the user/agent
- Exit 0 (or any non-2 code) allows the call
- Multiple matchers can target the same tool; all must pass
- Args can be baked into the command string (e.g., `guard-write-scope.sh /path/to/project`)

## Hooks vs Permissions: Independent Layers

PreToolUse hooks fire **before** the permission system and are completely independent of it. `--dangerously-skip-permissions` skips permission prompts but does NOT skip hooks. This means hooks are a reliable security boundary for unattended `claude --dangerously-skip-permissions --print` runs.

Note: `PermissionRequest` hooks do NOT fire in non-interactive mode (`--print`). Only `PreToolUse`/`PostToolUse` fire.

## Tool Input Guarantees

- `Write` and `Edit` tools always provide **absolute paths** in `tool_input.file_path`. Guards using `case`/pattern matching on absolute paths are safe — no relative path edge cases.

## Blanket Tool Blocking > Pattern Matching

For unattended loops, block entire tool classes rather than enumerating dangerous patterns. Research loops only need Read, Write, Edit, Glob, Grep, WebFetch, WebSearch — blanket-blocking Bash eliminates the entire class of prompt injection risks (remote code execution, destructive ops, environment manipulation) in 3 lines instead of 200+ lines of regex that can always be bypassed.

Pattern-matching guards are a game of whack-a-mole. Removing the tool entirely is a brick wall.

## Hook Performance: Process Spawn Overhead

Each hook spawns a process (~1-2ms on macOS) on every matching tool call. For high-frequency tools (Bash, Write/Edit), permanent hooks cause aggregate latency even with early-exit checks. Scope hooks to contexts where they're needed — e.g., inject into worktree-level `settings.local.json` instead of user-level settings, so hooks only exist during the scoped operation.

## Multiple PreToolUse Hooks Act as AND Gates

When multiple `PreToolUse` hooks match the same tool, **all** must allow for the call to proceed. If Hook A allows and Hook B denies, the call is blocked. This means concurrent write-scope guards for different directories are fundamentally incompatible on shared settings — each guard blocks the other's allowed directory. Solve with isolated settings (worktrees) rather than shared settings with multiple guards.

## PostToolUse Limitations

- **PostToolUse can't undo** — the tool already executed. Value is *feedback* (stderr → Claude), not prevention. Claude can then take corrective action.
- **No pre/post state comparison** — PreToolUse and PostToolUse fire independently with no shared state. To compare before/after, PreToolUse must write state to a temp file.

## Stop Hooks Can Loop

Always check `stop_hook_active` field to allow stopping on re-check. Without this check, a Stop hook that blocks stopping will loop indefinitely.

## Selective Allowlist: Middle Ground Between Blanket Block and Full Access

When an unattended agent needs *some* Bash access (e.g., git commands for file management) but not arbitrary execution, use a selective allowlist guard instead of a blanket block:

1. Case-match allowed command prefixes (`git rm *`, `git add *`, `git mv *`, etc.)
2. For path-accepting commands, validate each path arg starts with an allowed prefix (`$WORKTREE_ROOT/.claude/`)
3. Block compound commands (`&&`, `||`, `;`, `|`) via grep before the case statement — prevents chaining an allowed command with an arbitrary one
4. Default case blocks everything not explicitly allowed

This is narrower than full Bash access (small, enumerable allowlist of structured commands) but wider than blanket block (agent can perform git operations). Use when the agent's workflow genuinely requires shell commands that have no dedicated tool equivalent.

The "blanket > pattern matching" principle still holds for *open-ended* pattern matching (trying to enumerate dangerous commands). A *closed* allowlist of specific command prefixes is fundamentally different — you're enumerating what's allowed, not what's dangerous.

## Hook Enforcement for Workflow Gates

Hooks can enforce sequential workflow gates (e.g., "search learnings before doing anything else") using filesystem state coordination:

1. **SessionStart** creates a flag file (`/tmp/claude-gate-${session_id}`)
2. **PreToolUse** blocks non-exempt tools while the flag exists
3. **PostToolUse** on the required tool (e.g., Glob targeting learnings/) removes the flag

**What's enforceable:** The session-start gate works cleanly — low cost, flag removed after first qualifying tool call, zero ongoing overhead.

**What's not:** Plan mode is a **permission state change**, not a tool call. No `EnterPlanMode` tool exists for PreToolUse to intercept. Hooks see `permission_mode` in their JSON input (current state) but not transitions. There is no `PlanModeEntry` hook event.

**Alternative for non-enforceable gates:** Use `additionalContext` (available on SessionStart, UserPromptSubmit, PreToolUse, SubagentStart) to inject reminders conditionally — a nudge rather than a wall. Fires only while the flag file exists, so no ongoing overhead after compliance.

**Key coordination details:**
- `session_id` is in every hook's JSON input — use it for session-scoped state files
- PostToolUse completes before next PreToolUse fires (no race conditions)
- `CLAUDE_ENV_FILE` only sets env vars visible to Bash commands, not to other hooks — use filesystem for cross-hook state

## Idempotent Hook Injection

When injecting hooks programmatically (e.g., via `jq` into `settings.local.json`), strip existing entries by marker before adding new ones. This handles the case where a previous trap didn't fire (SIGKILL) and the script is re-run. Use a unique substring in command paths as the marker (e.g., `contains("lab/ralph/hooks/guard-")`).
