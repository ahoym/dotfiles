# Write body to tmp/claude-artifacts/change-request-replies/<comment_id>-<persona>-<role>.md, then:
# Use absolute paths with -F body=@ — gh api resolves @ paths relative to CWD.
gh api repos/{owner}/{repo}/pulls/<number>/comments \
  -F body=@/absolute/path/to/tmp/claude-artifacts/change-request-replies/<comment_id>-<persona>-<role>.md -F in_reply_to=<comment_id>
