# GitLab has no single review API. Post inline comments via GraphQL, then summary as top-level comment.
# See post-code-review.sh for the full file-based variable approach (preferred).

# Step 1: Get SHAs and MR internal ID:
# glab api projects/:id/merge_requests/<number>/versions | jq '.[0] | {base_commit_sha, head_commit_sha}'
# glab mr view <number> -F json | jq '.id'
# The MR id (not iid) is needed for GraphQL noteableId: "gid://gitlab/MergeRequest/<id>"

# Step 2: Write the GraphQL mutation template (once per session):
# Write to tmp/claude-artifacts/change-request-replies/createDiffNote.graphql:
#   mutation($body: String!, $noteableId: NoteableID!, $baseSha: String!, $headSha: String!, $startSha: String!, $oldPath: String!, $newPath: String!, $newLine: Int!) { createDiffNote(input: { noteableId: $noteableId, body: $body, position: { baseSha: $baseSha, headSha: $headSha, startSha: $startSha, paths: { oldPath: $oldPath, newPath: $newPath }, newLine: $newLine } }) { note { id } errors } }

# Step 3: Post each inline comment via GraphQL with file-based variables:
# Write each comment body to tmp/claude-artifacts/change-request-replies/<mr_number>-inline-<persona>-<role>-<n>.md
glab api graphql \
  -F query=@tmp/claude-artifacts/change-request-replies/createDiffNote.graphql \
  -F body=@tmp/claude-artifacts/change-request-replies/<mr_number>-inline-<persona>-<role>-<n>.md \
  -f noteableId=gid://gitlab/MergeRequest/<mr_id> \
  -f baseSha=<base_sha> \
  -f headSha=<head_sha> \
  -f startSha=<base_sha> \
  -f 'oldPath=<file_path>' \
  -f 'newPath=<file_path>' \
  -F newLine=<line_number>

# CRITICAL: -F vs -f for file reads:
#   -F (field): expands @filename to read file contents. Use for query, body, newLine (integer).
#   -f (raw-field): sends literal string. Use for string values (SHAs, paths, IDs).
#
# Body escaping: not needed with file-based variables — glab handles it.
# Line number: must match exact line in new file (1-indexed). Verify against file content, not diff hunk arithmetic.
# For new lines (+): omit oldLine. Context lines: both oldLine and newLine. Removed lines (-): only oldLine.
# Check errors array in response — non-empty means comment was not posted.
#
# Step 4: Post review summary as top-level comment (see post-top-level-comment.sh).
