gh pr view <number> --json reviews --jq '.reviews[] | select(.body | length > 0) | {author: .author.login, state: .state, body}'
# No since filtering. On incremental fetches, compare count against LAST_REVIEW_COUNT.
