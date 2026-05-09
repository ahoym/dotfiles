# Remove a parent/sub relationship created via addSubIssue. The sub-issue
# is not deleted — only the relationship is removed. Useful when re-parenting
# or cleaning up an incorrect link.

# Step 1 — resolve node IDs from issue numbers:
PARENT_ID=$(gh api repos/<OWNER>/<REPO>/issues/<PARENT_NUMBER> --jq '.node_id')
SUB_ID=$(gh api repos/<OWNER>/<REPO>/issues/<SUB_NUMBER> --jq '.node_id')

# Step 2 — remove the relationship:
gh api graphql -F parent="$PARENT_ID" -F sub="$SUB_ID" \
  -f query='mutation($parent: ID!, $sub: ID!) { removeSubIssue(input: {issueId: $parent, subIssueId: $sub}) { subIssue { number } } }'
