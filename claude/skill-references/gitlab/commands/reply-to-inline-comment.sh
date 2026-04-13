# Write body to tmp/claude-artifacts/change-request-replies/<note_id>-<persona>-<role>.md, then:
# Use absolute paths with -F body=@ — glab api resolves @ paths relative to CWD.
glab api projects/:id/merge_requests/<number>/discussions/<discussion_id>/notes \
  -X POST -F body=@/absolute/path/to/tmp/claude-artifacts/change-request-replies/<note_id>-<persona>-<role>.md
