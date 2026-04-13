# Use discussions endpoint for threaded comments
glab api projects/:id/merge_requests/<number>/discussions \
  | jq '.[] | {id, notes: [.notes[] | {id, body, author: .author.username, position}]}'
# No updated_after filtering. On incremental fetches, compare discussion count against LAST_REVIEW_COUNT.
