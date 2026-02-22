# LGTM Verification

When a reviewer posts an "LGTM" (Looks Good To Me) comment that includes their understanding of the PR:

1. **Compare their summary against actual implementation** - Create a checklist matching each point they mentioned to what was actually implemented
2. **Flag any mismatches** - If the reviewer's understanding doesn't match what was implemented, alert the user before proceeding
3. **Note items not mentioned** - If significant features were implemented but not mentioned in the LGTM, note these as well

## Example Verification

```
Reviewer's understanding vs Implementation:

| # | Reviewer's Description | Implemented? |
|---|------------------------|--------------|
| 1 | Adds benchmark ticker comparison | ✅ Yes |
| 2 | Consolidates chart generation | ✅ Yes |
| 3 | Adds tests for charts | ✅ Yes |

Additional changes not mentioned in LGTM:
- Restored emojis (from separate review comment)
- Extracted nested function (from separate review comment)

Verdict: LGTM understanding matches main features.
```

## Responding to Mismatched LGTM

When a reviewer's LGTM summary doesn't match the implementation, reply back politely indicating the mismatch. **Do not reveal the actual implementation** - instead, hint at where they should focus:

```bash
gh api repos/{owner}/{repo}/issues/{pr}/comments \
  -f body="Thanks for the review! However, that summary doesn't quite match what this PR implements.

I'd suggest taking a closer look at the changes in \`path/to/main/file.py\` and the new \`path/to/new/module.py\` to see what's actually being added here.

---
*Co-authored with Claude Opus 4.5*"
```

## Confirming Valid LGTM

When a reviewer's LGTM summary accurately reflects the implementation, reply back confirming:

```bash
gh api repos/{owner}/{repo}/issues/{pr}/comments \
  -f body="Thanks! That summary accurately reflects the PR. ✅

---
*Co-authored with Claude Opus 4.5*"
```
