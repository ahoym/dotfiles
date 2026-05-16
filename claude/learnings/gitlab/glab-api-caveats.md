`glab` CLI divergences from `gh` and common pitfalls.
**Keywords:** glab, gitlab, api, jq, json, pagination, file-upload
**Related:** none

## `--jq` does not exist

`glab api` has no `--jq` flag. Pipe to standalone `jq` instead:
```bash
# Wrong:
glab api projects/:id/merge_requests/<IID> --jq '.state'
# Correct:
glab api projects/:id/merge_requests/<IID> | jq -r '.state'
```

## JSON output flag

`glab mr view` uses `-F json`, not `--output json`:
```bash
glab mr view <number> -F json      # correct
glab mr view <number> -F json -c   # with discussions
```

## `-F` vs `-f` for file reads

- `-F` (field): expands `@filename` → reads file contents. Use for `query`, `body`, integer fields.
- `-f` (raw-field): sends the literal string `@filename`. Use for plain string values (SHAs, paths, IDs).

## Avoid `$(cat ...)` subshells

`$(cat ...)` triggers permission prompts. Use `-F body=@file` via the API instead:
```bash
# Wrong (permission prompt):
glab mr create --description "$(cat path/to/body.md)"
# Correct (no prompt):
glab api projects/:id/merge_requests -X POST \
  -F source_branch=<branch> -F target_branch=<base> -f title=<title> \
  -F description=@<ABSOLUTE_PATH>/tmp/claude-artifacts/change-request-replies/request-body.md
```
Same pattern for `glab mr update` → `glab api ... -X PUT -F description=@file`.

## Pagination

Use `--paginate` for complete result sets. `per_page=100` silently truncates MRs with 100+ comments:
```bash
glab api projects/:id/merge_requests/<number>/notes --paginate | jq '...'
```

## Cross-Refs

- `~/.claude/skill-references/gitlab/commands/` — canonical command reference scripts
