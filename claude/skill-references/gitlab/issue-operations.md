---
description: "GitLab commands for listing issues, fetching details, and posting comments. (v2 stub — not yet implemented)"
---

# GitLab: Issue Operations

Placeholder for GitLab issue provider. Implementation deferred to v2.

See GitHub equivalent at `~/.claude/skill-references/github/issue-operations.md` for the interface pattern.

## Expected Commands (v2)

```bash
# List open issues
glab issue list --state opened

# Fetch single issue
glab issue view <IID>

# Fetch issue notes (comments)
glab api projects/:id/issues/:iid/notes

# Post issue comment
glab issue note <IID> --message-file <path>
```
