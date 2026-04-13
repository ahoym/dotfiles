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

Use these scripts from `~/.claude/platform-commands/`:

**Step 1 (always run):**
- `fetch-review-comments.sh` — use the full fetch variant
- `fetch-issue-comments.sh`

**Step 2 (always run):**
- `fetch-review-details.sh`

**Step 3 (if discussion count > 10, OR state is closed, OR description signals substantial implementation — new module/adapter/integration/refactor):**
- `fetch-review-files.sh`

Do not fetch any other endpoints. These commands provide all the signal needed.

For **discussion reviews** (discussion count > 0): Summarize each thread — what was flagged, the reasoning, the resolution.
For **implementation-heavy reviews** (substantial diff, any discussion count): Analyze the implementation patterns visible in the diff — architectural decisions, design patterns, module structure, API contracts, error handling strategies, test patterns. The diff IS the learning; discussion is a bonus. Fetch Files Changed (Step 3) to understand scope even if discussion count ≤ 10.
For **zero-discussion reviews**: Extract patterns from the diff, description, and metadata. Zero discussion often means the team agrees on the approach — that agreement IS a convention worth capturing.
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

Learnings include **general good practices and architectural patterns**, not just gotchas and surprising failure modes. Capture validated approaches, architectural conventions, and engineering practices that would help the team make better decisions — not only things that caused incidents.

Focus on:
- **Implementation patterns**: Architecture decisions visible in the diff — module structure, design patterns, error handling, API contracts, test structure. These are learnings even without discussion.
- **What reviewers flagged and why**: Discussion threads with reasoning and resolution.
- **Decisions made and their reasoning**: Both explicit (in comments) and implicit (in the code — zero-discussion conventions the team already agrees on).
- **Patterns worth replicating or avoiding**: Including patterns from the diff that have no reviewer commentary but represent established conventions.
- **Convention signals**: Naming, package structure, test organization, configuration patterns.
- For closed reviews: what was tried and why it didn't proceed.
