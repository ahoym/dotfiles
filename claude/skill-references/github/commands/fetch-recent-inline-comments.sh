# Quick-exit check for polling. Fetches 10 to see past agent replies. No --jq.
gh api repos/{owner}/{repo}/pulls/<number>/comments --method GET -f sort=created -f direction=desc -F per_page=10
# Filter out self-comments (Role:.*<YOUR_ROLE> in body).
