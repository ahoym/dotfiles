# Address Request Comments — Edge Cases

Read this file when processing comments (step 5+). Skip on quiet no-ops.

## Core Principles

- Use `/git:explore-request` first if you need to understand the review before addressing comments
- **Reply to comments on the platform first** — share your analysis with the reviewer before making changes
- **Auto-implement on agreement** — when you agree with a suggestion, implement it after replying; when you disagree or are uncertain, escalate to your partner (see "When do suggestions get implemented?" below)
- Typo fixes and obvious bug fixes can be auto-implemented (they're corrections, not debatable suggestions)
- Always read the file context before making changes
- Use a friendly, appreciative tone in replies ("Thanks for catching this!", "Good call")
- If you disagree with a comment, explain your reasoning respectfully and ask for clarification
- Group related changes into a single commit when possible
- If a comment is unclear, ask the operator before responding

## When do suggestions get implemented?

**Mutual agreement = auto-implement.** When the addresser agrees with a reviewer's suggestion, implement it without waiting for operator approval. The partner can review the changes in the PR diff and calibrate.

**Disagreement = escalate.** When the addresser disagrees or is uncertain, present the suggestion to the partner and wait for their decision. Approval can come via CLI or review comments — either channel is valid.

To identify agent vs operator comments, check for `Role:.*Reviewer` or `Role:.*Addresser` in the comment body. Comments without a Role tag are from the operator.

## Conditional Requests

Comments with conditional phrasing like "If X, please do Y" should be categorized as **clarification requests**, not suggestions. The reviewer is asking for confirmation before the change should be made.

**Example:**
> "I think `is` means in-sample here. If so, please rename these variables."

This is a clarification request. Reply to confirm the understanding, then implement only after the reviewer confirms:
```
Yes, `is_` here means "in-sample". Would you like me to rename to `in_sample_*` or `train_*`?
```

## Line Number Drift

When comments reference specific line numbers (inline diff comments), be aware that:
- The line numbers in the API response refer to line numbers **at the time the comment was made**
- If new commits have been pushed since the comment was made, line numbers may have shifted
- On GitLab, the `head_sha` in the position data tells you which commit the line numbers refer to

**To find what an inline comment is actually about:**
```bash
# Option 1: Check out the commit the comment was made on
git show <commit_sha>:<file_path> | sed -n '<line_number>p'

# Option 2: View the file at that commit with context
git show <commit_sha>:<file_path> | head -n <line_number+5> | tail -n 10
```

**Do NOT** assume current file line numbers match the comment's line numbers after pushing changes.

## Investigation vs Approval Distinction

Be careful to distinguish comment types:

- **Clear approval** (execute): "Claude can you update...", "Go ahead and change it", "Please update the plan to...", "yes, proceed", "send it"
- **Investigation request** (analyze, then ask): "Can you look into X?", "Claude, can you investigate Y?"
- **Preference statement** (do NOT execute): "please annotate with X", "we should use X", "it would be better to..."

For investigation requests: Analyze the request, provide your findings/recommendations, then explicitly ask for approval before making changes.

## Planning Documents Exception

For `.md` files in plan directories (`docs/plans/`, `.claude/personal/plans/`, or any path containing `plans/`), do NOT auto-fix even if you agree with the comment. Planning documents require discussion, so reply with your thoughts and wait for explicit approval from the review author before making changes.

**When approval is given, only include what was specifically approved** - don't expand scope to include related improvements discussed in the same thread.

## Delta Summaries

Delta/summary comments (e.g., "Summary of Changes Since Last Update") should ALWAYS be posted as **top-level review comments**, not as thread replies. Top-level comments are easier to find and provide better visibility for tracking progress.

Follow **Post Top-Level Comment** in the platform cluster files.

## Re-review Requests

After pushing new changes, search for ALL reviewers who gave LGTM comments and tag each of them asking for re-review.

Follow **Find Approved Reviewers** in the platform cluster files to get the list, then **Post Top-Level Comment** to tag each reviewer asking for re-review.

**Important:** Tag ALL reviewers who gave LGTM comments, including the review author. When pair-programming with an AI agent, the operator is also reviewing the code changes made by the agent.

## Keep Reviews Focused

When responding to review feedback leads to changes unrelated to the review's purpose (e.g., updating rules/guidelines while reviewing an error handling audit), move those changes to a separate branch:

```bash
# Stash unrelated changes
git stash push -m "unrelated changes" <files>

# Switch to appropriate branch (often the base branch)
git checkout <target_branch>

# Apply and commit
git stash pop
git add <paths> && git commit -m "<message>"
git push origin <target_branch>

# Return to original branch
git checkout <original_branch>
```

This keeps the review focused on its intended scope and makes reviews easier.

## After LGTM Verification

After verifying and confirming an LGTM, note to the operator that the review is approved and further comment monitoring is unlikely to be needed. An approved review rarely receives new comments.
