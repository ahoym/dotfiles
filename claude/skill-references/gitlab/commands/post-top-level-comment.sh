# Write body to tmp/claude-artifacts/change-request-replies/<mr_number>-<persona>-<role>-top.md, then:
# MUST use uppercase -F (not -f) with body=@path — -F reads the file, -f posts the literal string.
# Avoid glab mr comment --message "$(cat ...)" — $(cat) triggers permission prompts.
glab api projects/:id/merge_requests/<number>/notes -X POST \
  -F body=@<ABSOLUTE_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/<mr_number>-<persona>-<role>-top.md
