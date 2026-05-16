GitLab DiffNote line positioning — `new_line` parameter drifts from diff hunk counting when posting inline review comments via the discussions API.
- **Keywords:** gitlab, diffnote, discussions API, new_line, line drift, hunk position, inline comment, review comment, line number, glab, position, LLM line counting
- **Related:** ~/.claude/skill-references/gitlab/comment-interaction.md

---

## DiffNote Line Numbers Drift From Diff Hunk Positions

When posting inline review comments via GitLab's REST discussions API, line numbers from diff hunk counting differ from actual `new_line` positions by 2-6 lines. Reviewer subagents report line numbers based on the diff output, but the API's `new_line` parameter refers to the file's actual line numbering.

**Fix:** Before posting each DiffNote, verify the target line against the actual file content (via `glab api projects/:id/repository/files/...` or local checkout). Posting to the wrong line makes the comment appear on unrelated code.

## GraphQL `createDiffNote` Flag Rules

`glab api graphql` has two flag types that behave differently with `@file` references:

| Flag | Name | `@file` behavior | Use for |
|------|------|-------------------|---------|
| `-F` | field | Reads file contents | `query`, `body`, `newLine` (integer inference) |
| `-f` | raw-field | Sends literal `@file` string | String values: SHAs, paths, noteableId |

Mixing them up silently fails: `-f body=@file.md` posts the literal string `"@file.md"` as the comment body. `-f newLine=42` sends `"42"` (string) which GraphQL rejects for `Int!` type.

## Platform Command Stub Detection

A platform command under 5 lines with no GraphQL mutation is likely a stub. Stubs cause silent degradation — agents work around missing capabilities by improvising (e.g., posting all findings as top-level notes instead of inline DiffNotes). When maintaining platform commands: verify each has the full API flow, not just a v1 placeholder.
