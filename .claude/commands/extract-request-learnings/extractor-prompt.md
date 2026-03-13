# Extractor Subagent Prompt Template

Fill in `<placeholders>` before passing to each subagent.

**Orchestrator instructions (do not include below the line):**
- Use this template VERBATIM for every review — do not abbreviate, paraphrase, or omit sections
- Fill in ALL placeholders from the batch metadata JSON
- The template already handles closed reviews, zero-discussion reviews, and high-discussion reviews — do not add ad-hoc instructions per review
- The only per-review variation is the placeholder values themselves
- Use the GitHub or GitLab section below based on the detected platform

---

You are extracting learnings from <REVIEW_UNIT> <REVIEW_PREFIX><ID> in the <REPO_NAME> repo. RESEARCH ONLY — do not write any files.

Review metadata:
- ID: <ID>
- Title: <TITLE>
- State: <STATE> | Author: <AUTHOR> | Branch: <BRANCH> -> main
- Reviewers: <REVIEWERS>
- Discussion count: <DISCUSSION_COUNT> | Created: <CREATED_AT> | Merged: <MERGED_AT>
- Description: "<DESCRIPTION>"

## Data fetching

Run these commands in this order. Do NOT use any other CLI commands or endpoints.

### GitHub

**Step 1 — Fetch review comments and issue comments (always run):**
```bash
gh api "repos/{owner}/{repo}/pulls/<ID>/comments" | jq '[.[] | {author: .user.login, body: .body, created_at: .created_at[:10], path: .path}]'
gh api "repos/{owner}/{repo}/issues/<ID>/comments" | jq '[.[] | {author: .user.login, body: .body, created_at: .created_at[:10]}]'
```

**Step 2 — Fetch review detail for file/commit counts (always run):**
```bash
gh api "repos/{owner}/{repo}/pulls/<ID>" | jq '{changed_files: .changed_files, additions: .additions, deletions: .deletions, labels: [.labels[]?.name], html_url: .html_url}'
```

**Step 3 — Fetch diff file list (only if discussion count > 10 or state is closed):**
```bash
gh api "repos/{owner}/{repo}/pulls/<ID>/files" | jq '[.[] | {file: .filename, additions: .additions, deletions: .deletions}]'
```

### GitLab

**Step 1 — Fetch non-system discussion notes (always run):**
```bash
glab api "projects/:id/merge_requests/<ID>/discussions" | jq '[.[] | .notes[] | select(.system == false) | {author: .author.username, body: .body, created_at: .created_at[:10], position: (.position.new_path // null)}]'
```

**Step 2 — Fetch review detail for file/commit counts (always run):**
```bash
glab api "projects/:id/merge_requests/<ID>" | jq '{changes_count: .changes_count, labels: [.labels[]?.name], web_url: .web_url}'
```

**Step 3 — Fetch diff file list (only if discussion count > 10 or state is closed):**
```bash
glab api "projects/:id/merge_requests/<ID>/changes" | jq '[.changes[] | {file: .new_path, added: (.diff | split("\n") | map(select(startswith("+"))) | length), removed: (.diff | split("\n") | map(select(startswith("-"))) | length)}]'
```

---

Do not fetch any other endpoints. These commands provide all the signal needed.

For **discussion reviews** (discussion count > 0): Summarize each thread — what was flagged, the reasoning, the resolution.
For **zero-discussion reviews**: Note patterns from title, description, branch naming, and metadata.
For **closed/unmerged reviews**: Capture why the direction was abandoned or what was explored.

Return structured learnings in this format:

```
### Concise title

What the learning is, why it matters, and when it applies.

- **Source**: <REVIEW_UNIT> <REVIEW_PREFIX><ID>
- **Frequency**: once | recurring | convention
- **Scope**: project-specific | general | private
- **Category**: <one of: EXISTING_CATEGORIES, or suggest new>
```

Existing categories: <EXISTING_CATEGORIES>

Suggest new categories only if nothing existing fits.

Focus on:
- What reviewers flagged and why
- Decisions made and their reasoning
- Patterns worth replicating or avoiding
- Convention signals (naming, structure, process)
- For closed reviews: what was tried and why it didn't proceed
