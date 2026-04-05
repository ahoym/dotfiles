---
description: "GitHub commands for listing issues, fetching details, posting comments, and checking linked PRs."
---

# GitHub: Issue Operations

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters.

## List Open Issues

```bash
# All open issues (default limit 30)
gh issue list --state open --json number,title,body,labels,assignees --limit <LIMIT>

# Filtered by label (repeat --label for multiple)
gh issue list --state open --label <LABEL> --json number,title,body,labels,assignees --limit <LIMIT>

# Multiple labels (AND logic)
gh issue list --state open --label <LABEL1> --label <LABEL2> --json number,title,body,labels,assignees --limit <LIMIT>
```

## Fetch Single Issue (with comments)

```bash
gh issue view <NUMBER> --json number,title,body,labels,assignees,comments,url
```

## Fetch Issue Comments

For fine-grained filtering (timestamps, user), use the API directly:

```bash
gh api repos/{owner}/{repo}/issues/<NUMBER>/comments --paginate --jq '.[] | {id, body, user: .user.login, created_at}'
```

## Post Issue Comment

Write body to file first to avoid HEREDOC permission prompts. **Use absolute paths** — `gh` resolves file paths relative to the shell's CWD.

```bash
# Write body via Write tool to tmp/claude-artifacts/sweep-work-items/clarify-<NUMBER>.md, then:
gh issue comment <NUMBER> --body-file /absolute/path/to/tmp/claude-artifacts/sweep-work-items/clarify-<NUMBER>.md
```

## Check for Linked PRs (by branch name pattern)

```bash
gh pr list --state open --json headRefName,number,url
```

Filter client-side for branches matching `sweep/<NUMBER>-*`.

## Detect Sweeper Comments

Fetch all comments and scan for the Sweeper footnote:

```bash
gh api repos/{owner}/{repo}/issues/<NUMBER>/comments --paginate
```

Parse the JSON response — look for `Role:.*Sweeper` in comment bodies. Do not use `--jq` with complex filters to avoid quoted-string permission prompts. Check:
- If a Sweeper comment exists with no subsequent non-Sweeper comment → awaiting reply
- If a Sweeper comment exists with a subsequent non-Sweeper comment → re-assess eligible
