# DiffNote Line Numbers Drift From Diff Hunk Positions

When posting inline review comments via GitLab's REST discussions API, line numbers from diff hunk counting differ from actual `new_line` positions by 2-6 lines. Reviewer subagents report line numbers based on the diff output, but the API's `new_line` parameter refers to the file's actual line numbering.

**Fix:** Before posting each DiffNote, verify the target line against the actual file content (via `glab api projects/:id/repository/files/...` or local checkout). Posting to the wrong line makes the comment appear on unrelated code.
