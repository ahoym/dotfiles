# Write body via Write tool to tmp/claude-artifacts/change-request-replies/<issue_iid>-comment.md, then:
# Use glab api with -F to avoid $(cat ...) permission prompts.
# MUST use uppercase -F (not -f) with @path — -F reads the file, -f posts the literal string.
glab api projects/:id/issues/<IID>/notes -X POST \
  -F body=@<ABSOLUTE_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/<issue_iid>-comment.md
