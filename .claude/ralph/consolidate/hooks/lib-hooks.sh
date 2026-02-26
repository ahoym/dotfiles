#!/bin/bash
# Library for injecting/removing consolidation security hooks into settings.local.json.
# Source this file, then call inject_hooks / remove_hooks.
#
# Usage:
#   source lib-hooks.sh
#   inject_hooks ".claude/settings.local.json" "/abs/path/to/worktree"
#   trap 'remove_hooks ".claude/settings.local.json"' EXIT

inject_hooks() {
  local settings_file="$1"
  local worktree_root="$2"

  if ! command -v jq &>/dev/null; then
    echo "WARNING: jq not found, skipping hook injection" >&2
    return 1
  fi

  # Build hooks config via jq to ensure proper JSON escaping
  local hooks_json
  hooks_json=$(jq -n \
    --arg bash_cmd "bash ~/.claude/ralph/consolidate/hooks/guard-bash.sh" \
    --arg web_cmd "bash ~/.claude/ralph/consolidate/hooks/guard-web.sh" \
    --arg write_cmd "bash ~/.claude/ralph/consolidate/hooks/guard-write-scope.sh $worktree_root" \
    --arg read_cmd "bash ~/.claude/ralph/consolidate/hooks/guard-read-scope.sh $worktree_root" \
    --arg task_cmd "bash ~/.claude/ralph/consolidate/hooks/guard-task.sh" \
    '{
      "PreToolUse": [
        {
          "matcher": "Bash",
          "hooks": [{"type": "command", "command": $bash_cmd}]
        },
        {
          "matcher": "WebFetch",
          "hooks": [{"type": "command", "command": $web_cmd}]
        },
        {
          "matcher": "WebSearch",
          "hooks": [{"type": "command", "command": $web_cmd}]
        },
        {
          "matcher": "Write",
          "hooks": [{"type": "command", "command": $write_cmd}]
        },
        {
          "matcher": "Edit",
          "hooks": [{"type": "command", "command": $write_cmd}]
        },
        {
          "matcher": "Read",
          "hooks": [{"type": "command", "command": $read_cmd}]
        },
        {
          "matcher": "Glob",
          "hooks": [{"type": "command", "command": $read_cmd}]
        },
        {
          "matcher": "Grep",
          "hooks": [{"type": "command", "command": $read_cmd}]
        },
        {
          "matcher": "Task",
          "hooks": [{"type": "command", "command": $task_cmd}]
        }
      ]
    }')

  if [ -f "$settings_file" ]; then
    # Idempotent: strip existing consolidation hooks, then add new ones.
    # Handles SIGKILL leaving stale hooks from a previous run.
    # Preserves non-consolidation hooks and all other settings.
    jq --argjson hooks "$hooks_json" '
      # Keep non-consolidation PreToolUse entries
      [(.hooks.PreToolUse // [])[] | select(
        .hooks | any(.command | contains("ralph/consolidate/hooks/guard-")) | not
      )] as $non_consolidate |
      .hooks.PreToolUse = ($non_consolidate + $hooks.PreToolUse)
    ' "$settings_file" > "${settings_file}.tmp"
    mv "${settings_file}.tmp" "$settings_file"
  else
    mkdir -p "$(dirname "$settings_file")"
    jq -n --argjson hooks "$hooks_json" '{hooks: $hooks}' > "$settings_file"
  fi

  echo "Injected consolidation security hooks into $settings_file"
}

remove_hooks() {
  local settings_file="$1"

  if ! command -v jq &>/dev/null; then
    echo "WARNING: jq not found, skipping hook removal" >&2
    return 1
  fi

  if [ ! -f "$settings_file" ]; then
    return 0
  fi

  jq 'del(.hooks)' "$settings_file" > "${settings_file}.tmp"
  mv "${settings_file}.tmp" "$settings_file"

  echo "Removed consolidation security hooks from $settings_file"
}
