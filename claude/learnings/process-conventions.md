Patterns for how engineering work is organized, scoped, and tracked — PR splitting, MR scoping, phased delivery, and preparatory refactoring.
- **Keywords:** PR splitting, MR scoping, cherry-pick, preparatory refactoring, scope creep, staged renames, plan-first PR, PR description, git history, safeguards
- **Related:** ~/.claude/learnings/review-conventions.md, ~/.claude/learnings/code-quality-instincts.md

---

### Defer large cross-cutting refactors to tracked issues

When code review surfaces a systemic improvement (e.g., float-to-Decimal conversion), file an issue rather than scope-creeping the current PR. The PR stays focused; the improvement gets tracked. Even for straightforward rename/reorganization tasks, creating an issue first establishes traceability and makes the "why" discoverable later (`Fixes #N` for clean linking).

### Plan-first PRs as exploration pattern

PRs that include a plan document alongside implementation code serve as design artifacts. Even when the PR is ultimately closed, the planning work feeds into the decision — the analysis itself is the value. However, plan PRs scoped too narrowly get superseded — when planning refactors that touch data types flowing across module boundaries, scope the plan to the full data flow path, not just the module where symptoms are most visible.

### Closing PRs cleanly with cherry-pick intent

Rather than silently abandoning a PR, explicitly note that unique content will be cherry-picked into a follow-up. Makes the closed PR a discoverable record of what was tried and what content is still pending. Tactical approach: when a "lite" version gets merged first, close the redundant PR, create a new branch from main, manually add only the unique content (don't cherry-pick commits if files diverged), and open a focused PR.

### Scope MRs tightly — one concern per merge request

Breaking changes bundled with new features make review, rollback, and changelog tracking harder. Ship separately. Large exploratory MRs (47+ files) get closed. Cross-cutting refactors with zero pre-alignment face high closure risk. Small, focused MRs (4 files, single purpose) get same-day turnaround. Tangential changes (e.g., CLAUDE.md update in a feature PR) get their own PR, even if small.

### Ship integration client separately from orchestration wiring

Ship the client (HTTP wrapper, DTOs, auth) as a standalone MR before the orchestration. Reduces review complexity and isolates failure domains.

### Self-documenting MR descriptions

For larger MRs, state which files contain the important business logic. Guides reviewers to spend time where it matters.

### Migration conflict resolution should be documented

State the original version and new version in the MR description. Makes it easy for reviewers to verify without digging through diffs.

### Large renames should be staged

Prioritize internal renames to unblock dependent MRs, deferring deployment-visible changes (Docker image paths, pipeline configs).

### Preparatory refactoring deserves its own MR

"Make the change easy, then make the easy change." Separating refactoring from feature work keeps both MRs focused. The refactoring MR establishes the new structure; the feature MR builds on it.

### READMEs should lead with prerequisites

Users need to know what to install before following setup steps. Structure: prerequisites first, then setup, then usage.

### Sensitive data audit checklist for shared dotfiles

Audit for: internal project/repo names, MR/PR numbers, absolute paths with usernames, internal tool names, team names, org-specific identifiers. Focus effort on tracked files; `settings.local.json` is gitignored.

### PR splitting strategy for large PRs

When splitting a large PR, separate refactors and structural changes first (independent, merge to main), features last (dependent, merge after structure). Structure → tests → feature is the natural dependency order.

### Relocate decision frameworks to the moment of use

When a decision framework (e.g., "separating universal from specific") lives in a general guideline but is only needed at one specific moment (e.g., capturing learnings), move it to the skill where it's actually used. Location should match the moment of use.

### Verify safeguards survive fixes

When fixing one problem, verify the original problem's safeguards are preserved or replaced. Pattern: when removing a workaround, ask "what was this protecting against?" before deleting. After the fix, test that the original safeguard still works — not just that the symptom is gone.

Example: removing `?per_page=100` from URLs to fix quoting issues silently reverted to the 30-result default, hiding comments beyond page 1. The fix (`--paginate`) replaced the safeguard — but verification ("command runs without permission prompt" ✅ but "command still returns all results" ❌) would have caught the regression immediately.

### Fix the source, not just the behavior

When a correction traces back to a template or reference file, fix the file — not just your current behavior. Otherwise the next session reads the same bad template and repeats the mistake. If you're corrected on a command format and the command came from a template, update the template immediately.

### Update PR Description When Scope Drifts During Review

When mid-review work significantly expands a PR's scope beyond its original intent (e.g., an extraction PR gains cron infrastructure, permission patterns, and new learnings sections), update the PR title and description before shipping. Future readers use the description to set expectations — a mismatch between title and content makes the PR harder to review and reference.

## Verify PR Description Claims Against Git History

Before editing a PR description to say "adds X" or "removes Y", verify with `git log <base>..<branch> -- <file>`. Don't rely on `git diff <base>` — a file that appears "deleted" in the diff may have been added to base *after* the branch was cut, meaning the branch never touched it. `git log` is authoritative; `git diff` can mislead when branches diverge.

```bash
# Confirm a file was actually touched by this branch
git log main..HEAD -- path/to/file.md
# Empty output = branch never touched it (don't claim it in the PR description)
```

### Calibrate Flag-Worthy Observations to Operator-Cession Tier

Surfacing every discovery erodes trust in flags as much as missing real ones. Apply the same tier system as decision-making:

- **Routine observations** (small inconsistencies, transient state, things that resolve themselves) → log silently to memory, follow-up doc, or just hold. Don't surface inline.
- **Substantive observations** (things that change the operator's plan, real bugs, broken contracts, unexpected behavior with downstream impact) → flag inline.

Failure mode: over-flagging tiny discoveries creates noise that the operator has to filter, training them to ignore flags — including the substantive ones. This is the same shape as the decide-silently / decide-with-report / escalate framework: routine work doesn't need surfacing.

Concrete examples of routine (silent log): a transient `last_comment_id: none` in one cycle's status that recovers next cycle; a runner state file that looks stale but resolves on completion notification; a one-off naming inconsistency in a generated artifact. Concrete examples of substantive (flag inline): a stale-ref class of bug that affects multiple files; a permission pattern gap blocking work; intent drift between PR description and delivered diff.

### Check git history for prior art before designing new protocol features

When adding features to a protocol or system, check git history for previously removed versions of the same concept. Prior art often contains design decisions, failure modes, and refinements that save reinvention. The removed version may need only a targeted fix rather than a from-scratch redesign.

## Cross-Refs

- `~/.claude/learnings/review-conventions.md` — code review patterns (complementary: workflow vs review)
- `~/.claude/learnings/code-quality-instincts.md` — code-level quality patterns (complementary: code vs process)

### Remove TODOs before merging to main
TODOs in production code are deferred decisions that accumulate silently. Resolve them before merge or convert to tracked tickets with context. A TODO without a ticket reference is a promise nobody is tracking.
