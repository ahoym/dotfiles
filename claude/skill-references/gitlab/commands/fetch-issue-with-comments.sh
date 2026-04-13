# GitLab issue with latest note (v2 stub)
# Requires two calls — issue metadata + notes
glab api projects/:id/issues/<IID> --jq '{updated_at}'
# Latest note:
glab api projects/:id/issues/<IID>/notes -F sort=desc -F per_page=1 --jq '.[0] | {id, body}'
