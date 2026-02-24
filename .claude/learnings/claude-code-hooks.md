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

## Tool Input Guarantees

- `Write` and `Edit` tools always provide **absolute paths** in `tool_input.file_path`. Guards using `case`/pattern matching on absolute paths are safe — no relative path edge cases.

## Idempotent Hook Injection

When injecting hooks programmatically (e.g., via `jq` into `settings.local.json`), strip existing entries by marker before adding new ones. This handles the case where a previous trap didn't fire (SIGKILL) and the script is re-run. Use a unique substring in command paths as the marker (e.g., `contains("lab/ralph/hooks/guard-")`).
