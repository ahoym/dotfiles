# Extractor Subagent Prompt Template

Fill in `<placeholders>` before passing to each subagent.

**Orchestrator instructions (do not include below the line):**
- Use this template VERBATIM for every review — do not abbreviate, paraphrase, or omit sections
- Fill in ALL placeholders from the batch metadata JSON
- The template already handles closed reviews, zero-discussion reviews, and high-discussion reviews — do not add ad-hoc instructions per review
- The only per-review variation is the placeholder values themselves
- Set `<PLATFORM>` to `github` or `gitlab` based on the detected platform before injecting

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

Read `~/.claude/skill-references/<PLATFORM>-commands.md` (where `<PLATFORM>` is `github` or `gitlab`) for exact command templates. Use these sections from that file:

**Step 1 (always run):**
- **Fetch Inline/Review Comments** — use the full fetch variant
- **Fetch Issue/Top-Level Comments**

**Step 2 (always run):**
- **Fetch Review Details**

**Step 3 (only if discussion count > 10 or state is closed):**
- **Fetch Files Changed**

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
- **Language**: <language/framework if applicable, e.g., Python, React, Docker; omit if language-agnostic>
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
