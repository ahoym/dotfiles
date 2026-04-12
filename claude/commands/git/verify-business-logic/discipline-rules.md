# Discipline Rules

Canonical structural rules for the convergence verifier. Each rule is an assertion — pass or fail, with cited evidence. These are distilled from the review and address skill references.

## Rule 1: Footnote Format

Every externally-posted comment (review body, inline comment, thread reply) must end with the identity footnote.

**Assertion**: All agent-posted comments contain:
```
---
- *Co-Authored with [Claude Code](https://claude.ai/code) (<model>)*
- *Persona:* <persona-name or "none">
- *Role:* <Reviewer|Addresser>
```

**How to check**: Fetch all comments with `Role:` tag. Verify three fields present: Co-Authored, Persona, Role. Flag comments missing any field.

**What to cite**: Comment ID + which field is missing.

## Rule 2: Body Shape — No Duplication

Review body contains themes only. File-specific details belong in inline comments, not the summary.

**Assertion**: Review body `## Findings` section contains no file paths, line numbers, or code snippets. Those appear only in inline comments.

**How to check**: Parse review body for file path patterns (`path/to/file`, line numbers like `L42`, code fences in findings section).

**What to cite**: Review comment ID + the leaked file-specific detail.

## Rule 3: Reaction Discipline

Resolved and acknowledged threads get emoji reactions only — no text reply restating the fix.

**Assertion**: For threads classified as resolved or acknowledged:
- A reaction emoji exists (rocket for resolved, thumbsup for acknowledged)
- No text reply from the reviewer *after* the addresser's fix/acknowledgement
- Exception: operator comments (no `Role:` tag) always reopen the thread

**How to check**: For each thread with a reviewer reaction emoji, verify no subsequent reviewer text reply exists on that thread. Ignore operator comments that reopen.

**What to cite**: Thread ID + the unnecessary text reply comment ID.

## Rule 4: Loop Closure

Every inline finding has a response. No orphaned threads.

**Assertion**: For every reviewer inline comment:
- At least one of: addresser reply, reviewer reaction (resolved/acknowledged), or explicit "no action needed" signal
- No threads where the reviewer posted a finding and received zero responses

**How to check**: Walk all reviewer inline comments. For each, check for replies (addresser text or reviewer reaction). Flag threads with zero responses.

**What to cite**: Original reviewer comment ID + thread URL.

**Note**: Missing responses may indicate the address cycle hasn't completed rather than a discipline failure. Check timing — if the address runner converged and the thread is still orphaned, it's a finding.

## Rule 5: No Bare Issue References

Comments avoid bare `#N` which GitHub auto-links unexpectedly.

**Assertion**: Agent-posted comments use backtick-wrapped `` `#N` `` or omit `#` entirely.

**How to check**: Search agent comments for bare `#\d+` not inside backticks or code fences.

**What to cite**: Comment ID + the bare reference.

**Severity**: Low — cosmetic, but breaks when referencing non-existent issues.

## Rule 6: Empty Review Guard

Reviews with no findings should not be posted (exception: confirming new commits reviewed).

**Assertion**: Every posted review body contains at least one finding, one inline comment, or is explicitly a "no new findings" confirmation after new commits.

**How to check**: Parse review bodies. Flag reviews with empty `## Findings` and zero inline comments that aren't commit-confirmation reviews.

**What to cite**: Review comment ID.

## Applying Rules

Run all rules. Report as a checklist:

```
### Discipline Check

- [x] **Footnote format** — all 12 agent comments have valid footnotes
- [ ] **Body shape** — review body leaks file path `src/auth.ts` (comment #456)
- [x] **Reaction discipline** — 3 resolved threads, all reaction-only
- [x] **Loop closure** — 8/8 inline findings have responses
- [x] **Issue references** — no bare `#N` found
- [x] **Empty review guard** — no empty reviews posted
```

Failed assertions include the specific citation. Passed assertions include counts for operator confidence.
