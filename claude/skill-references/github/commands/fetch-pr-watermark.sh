# Fetch PR state + latest commit + mergeable status for watermark comparison
# No --jq (avoids quoted string permission prompts). Parse JSON in the agent.
gh pr view <N> --json commits,state,mergeStateStatus,mergeable,comments
