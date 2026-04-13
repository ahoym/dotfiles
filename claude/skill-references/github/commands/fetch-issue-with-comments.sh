# Fetch issue metadata with latest comment info
gh issue view <N> --json updatedAt,comments --jq '{updatedAt, last_comment_id: (.comments[-1].id // null), last_comment_body: (.comments[-1].body // null)}'
