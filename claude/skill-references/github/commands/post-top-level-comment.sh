# Write body to tmp/claude-artifacts/change-request-replies/<pr_number>-<persona>-<role>-top.md, then:
# Use absolute paths — same CWD caveat as reply-to-inline-comment.
gh pr comment <number> --body-file /absolute/path/to/tmp/claude-artifacts/change-request-replies/<pr_number>-<persona>-<role>-top.md
