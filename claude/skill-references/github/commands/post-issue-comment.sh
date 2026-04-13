# Write body via Write tool to tmp/claude-artifacts/sweep-work-items/clarify-<NUMBER>.md, then:
# Use absolute paths — gh resolves file paths relative to CWD.
gh issue comment <NUMBER> --body-file /absolute/path/to/tmp/claude-artifacts/sweep-work-items/clarify-<NUMBER>.md
