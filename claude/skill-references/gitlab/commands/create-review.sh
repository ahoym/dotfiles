# Write body via Write tool to tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md, then:
# Use glab api with -F to avoid $(cat ...) permission prompts.
# MUST use uppercase -F (not -f) with @path — -F reads the file, -f posts the literal string.
# glab mr create has no --description-file flag; the API reads the file directly.
# For titles with spaces/special chars, write to a file and use -F title=@<file>.
glab api projects/:id/merge_requests -X POST \
  -F source_branch=<source-branch> \
  -F target_branch=<base-branch> \
  -f title=<title> \
  -F description=@<ABSOLUTE_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md \
  | jq -r '.web_url'
