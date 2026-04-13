# Write body to tmp/claude-artifacts/change-request-replies/<note_id>-<persona>-<role>.md, then:
# MUST use uppercase -F (not -f) with body=@path — -F reads the file, -f posts the literal string.
glab api projects/:id/merge_requests/<number>/discussions/<discussion_id>/notes \
  -X POST -F body=@<ABSOLUTE_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/<note_id>-<persona>-<role>.md
