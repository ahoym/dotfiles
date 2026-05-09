# Link a sub-issue to a parent via GitHub's native sub-issues feature.
# Renders as a Sub-issues panel with progress bar in the parent issue UI,
# and "Parent" backlink on the sub-issue. Different from a markdown
# checklist — this is a structured relationship.
#
# Both numbers must be issues (not PRs) in the same repo. The GraphQL
# mutation requires node IDs, not numbers — resolve them first.

# Step 1 — resolve node IDs from issue numbers:
PARENT_ID=$(gh api repos/<OWNER>/<REPO>/issues/<PARENT_NUMBER> --jq '.node_id')
SUB_ID=$(gh api repos/<OWNER>/<REPO>/issues/<SUB_NUMBER> --jq '.node_id')

# Step 2 — add the parent/sub relationship:
gh api graphql -F parent="$PARENT_ID" -F sub="$SUB_ID" \
  -f query='mutation($parent: ID!, $sub: ID!) { addSubIssue(input: {issueId: $parent, subIssueId: $sub}) { subIssue { number } } }'
