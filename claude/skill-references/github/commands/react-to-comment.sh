# React to inline/review comment (available: +1, -1, laugh, confused, heart, hooray, rocket, eyes)
# Use -f (lowercase) not -F — -F infers type and treats +1/-1 as numeric, which the API rejects
gh api repos/{owner}/{repo}/pulls/comments/<comment_id>/reactions -f content=<emoji>

# React to issue/top-level comment:
# gh api repos/{owner}/{repo}/issues/comments/<comment_id>/reactions -f content=<emoji>
