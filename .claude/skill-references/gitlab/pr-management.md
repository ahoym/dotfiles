---
description: "GitLab commands for creating/updating MRs, posting reviews, and branch management."
---

# GitLab: MR Management

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters.

## Create or Update MR (Body via File)

Write the MR body to `change-request-replies/request-body-<BRANCH_NAME>.md` first to avoid quoting issues:

```bash
mkdir -p change-request-replies
# Write body via Write tool to change-request-replies/request-body-<BRANCH_NAME>.md, then:
glab mr create --target-branch <base-branch> --title "<title>" --description "$(cat change-request-replies/request-body-<BRANCH_NAME>.md)"
# Or update existing:
glab mr update <number> --description "$(cat change-request-replies/request-body-<BRANCH_NAME>.md)"
# Clean up:
rm change-request-replies/request-body-<BRANCH_NAME>.md && rmdir change-request-replies 2>/dev/null
```

## Post Review with Inline Comments

GitLab has no single "review" API like GitHub. Post inline comments as individual discussion notes, then post the summary as a top-level comment.

**Step 1: Post each inline comment as a new discussion:**

```bash
mkdir -p change-request-replies
# For each inline comment, write body to change-request-replies/review-<note_index>.md, then:
glab api projects/:id/merge_requests/<number>/discussions -X POST \
  -f "body=$(cat change-request-replies/review-<note_index>.md)" \
  -f "position[base_sha]=<base_sha>" \
  -f "position[head_sha]=<head_sha>" \
  -f "position[start_sha]=<base_sha>" \
  -f "position[position_type]=text" \
  -f "position[new_path]=<file_path>" \
  -f "position[new_line]=<line_number>"
```

Get `base_sha` and `head_sha` from:
```bash
glab api projects/:id/merge_requests/<number>/versions | jq '.[0] | {base_commit_sha, head_commit_sha}'
```

**Step 2: Post the review summary as a top-level comment** (see comment-interaction.md → "Post Top-Level Comment").

**Step 3: Clean up:**
```bash
rm -rf change-request-replies
```

## Checkout Review Branch

```bash
glab mr checkout <number>
git pull origin <source_branch>
```

## Check for Existing Review

```bash
glab mr list --source-branch <branch-name>
```

## Find Approved Reviewers

```bash
glab api "projects/:id/merge_requests/<number>/notes?sort=desc&per_page=100" \
  | jq -r '[.[] | select(.body | test("LGTM"; "i"))] | [.[].author.username] | unique | .[]'
```
