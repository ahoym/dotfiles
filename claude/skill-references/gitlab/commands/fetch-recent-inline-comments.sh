# Quick-exit check for polling. Fetches 10 to see past agent replies.
glab api projects/:id/merge_requests/<number>/notes --method GET -f sort=desc -F per_page=10
# Filter out self-comments (Role:.*<YOUR_ROLE> in body).
