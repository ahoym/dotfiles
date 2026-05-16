# Use for ANY reply to an existing GitLab discussion — inline DiffNote OR top-level. Every note
# belongs to a discussion (with a discussion_id), and this endpoint threads the reply under it.
# The script name is historical: this is the only correct path for replying to a top-level
# operator direction note as well — passing the parent note's discussion_id threads under it.
# Using post-top-level-comment.sh to "reply" to a top-level note creates a NEW floating
# discussion instead.
#
# Write body to tmp/claude-artifacts/change-request-replies/<note_id>-<persona>-<role>.md, then:
# MUST use uppercase -F (not -f) with body=@path — -F reads the file, -f posts the literal string.
glab api projects/:id/merge_requests/<number>/discussions/<discussion_id>/notes \
  -X POST -F body=@<ABSOLUTE_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/<note_id>-<persona>-<role>.md
