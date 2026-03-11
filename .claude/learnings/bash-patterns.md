# Bash Patterns

## Shell Env Default Ordering Gotcha

When a shared library script (e.g., `lib.sh`) sets a variable with a default:
```bash
# lib.sh
export NETWORK="${NETWORK:-testnet}"
```

Any downstream script that sources it **cannot** override with another conditional default:
```bash
source lib.sh            # NETWORK is now "testnet"
NETWORK="${NETWORK:-$STATE_NETWORK}"  # No-op! NETWORK is already set
```

**Fix:** Save the user's original value before sourcing the library:
```bash
USER_NETWORK="${NETWORK:-}"
source lib.sh
if [ "${USER_NETWORK:-}" = "" ]; then
  NETWORK="$STATE_NETWORK"  # Use data-driven default
fi
```

This preserves explicit user overrides (`NETWORK=mainnet ./script.sh`) while allowing the script to use a data-driven default (e.g., from a state file) instead of the library's hardcoded default.

## Shared Test Helper Library Pattern (scripts/lib.sh)

When multiple bash test scripts share the same boilerplate (BASE_URL, response parsing, status assertion), extract a shared library:

```bash
#!/usr/bin/env bash
# scripts/lib.sh
export BASE_URL="${BASE_URL:-http://localhost:3000}"

parse_response() {
  local response="$1"
  HTTP_CODE=$(echo "$response" | tail -1)
  BODY=$(echo "$response" | sed '$d')
}

assert_status() {
  local expected="$1"
  local description="$2"
  if [ "$HTTP_CODE" -eq "$expected" ]; then
    echo "PASS: ${description}"
  else
    echo "FAIL: ${description} -- expected HTTP ${expected}, got ${HTTP_CODE}"
    echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
    exit 1
  fi
}
```

Source with: `source "$(cd "$(dirname "$0")" && pwd)/lib.sh"` — resolves absolute path regardless of invocation directory. The `| tail -1 | grep -q "201"` pattern does string matching (would match `2012`); `parse_response` + `assert_status` gives proper numeric comparison.

## `set -e` and `pipefail` Traps

### `$()` Assignments Propagate Exit Codes Under `set -e`

When a command substitution fails inside a variable assignment, `set -e` kills the script immediately — before any error-handling code runs.

```bash
# Silent death:
RESULT=$(some_command_that_might_fail)

# Fix: Append || true then handle explicitly:
RESULT=$(some_command_that_might_fail) || true
[ -z "$RESULT" ] && { echo "error message"; exit 1; }
```

### `ls` + Glob + `pipefail` = Silent Death

`ls` with a non-matching glob exits non-zero. Combined with `pipefail`, this propagates through pipes and kills `$()` assignments silently:

```bash
# Silent death when no files match:
LATEST=$(ls -t /some/dir/*.json 2>/dev/null | head -1)

# Fix:
LATEST=$(ls -t /some/dir/*.json 2>/dev/null | head -1) || true
```

### `((x++))` Returns Exit 1 When x Is 0

Arithmetic `((expr))` returns exit code 1 when the expression evaluates to 0, which `set -e` treats as failure. Use `x=$((x + 1))` instead.

### General Principle

Under `set -euo pipefail`, any command that might legitimately fail in a `$()` assignment needs `|| true` to allow fallthrough to explicit error handling.

## Teardown Must Precede Prerequisite Checks

When a script has a `--clean` / teardown mode, skip or defer port/resource availability checks until after teardown runs. Otherwise `--clean` fails on the very ports it's about to free.

```bash
# Wrong: checks before clean → --clean always fails if previous run is up
check_port 5432 "Postgres" || exit 1
if $CLEAN; then docker rm -f postgres; fi

# Right: skip checks when --clean will free them
if ! $CLEAN; then
  check_port 5432 "Postgres" || exit 1
fi
if $CLEAN; then docker rm -f postgres; fi
```

## Use `jq` Instead of `python3` for JSON Parsing in Bash

`python3 -c "import json; ..."` in bash commands triggers permission prompts because quoted strings match differently. `jq` is auto-permitted and handles the same JSON parsing tasks. When passing API output to subagents, prefer passing raw JSON directly rather than parsing in the main context at all.

## rsync --delete Auto-Removes Renamed Directories

`rsync --delete` removes anything in the target that doesn't exist in the source. So renaming a source directory (e.g., `old-name/` → `new-name/`) automatically deletes the old-named directory from the target — no need for separate `rm -rf` cleanup commands.
