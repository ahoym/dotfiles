# Write jq filter to tmp/claude-artifacts/jq-filters/jq-filter.jq via Write tool first:
#   [.[] | select(.state == "APPROVED") | .user.login] | unique | .[]
# Then (use piped jq -f instead of --jq):
gh api repos/{owner}/{repo}/pulls/<number>/reviews \
  | jq -rf tmp/claude-artifacts/jq-filters/jq-filter.jq
