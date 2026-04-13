# Full fetch — notes without position data are top-level comments
glab api projects/:id/merge_requests/<number>/notes --paginate | jq '[.[] | select(.position == null)] | .[] | {id, body, author: .author.username, created_at}'

# Incremental fetch — write jq filter to file first:
# 1. Write to tmp/claude-artifacts/jq-filters/jq-filter.jq via Write tool:
#      [.[] | select(.position == null)] | .[] | select(.created_at > "<TS>") | {id, body, author: .author.username, created_at}
# 2. Then:
# glab api projects/:id/merge_requests/<number>/notes --paginate | jq -f tmp/claude-artifacts/jq-filters/jq-filter.jq
