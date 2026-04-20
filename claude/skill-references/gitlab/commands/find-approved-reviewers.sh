# Write jq filter to tmp/claude-artifacts/jq-filters/jq-filter.jq via Write tool first:
#   [.[] | select(.body | test("LGTM"; "i"))] | [.[].author.username] | unique | .[]
# Then:
glab api "projects/:id/merge_requests/<number>/notes?sort=desc&per_page=100" \
  | jq -rf tmp/claude-artifacts/jq-filters/jq-filter.jq
