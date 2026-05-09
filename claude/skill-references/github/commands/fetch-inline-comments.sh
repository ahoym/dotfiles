# Full fetch (--paginate to get all comments beyond default 30-per-page limit)
# Fields: id, in_reply_to_id, commit_id, path, line, body, user, created_at
# in_reply_to_id and commit_id are required by re-review thread classification.
gh api repos/{owner}/{repo}/pulls/<number>/comments --paginate --jq '.[] | {id, in_reply_to_id, commit_id, path, line, body, user: .user.login, created_at}'

# Incremental fetch — write jq filter to file first:
# 1. Write to tmp/claude-artifacts/jq-filters/jq-filter.jq via Write tool:
#      .[] | select(.created_at > "<TS>") | {id, in_reply_to_id, commit_id, path, line, body, user: .user.login, created_at}
# 2. Then (use piped jq -f instead of --jq):
# gh api repos/{owner}/{repo}/pulls/<number>/comments --paginate | jq -f tmp/claude-artifacts/jq-filters/jq-filter.jq
