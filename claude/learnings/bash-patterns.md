Shell scripting gotchas and recipes covering `set -euo pipefail` traps, `gh api` query patterns, shared test helpers, and zsh compatibility.
- **Keywords:** set -e, pipefail, set -u, unbound variable, command substitution, gh api, zsh globbing, rsync --delete, lib.sh, empty array expansion, teardown
- **Related:** claude-code.md, git-patterns.md

---

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

## Empty Array Expansion Under `set -u`

`${arr[@]}` fails with "unbound variable" under `set -u` when the array is empty. Use the `${arr[@]+"${arr[@]}"}` pattern:

```bash
local args=()
$FLAG && args+=(--flag)
# Wrong: fails when args is empty
echo "${args[@]}"
# Right: expands to nothing when empty
echo ${args[@]+"${args[@]}"}
```

This uses parameter alternate value syntax: if `arr[@]` is unset/empty, expand to nothing; otherwise expand normally. Common in functions that conditionally build argument lists.

## `gh api` Query Params: Use `-f`/`-F` Flags, Not URL Query Strings

`gh api` URLs with `?` and `&` cause zsh globbing errors and break permission patterns. Two workarounds:

**Preferred — flag-based GET params:**
```bash
# Wrong — zsh glob error + permission prompt:
gh api 'repos/{owner}/{repo}/pulls/24/comments?sort=created&direction=desc&per_page=1'

# Right — flags become query params with --method GET:
gh api repos/{owner}/{repo}/pulls/24/comments --method GET -f sort=created -f direction=desc -F per_page=1
```

**Fallback — client-side filter (when server-side filtering isn't available):**
```bash
gh api repos/{owner}/{repo}/pulls/24/comments --jq '.[] | select(.created_at > "2026-03-14T04:00:00Z") | ...'
```

Note: `--jq` expressions with `contains()` or string comparisons also trigger permission prompts. When possible, drop `--jq` entirely and parse the raw JSON in agent logic.

`gh api` natively resolves `{owner}/{repo}` from the current repo context — no need to manually look up the owner and repo name.

**Use `--paginate` to get all results.** `gh api` defaults to 30 results per page (ascending). Without `--paginate`, comments beyond the first page are silently missed. `--paginate` is a CLI flag (no quoting needed) that auto-fetches all pages.

**Use `--input file.json` for complex JSON payloads.** When a POST body has nested arrays or objects (e.g., review with inline comments), write the JSON to a temp file and pass via `--input`. Avoids shell quoting issues entirely — no `-f`/`-F` field-by-field construction needed.

## `gh api` `-f` vs `-F` for Field Values

`-F` (uppercase) infers type: `+1` becomes numeric `1`, which the GitHub reactions API rejects. `-f` (lowercase) always sends as string. Use `-f` when the value must be a string (e.g., `-f content=+1` for emoji reactions).

## rsync --delete Auto-Removes Renamed Directories

`rsync --delete` removes anything in the target that doesn't exist in the source. So renaming a source directory (e.g., `old-name/` → `new-name/`) automatically deletes the old-named directory from the target — no need for separate `rm -rf` cleanup commands.

## Cross-Refs

- `~/.claude/learnings/claude-code.md` — Bash permission prefix matching gotchas (chaining, subshells, quoted strings, tilde expansion — complementary permission-system angle)
- `~/.claude/learnings/git-patterns.md` — GitHub API pagination, git operations that use bash scripting patterns
