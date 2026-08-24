# Write body to tmp/claude-artifacts/change-request-replies/<comment_id>-<persona>-<role>.md, then:
# The Write file_path stays CWD-relative (absolutizing it prompts) — only the -F @ arg below is absolute.
# MUST use uppercase -F (not -f) with body=@path — -F reads the file, -f posts the literal string.
gh api repos/{owner}/{repo}/pulls/<number>/comments \
  -X POST -F body=@<ABSOLUTE_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/<comment_id>-<persona>-<role>.md \
  -F in_reply_to=<comment_id>
