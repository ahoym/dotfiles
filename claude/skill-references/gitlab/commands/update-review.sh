# Write body via Write tool to tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md, then:
# Use API with -F description=@<file> — avoids $(cat) permission prompts.
# glab mr update has no --description-file flag; the API reads the file directly.
glab api projects/:id/merge_requests/<IID> -X PUT \
  -F description=@<ABSOLUTE_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md
