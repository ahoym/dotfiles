# Full fetch (--paginate to get all notes beyond default page limit)
glab api projects/:id/merge_requests/<number>/notes --paginate | jq '.[] | {id, body, author: .author.username, created_at, position}'

# Incremental fetch — write jq filter to file first:
# 1. Write to tmp/claude-artifacts/jq-filters/jq-filter.jq via Write tool:
#      .[] | select(.created_at > "<TS>") | {id, body, author: .author.username, created_at, position}
# 2. Then:
# glab api projects/:id/merge_requests/<number>/notes --paginate | jq -f tmp/claude-artifacts/jq-filters/jq-filter.jq
