# GitLab issue with latest note (v2 stub)
# Requires two calls — issue metadata + notes
# glab api has no --jq flag. Pipe to standalone jq instead.
glab api projects/:id/issues/<IID> | jq '{updated_at}'
# Latest note:
glab api 'projects/:id/issues/<IID>/notes?sort=desc&per_page=1' | jq '.[0] | {id, body}'
