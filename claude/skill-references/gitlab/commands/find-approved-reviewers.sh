# Write jq filter to tmp/claude-artifacts/jq-filters/jq-filter.jq via Write tool first:
#   [.[] | select(.body | test("LGTM"; "i"))] | [.[].author.username] | unique | .[]
# Then:
# Uses --paginate to fetch all notes (not just first 100) for MRs with many comments.
glab api projects/:id/merge_requests/<number>/notes --paginate \
  | jq -rf tmp/claude-artifacts/jq-filters/jq-filter.jq
