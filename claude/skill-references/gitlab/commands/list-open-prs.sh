# GitLab open MRs (v2 stub)
# glab api has no --jq flag. Pipe to standalone jq instead.
glab api projects/:id/merge_requests -F state=opened | jq '.[] | {iid, source_branch, web_url}'
