#!/bin/bash
# PreToolUse hook: enforces URL safety rules for WebFetch
# Used by ralph loops to guard against prompt injection.
# Exit 0 = allow, Exit 2 + stderr = block

INPUT=$(cat)
URL=$(echo "$INPUT" | jq -r '.tool_input.url // empty')

if [ -z "$URL" ]; then
  exit 0
fi

# Block non-HTTPS
if echo "$URL" | grep -qEi '^http://'; then
  echo "BLOCKED: Non-HTTPS URL: $URL" >&2
  exit 2
fi

# Block URL shorteners
if echo "$URL" | grep -qEi '(bit\.ly|tinyurl\.com|t\.co|goo\.gl|is\.gd|buff\.ly|ow\.ly|rebrand\.ly)'; then
  echo "BLOCKED: URL shortener: $URL" >&2
  exit 2
fi

# Block paste sites
if echo "$URL" | grep -qEi '(pastebin\.com|paste\.ee|hastebin\.com|dpaste\.com|ghostbin\.com)'; then
  echo "BLOCKED: Paste site: $URL" >&2
  exit 2
fi

# Block suspicious TLDs
if echo "$URL" | grep -qEi '\.(zip|mov|tk|ml|ga|cf|gq)(/|$)'; then
  echo "BLOCKED: Suspicious TLD: $URL" >&2
  exit 2
fi

exit 0
