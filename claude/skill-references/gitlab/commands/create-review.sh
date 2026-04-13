# Write body via Write tool to tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md, then:
# Use absolute paths with $(cat) — resolves relative to CWD.
glab mr create --target-branch <base-branch> --title "<title>" --description "$(cat /absolute/path/to/tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md)"
