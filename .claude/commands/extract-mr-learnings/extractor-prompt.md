# Extractor Subagent Prompt Template

Fill in `<placeholders>` before passing to each subagent.

**Orchestrator instructions (do not include below the line):**
- Use this template VERBATIM for every PR — do not abbreviate, paraphrase, or omit sections
- Fill in ALL placeholders from the batch metadata JSON
- The template already handles closed PRs, zero-discussion PRs, and high-discussion PRs — do not add ad-hoc instructions per PR
- The only per-PR variation is the placeholder values themselves

---

You are extracting learnings from PR #<NUMBER> in the <REPO_NAME> GitHub repo. RESEARCH ONLY — do not write any files.

PR metadata:
- Number: <NUMBER>
- Title: <TITLE>
- State: <STATE> | Author: <AUTHOR> | Branch: <HEAD_BRANCH> -> main
- Reviewers: <REVIEWERS>
- Comments: <COMMENTS> | Created: <CREATED_AT> | Merged: <MERGED_AT>
- Description: "<DESCRIPTION>"

## Data fetching

Run these commands in this order. Do NOT use any other gh commands or endpoints.

**Step 1 — Fetch review comments and issue comments (always run):**
```bash
gh api "repos/{owner}/{repo}/pulls/<NUMBER>/comments" | jq '[.[] | {author: .user.login, body: .body, created_at: .created_at[:10], path: .path}]'
gh api "repos/{owner}/{repo}/issues/<NUMBER>/comments" | jq '[.[] | {author: .user.login, body: .body, created_at: .created_at[:10]}]'
```

**Step 2 — Fetch PR detail for file/commit counts (always run):**
```bash
gh api "repos/{owner}/{repo}/pulls/<NUMBER>" | jq '{changed_files: .changed_files, additions: .additions, deletions: .deletions, labels: [.labels[]?.name], html_url: .html_url}'
```

**Step 3 — Fetch diff file list (only if comments > 10 or state is closed):**
```bash
gh api "repos/{owner}/{repo}/pulls/<NUMBER>/files" | jq '[.[] | {file: .filename, additions: .additions, deletions: .deletions}]'
```

Do not fetch any other endpoints. These commands provide all the signal needed.

For **discussion PRs** (comments > 0): Summarize each thread — what was flagged, the reasoning, the resolution.
For **zero-discussion PRs**: Note patterns from title, description, branch naming, and metadata.
For **closed/unmerged PRs**: Capture why the direction was abandoned or what was explored.

Return structured learnings in this format:

```
### Concise title

What the learning is, why it matters, and when it applies.

- **Source**: PR #<NUMBER>
- **Frequency**: once | recurring | convention
- **Scope**: project-specific | general
- **Category**: <one of: EXISTING_CATEGORIES, or suggest new>
```

Existing categories: <EXISTING_CATEGORIES>

Suggest new categories only if nothing existing fits.

Focus on:
- What reviewers flagged and why
- Decisions made and their reasoning
- Patterns worth replicating or avoiding
- Convention signals (naming, structure, process)
- For closed PRs: what was tried and why it didn't proceed
