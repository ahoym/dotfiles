# Fetch the latest inline comment ID on a PR (for watermark tracking)
gh api repos/{owner}/{repo}/pulls/<N>/comments --jq '.[-1].id // empty'
