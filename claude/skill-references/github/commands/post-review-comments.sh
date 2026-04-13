# Write JSON payload to tmp/claude-artifacts/change-request-replies/review-<number>.json, then:
gh api repos/{owner}/{repo}/pulls/<number>/reviews \
  --input tmp/claude-artifacts/change-request-replies/review-<number>.json
# Optional: clean up payload after posting
rm tmp/claude-artifacts/change-request-replies/review-<number>.json

# Payload format (tmp/claude-artifacts/change-request-replies/review-<number>.json):
# {"event": "COMMENT", "body": "...", "comments": [{"path": "file.md", "line": 42, "side": "RIGHT", "body": "..."}]}
# event: COMMENT, APPROVE, or REQUEST_CHANGES
# line: line number in final version (RIGHT side of diff)
# side: always RIGHT for new-version comments
