# Write jq filter to tmp/claude-artifacts/jq-filters/jq-filter.jq via Write tool first:
#   .[] | {number, title, state, comments, user: .user.login, head_branch: .head.ref, requested_reviewers: [.requested_reviewers[].login], created_at: .created_at[:10], merged_at: (.merged_at // "n/a")[:10], body: (.body // "(none)")[:400]}
# Then:
gh api 'repos/{owner}/{repo}/pulls?state=all&sort=created&direction=asc&per_page=<SIZE>&page=<PAGE>' \
  | jq -cf tmp/claude-artifacts/jq-filters/jq-filter.jq
