# Fetch the latest inline note ID on an MR (for watermark tracking)
glab api projects/:id/merge_requests/<IID>/notes -F sort=desc -F per_page=1 --jq '.[0].id // empty'
