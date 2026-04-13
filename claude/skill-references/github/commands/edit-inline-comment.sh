# Write updated body to .gh-reply.tmp, then:
# Endpoint is pulls/comments/<comment_id> (no PR number), not pulls/<number>/comments/<comment_id>.
gh api repos/{owner}/{repo}/pulls/comments/<comment_id> -X PATCH \
  -F body=@.gh-reply.tmp
