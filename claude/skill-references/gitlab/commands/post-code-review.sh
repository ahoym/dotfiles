# GitLab MR review: inline comments via GraphQL + summary as top-level note

# Step 1: Get SHAs for diff positioning + MR internal ID (not iid):
glab api projects/:id/merge_requests/<number>/versions | jq '.[0] | {base_commit_sha, head_commit_sha}'
# MR_ID: glab mr view <number> -F json | jq '.id'
# noteableId = "gid://gitlab/MergeRequest/<MR_ID>"

# Step 2: Write the GraphQL mutation template (once per session):
# Write to tmp/claude-artifacts/change-request-replies/createDiffNote.graphql:
#   mutation($body: String!, $noteableId: NoteableID!, $baseSha: String!, $headSha: String!, $startSha: String!, $oldPath: String!, $newPath: String!, $newLine: Int!) { createDiffNote(input: { noteableId: $noteableId, body: $body, position: { baseSha: $baseSha, headSha: $headSha, startSha: $startSha, paths: { oldPath: $oldPath, newPath: $newPath }, newLine: $newLine } }) { note { id } errors } }

# Step 3: Post each inline comment via GraphQL:
# Write each comment body to tmp/claude-artifacts/change-request-replies/<mr_number>-inline-<persona>-<role>-<n>.md
# Then post with file-based variables:
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
# Line number rules:
#   New lines (+): use newLine only, omit oldLine
#   Context lines: both oldLine and newLine
#   Removed lines (-): oldLine only, omit newLine
#   MANDATORY: verify every newLine before posting. Two methods:
#   a. bash ~/.claude/skill-references/implementer/diff-line-lookup.sh <MR> "<token>" → file:line
#   b. Read(file, offset=line-3, limit=7) and confirm the target code token is on the line.
#   Subagent line numbers are frequently off by 1-3 lines.
#
# Check errors array in response — non-empty means comment was not posted.

# Step 4: Post review summary as top-level comment (see post-top-level-comment.sh):
glab api projects/:id/merge_requests/<number>/notes -X POST \
  -F body=@<ABSOLUTE_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/<mr_number>-<persona>-<role>-top.md
