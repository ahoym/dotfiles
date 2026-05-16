# Fetch MR state + latest commit + merge status for watermark comparison
# glab api has no --jq flag. Pipe to standalone jq instead.
glab api projects/:id/merge_requests/<IID> | jq '{state, merge_status, sha}'
