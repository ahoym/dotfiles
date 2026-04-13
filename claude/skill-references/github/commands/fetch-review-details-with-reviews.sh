# Combines metadata, state, and reviews in a single call.
# No --jq to avoid quoted strings in permission patterns.
gh pr view <number> --json number,title,headRefName,baseRefName,url,state,reviews
