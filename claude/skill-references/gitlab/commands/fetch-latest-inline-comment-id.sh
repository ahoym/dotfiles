# Fetch the latest inline note ID on an MR (for watermark tracking)
# glab api has no --jq flag. Pipe to standalone jq instead.
glab api 'projects/:id/merge_requests/<IID>/notes?sort=desc&per_page=1' | jq -r '.[0].id // empty'
