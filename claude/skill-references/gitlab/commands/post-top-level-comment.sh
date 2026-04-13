# Write body to tmp/claude-artifacts/change-request-replies/<mr_number>-<persona>-<role>-top.md, then:
# Use absolute paths with -F body=@ — glab api resolves @ paths relative to CWD.
# Avoid glab mr comment --message "$(cat ...)" — $(cat) triggers permission prompts.
glab api projects/:id/merge_requests/<number>/notes -X POST \
  -F body=@/absolute/path/to/tmp/claude-artifacts/change-request-replies/<mr_number>-<persona>-<role>-top.md
