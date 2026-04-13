# Fetch issue metadata with state and latest comment info
gh issue view <N> --json state,updatedAt,comments --jq '{state, updatedAt, last_comment_id: (.comments[-1].id // null), last_comment_body: (.comments[-1].body // null)}'
