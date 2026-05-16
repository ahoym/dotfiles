# GitLab issue state (v2 stub)
# glab api has no --jq flag. Pipe to standalone jq instead.
glab api projects/:id/issues/<IID> | jq -r '.state'
