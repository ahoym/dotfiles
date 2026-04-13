# Write body via Write tool to tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md, then:
# Use absolute paths with $(cat) — resolves relative to CWD.
glab mr update <number> --description "$(cat <ABSOLUTE_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md)"
