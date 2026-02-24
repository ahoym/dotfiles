#!/bin/bash
# PreToolUse hook: blocks dangerous Bash command patterns
# Used by ralph loops to guard against prompt injection.
# Exit 0 = allow, Exit 2 + stderr = block

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Pipe network content to shell
if echo "$COMMAND" | grep -qEi 'curl\s.*\|\s*(ba)?sh|wget\s.*\|\s*(ba)?sh'; then
  echo "BLOCKED: Piping network content to shell" >&2
  exit 2
fi

# Eval remote content
if echo "$COMMAND" | grep -qEi 'eval\s+\$\(curl|eval\s+\$\(wget'; then
  echo "BLOCKED: Eval of remote content" >&2
  exit 2
fi

# Download and execute
if echo "$COMMAND" | grep -qEi 'curl.*&&.*chmod\s+\+x|wget.*&&.*chmod\s+\+x'; then
  echo "BLOCKED: Download-and-execute pattern" >&2
  exit 2
fi

# chmod +x and execute
if echo "$COMMAND" | grep -qEi 'chmod\s+\+x.*&&\s*\./' ; then
  echo "BLOCKED: chmod +x and execute pattern" >&2
  exit 2
fi

# Package install from URL
if echo "$COMMAND" | grep -qEi '(pip|npm|gem)\s+install\s+https?://'; then
  echo "BLOCKED: Package install from URL" >&2
  exit 2
fi

# Clone and execute
if echo "$COMMAND" | grep -qEi 'git\s+clone.*&&.*(bash|sh|python|\.\/)'; then
  echo "BLOCKED: Clone-and-execute pattern" >&2
  exit 2
fi

# Process substitution from network
if echo "$COMMAND" | grep -qEi '(ba)?sh\s+<\(curl|(ba)?sh\s+<\(wget'; then
  echo "BLOCKED: Process substitution from network" >&2
  exit 2
fi

exit 0
