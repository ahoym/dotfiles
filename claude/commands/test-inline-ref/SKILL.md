---
name: test-inline-ref
description: "Test skill to validate inline reference command extraction."
argument-hint: "<pr-number>"
allowed-tools:
  - Bash
  - Read
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`
- Platform: !`git remote get-url origin 2>/dev/null | grep -qi gitlab && echo gitlab || echo github`

## Inlined Commands (extracted at load time)

### Fetch Review Details
!`p=$(git remote get-url origin 2>/dev/null | grep -qi gitlab && echo gitlab || echo github); sed -n '/^## Fetch Review Details$/{n; :l; /^## /q; p; n; b l}' ~/.claude/skill-references/$p/fetch-review-data.md 2>/dev/null || sed -n '/^## Fetch Review Details$/{n; :l; /^## /q; p; n; b l}' claude/skill-references/$p/fetch-review-data.md`

### Fetch Files Changed
!`p=$(git remote get-url origin 2>/dev/null | grep -qi gitlab && echo gitlab || echo github); sed -n '/^## Fetch Files Changed$/{n; :l; /^## /q; p; n; b l}' ~/.claude/skill-references/$p/fetch-review-data.md 2>/dev/null || sed -n '/^## Fetch Files Changed$/{n; :l; /^## /q; p; n; b l}' claude/skill-references/$p/fetch-review-data.md`

### Fetch Commits
!`p=$(git remote get-url origin 2>/dev/null | grep -qi gitlab && echo gitlab || echo github); sed -n '/^## Fetch Commits$/{n; :l; /^## /q; /^$/{ n; /^$/q; /^[#A-Z]/q; }; p; n; b l}' ~/.claude/skill-references/$p/fetch-review-data.md 2>/dev/null || sed -n '/^## Fetch Commits$/{n; :l; /^## /q; /^$/{ n; /^$/q; /^[#A-Z]/q; }; p; n; b l}' claude/skill-references/$p/fetch-review-data.md`

## Instructions

1. **Parse review number** from `$ARGUMENTS`.

2. **Fetch review metadata** (run in parallel) — use the exact commands from the "Inlined Commands" section above, substituting `<number>` with the review number:
   - Run **Fetch Review Details**
   - Run **Fetch Files Changed**
   - Run **Fetch Commits**

3. **Display results** — print the fetched metadata in a summary format.

4. Done. This is a test skill — just confirm the commands were executed as inlined above.
