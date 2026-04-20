# Write body to tmp/claude-artifacts/change-request-replies/<pr_number>-<persona>-<role>-top.md, then:
# --body-file reads the file content. Use absolute path — CWD may differ from project root.
gh pr comment <number> --body-file <ABSOLUTE_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/<pr_number>-<persona>-<role>-top.md
