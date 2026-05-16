# GitLab MRs by source branch (v2 stub)
# glab api has no --jq flag. Pipe to standalone jq instead.
glab api projects/:id/merge_requests -F source_branch=<BRANCH> -F state=all | jq '.[] | {iid, source_branch, state}'
