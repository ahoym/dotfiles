# GitLab has no single review API. Post inline comments via GraphQL, then summary as top-level comment.

# Step 1: Get SHAs and MR internal ID:
# glab api projects/:id/merge_requests/<number>/versions | jq '.[0] | {base_commit_sha, head_commit_sha}'
# glab mr view <number> --output json | jq '.id'
# The MR id (not iid) is needed for GraphQL noteableId: "gid://gitlab/MergeRequest/<id>"

# Step 2: Post each inline comment via GraphQL:
# For complex mutations, write query to .graphql file and use uppercase -F:
#   glab api graphql -F query=@tmp/claude-artifacts/change-request-replies/gql-1.graphql
# Lowercase -f query=@file does NOT read the file — passes literal "@file" string.
glab api graphql -f query='mutation {
  createDiffNote(input: {
    noteableId: "gid://gitlab/MergeRequest/<mr_id>",
    body: "<escaped_body>",
    position: {
      baseSha: "<base_sha>",
      headSha: "<head_sha>",
      startSha: "<base_sha>",
      paths: { oldPath: "<file_path>", newPath: "<file_path>" },
      newLine: <line_number>
    }
  }) { note { id } errors }
}'

# Body escaping: use jq -Rs on a file for JSON-escaped string. Always jq, never python3.
# Line number: must match exact line in new file (1-indexed). Verify against file content, not diff hunk arithmetic.
# For new lines (+): omit oldLine. Context lines: both oldLine and newLine. Removed lines (-): only oldLine.
# Step 3: Post review summary as top-level comment (see post-top-level-comment.sh).
