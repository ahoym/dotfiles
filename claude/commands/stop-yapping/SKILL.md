---
name: stop-yapping
description: "Pass over comments added, modified, removed, or stale in a branch or MR/PR — tighten to WHY-not-WHAT and strip MR/phase artifacts. Auto-applies."
argument-hint: "[request-number | request-url]"
allowed-tools: Bash, Edit, Glob, Grep, Read
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Stop Yapping

Audit comments touched (added, modified, or deleted) in a branch or request, plus comments still in surviving code whose surrounding context shifted enough to make them stale. Rewrite to focus on **WHY**, strip artifacts (MR/PR refs, phase framing, transition language, restated identifiers), and auto-apply.

## Usage

- `/stop-yapping` — Audit comments in the current branch (`main..HEAD`)
- `/stop-yapping <number>` — Audit comments in a specific MR/PR
- `/stop-yapping <url>` — Audit comments in MR/PR by URL

## Scope of Audit

Three buckets, all in scope by default:

1. **Added or modified comments** — any comment whose text changed in the diff. Re-read the *full enclosing comment block* in the working tree (not just the changed lines), since context-free fragments mislead.
2. **Removed comments** — comment text on `-` lines in the diff. Check whether the WHY still applies to the surviving code; if yes, propose restoring (possibly reworded).
3. **Stale survivors** — unchanged comments in files the diff touched, where the surrounding code shifted enough that the comment no longer matches. Scoped to touched files only — do not scan the rest of the repo.

## Instructions

### 1. Resolve the audit target

Parse `$ARGUMENTS`:
- **Empty** → audit current branch. Diff target: `git merge-base HEAD main` (fall back to `origin/main` if `main` is absent).
- **Numeric** → MR/PR number on the current repo's remote.
- **URL** → extract the number from the URL path (GitHub: `/pull/<n>`; GitLab: `/-/merge_requests/<n>`).

For the MR/PR case, detect the platform from the origin remote (`github.com` → github, otherwise gitlab), then fetch metadata + diff using:
- `~/.claude/skill-references/<platform>/commands/fetch-review-details.sh`
- `~/.claude/skill-references/<platform>/commands/fetch-review-diff.sh`
- `~/.claude/skill-references/<platform>/commands/fetch-review-files.sh`

For the branch case:
- `git diff <merge-base>...HEAD` for the diff
- `git diff --name-only <merge-base>...HEAD` for the file list

### 2. Identify comment loci

For each file in the changed set, classify hunks:

- **Added/modified comments**: scan `+` lines for comment markers (`//`, `/*`, `*`, `/**`). For each match, locate the full comment block in the working file by reading a window around the hunk line. Capture: file, start line, end line, current text.
- **Removed comments**: scan `-` lines for comment markers. Capture the deleted text and the line number it was attached to (now occupied by surviving code).
- **Stale survivors**: read each touched file in full. For each existing comment block, sniff coherence with the immediately following code (typically the next 5–20 lines). Flag only when the mismatch is concrete — referenced identifiers no longer exist, described behavior contradicts the code, named invariants no longer hold. Do not flag on style/verbosity grounds (that's bucket 1's job).

Skip: license headers, generated-file markers, JSX/HTML markup comments, comments inside string literals.

### 3. Apply the audit lens to each capture

For every comment captured, decide one of: **keep as-is**, **rewrite**, **delete**, **restore** (for removed-but-should-stay).

| Pattern | Action | Override / notes |
|---------|--------|-----------------|
| MR/PR ref: `(MR !165)`, `(#42)`, `(added by !158)` | strip | preserve only when the ref IS the load-bearing WHY pointer and no other anchor exists |
| Transition framing: "Now X", "Was renamed from Z", "Switched from" | strip | never — git history covers this |
| Phase language: "Phase 1 adds", "For now", "Eventually we'll" | strip | never |
| Restated identifier: `fetchY()` + "Helper that fetches Y" | strip | never |
| Ceremony opener: "Note that…", "It should be noted…" | strip | never |
| Anchored `TODO(JIRA-xxx)` / `FIXME(JIRA-xxx)` | preserve | content separately rotted |
| Unanchored `TODO` / `FIXME` | flag | rewrite with ticket ref if operator can supply one; otherwise delete or convert to WHY comment |
| Non-obvious server/library contract | preserve | contract no longer holds |
| Invariant or race/safety note | preserve | no longer applies |
| Named source-of-truth pointer (controller, constant, contract) | preserve (strip any MR ref, keep symbolic anchor) | pointer no longer exists |
| JSDoc tags: `@param`, `@returns`, `@deprecated`, `@throws`, `@see` | preserve | tag is incorrect for current signature |

**Format rule**: multi-line prose uses `/* */`, not stacked `//`. Single line uses `//`. JSDoc uses `/** */`.

### 4. Auto-apply

Execute as one logical pass:
- Edit each comment in-place.
- Restore comments flagged in bucket 2 (removed-but-should-stay), inserting at the appropriate location in the surviving code.
- For stale survivors (bucket 3), rewrite to match the current behavior, or delete if no longer relevant.

Do not commit. The operator reviews the diff and commits manually. Revert path: `git restore <file>` per file, or `git restore .` for the whole pass — single-revert is the safety net for auto-apply.

### 5. Report

Print a summary grouped by bucket:

```
📝 Tighten Comments — branch feature/foo (12 comments processed)

ADDED / MODIFIED (8)
  src/api/orders.ts:186          5 lines → 2 lines   stripped MR ref + transition
  src/api/orders.ts:201         10 lines → 6 lines   stripped MR ref
  src/api/queries/orders.ts:75  15 lines → 9 lines   dropped restated return type
  ...

REMOVED-BUT-RESTORED (1)
  src/api/orders.ts:312          restored — invariant still applies to surviving code

STALE SURVIVORS (2)
  src/entities/index.ts:1086  rewrote — referenced `legacy_id` no longer exists
  src/api/orders.ts:340          deleted — described behavior contradicts current code

UNCHANGED (1)
  src/api/tests/orders.test.ts:42  already concise WHY-comment

⚠️ FLAGGED (needs operator input)
  src/api/orders.ts:120  // TODO: clean up later
    → no JIRA anchor; rewrite with ticket ref or delete?
```

### 6. Operator gate (flagged items only)

For each flagged TODO/FIXME or any rewrite where the WHY is ambiguous, present the options and wait for the operator. Do not auto-apply on ambiguous cases.

## Cross-Refs

| Next Step | Skill |
|-----------|-------|
| Create / update the MR/PR | `/git:create-request` |
| Address review comments | `/git:address-request-comments` |
| Split a large MR/PR | `/git:split-request` |

## Important Notes

- **Don't manufacture rewrites.** If a comment already says WHY tightly, mark it unchanged in the report. The skill's value is removing noise, not generating churn.
