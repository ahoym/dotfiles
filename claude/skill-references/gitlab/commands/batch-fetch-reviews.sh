# Write jq filter to tmp/claude-artifacts/jq-filters/jq-filter.jq via Write tool first:
#   .[] | {iid, title, state, user_notes_count, author: .author.username, source_branch, reviewers: [.reviewers[].username], created_at: .created_at[:10], merged_at: (.merged_at // "n/a")[:10], description: (.description // "(none)")[:400]}
# Then:
glab api "projects/:id/merge_requests?state=all&sort=asc&order_by=created_at&per_page=<SIZE>&page=<PAGE>" \
  | jq -cf tmp/claude-artifacts/jq-filters/jq-filter.jq
