gh pr view <number> --json commits \
  --jq '.commits[] | {sha: .oid[0:7], message: .messageHeadline}'
