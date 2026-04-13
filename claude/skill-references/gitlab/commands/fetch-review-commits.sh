# glab api has no --jq flag. Pipe to standalone jq instead.
glab api projects/:id/merge_requests/<number>/commits \
  | jq '.[] | {sha: .short_id, message: .title}'
