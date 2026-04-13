# Fetch MR state + latest commit + merge status for watermark comparison
glab api projects/:id/merge_requests/<IID> --jq '{state, merge_status, sha}'
