# GitLab MR target branch (v2 stub)
# glab api has no --jq flag. Pipe to standalone jq instead.
glab api projects/:id/merge_requests/<IID> | jq -r '.target_branch'
