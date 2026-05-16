# Write body via Write tool to tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md, then:
# Use glab api with -F to avoid $(cat ...) permission prompts.
# MUST use uppercase -F (not -f) with @path — -F reads the file, -f posts the literal string.
# glab mr update has no --description-file flag; the API reads the file directly.
glab api projects/:id/merge_requests/<number> -X PUT \
  -F description=@<ABSOLUTE_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md
