# Fetch state + reviews + top-level comments in a single call.
# No --jq (avoids quoted string permission prompts).
gh pr view <number> --json state,reviews,comments,number,title,headRefName,baseRefName
