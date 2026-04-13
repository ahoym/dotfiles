# Quick-exit check for polling — commits, reviews, state, and top-level comments in one call.
# No --jq. Parse JSON response in agent logic.
gh pr view <number> --json commits,reviews,state,comments
