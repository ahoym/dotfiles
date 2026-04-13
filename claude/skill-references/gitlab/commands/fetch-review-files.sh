# Uses MR changes API instead of parsing raw diff — avoids quoted grep/sed args.
glab api projects/:id/merge_requests/<number>/changes | jq -r .changes[].new_path
