# ONLY for posting a NEW standalone top-level discussion (e.g., the "Review actions" summary).
# DO NOT use this to REPLY to an existing top-level operator note — that creates a brand-new
# floating discussion instead of threading under the parent. To reply to an existing top-level
# discussion, use reply-to-inline-comment.sh with the parent note's discussion_id (every note
# belongs to a discussion, inline or top-level).
#
# Write body to tmp/claude-artifacts/change-request-replies/<mr_number>-<persona>-<role>-top.md, then:
# MUST use uppercase -F (not -f) with body=@path — -F reads the file, -f posts the literal string.
# Avoid glab mr comment --message "$(cat ...)" — $(cat) triggers permission prompts.
glab api projects/:id/merge_requests/<number>/notes -X POST \
  -F body=@<ABSOLUTE_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/<mr_number>-<persona>-<role>-top.md
