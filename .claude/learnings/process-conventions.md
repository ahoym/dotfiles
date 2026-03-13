# Process Conventions

Patterns for how engineering work is organized, scoped, and tracked.

### Defer large cross-cutting refactors to tracked issues

When code review surfaces a systemic improvement (e.g., float-to-Decimal conversion), file an issue rather than scope-creeping the current PR. The PR stays focused; the improvement gets tracked.

- **Takeaway**: Systemic improvements surfaced during review = new issue, not PR scope expansion.

### Plan-first PRs as exploration pattern

PRs that include a plan document alongside implementation code serve as design artifacts. Even when the PR is ultimately closed, the planning work feeds into the decision — the analysis itself is the value.

- **Takeaway**: Exploration PRs that get closed still produce value through their analysis.

### Closing PRs cleanly with cherry-pick intent

Rather than silently abandoning a PR, explicitly note that unique content will be cherry-picked into a follow-up. Makes the closed PR a discoverable record of what was tried and what content is still pending.

- **Takeaway**: Close PRs with documented intent — what's abandoned vs. what's being carried forward.

### Scope MRs tightly — one concern per merge request

Breaking changes bundled with new features make review, rollback, and changelog tracking harder. Ship separately. Large exploratory MRs (47+ files) get closed. Cross-cutting refactors with zero pre-alignment face high closure risk. Small, focused MRs (4 files, single purpose) get same-day turnaround.

### Ship integration client separately from orchestration wiring

Ship the client (HTTP wrapper, DTOs, auth) as a standalone MR before the orchestration. Reduces review complexity and isolates failure domains.

### Self-documenting MR descriptions

For larger MRs, state which files contain the important business logic. Guides reviewers to spend time where it matters.

### Author self-annotation as review substitute

When no reviewers are available, authors annotating their own code with design decisions creates a written record. Not a substitute for review, but better than no documentation.

### Migration conflict resolution should be documented

State the original version and new version in the MR description. Makes it easy for reviewers to verify without digging through diffs.

### Large renames should be staged

Prioritize internal renames to unblock dependent MRs, deferring deployment-visible changes (Docker image paths, pipeline configs).

### Preparatory refactoring deserves its own MR

"Make the change easy, then make the easy change." Separating refactoring from feature work keeps both MRs focused. The refactoring MR establishes the new structure; the feature MR builds on it.

### Reviewers picking up adjacent work

When a reviewer identifies work they can do to unblock or improve the MR, they create a parallel MR. Healthy collaboration pattern.

### Review summaries must accurately reflect changes

Superficial LGTMs with inaccurate summaries are worse than no summary. Verify your summary matches the actual diff.

### Two-step review: question placement, then request extraction

First ask "does this need to be here?" with a concrete test. Get analysis back, then decide whether to request extraction. Avoids premature refactoring requests.

### Remove cross-cutting concerns to separate PRs

Tangential changes (e.g., CLAUDE.md update in a feature PR) get their own PR, even if small.

### Automated reviewers can create false sense of coverage

AI catches mechanical issues (null checks, config formatting, constraint/message mismatches). Humans catch architectural and security concerns. Both are complementary. Monitor whether automated tools supplement or replace human review.

### E2E evidence in MR comments for infrastructure changes

Infrastructure changes should include screenshots and DB query results before merge. Concrete proof the change works in a real environment.

### Reviewer-initiated regression analysis on data model changes

When changes affect data model relationships, reviewers should independently trace the full data flow to verify no regressions.

### Commented-out code in migrations needs context

Migrations are immutable after deployment. Commented-out SQL needs context about why and whether it should be re-enabled.

### READMEs should lead with prerequisites

Users need to know what to install before following setup steps. Structure: prerequisites first, then setup, then usage.

### Sensitive data audit checklist for shared dotfiles

Audit for: internal project/repo names, MR/PR numbers, absolute paths with usernames, internal tool names, team names, org-specific identifiers. Focus effort on tracked files; `settings.local.json` is gitignored.
