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
