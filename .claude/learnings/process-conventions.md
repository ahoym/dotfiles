# Process Conventions

Patterns for how engineering work is organized, scoped, and tracked.

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

### Author self-annotation and self-review as quality gate

When no reviewers are available, authors annotating their own code with design decisions creates a written record. Self-review on the diff view catches issues invisible during implementation — the diff presentation surfaces patterns (like repeated mock data) that aren't obvious in the editor. Not a substitute for external review, but better than no documentation.

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

### PR review response etiquette: reference fixing commit hash

When addressing PR review feedback, reply to each comment with the commit hash that fixes it (e.g., "Fixed in abc123"). Use an appreciative tone ("Thanks for catching this!"). When unclear, state your understanding then ask rather than guessing. When pushing back, explain context and ask for clarification rather than dismissing.

### Codify review feedback as reusable guidelines

Treat review feedback as a source of reusable guidelines rather than one-off corrections. After a review cycle, capture patterns into the project's guideline files (e.g., `.claude/guidelines/`) while context is fresh. Ship via lightweight docs-only PRs with zero-discussion, same-day merge.

### PR splitting strategy for large PRs

When splitting a large PR, separate refactors and structural changes first (independent, merge to main), features last (dependent, merge after structure). Structure → tests → feature is the natural dependency order.

### Relocate decision frameworks to the moment of use

When a decision framework (e.g., "separating universal from specific") lives in a general guideline but is only needed at one specific moment (e.g., capturing learnings), move it to the skill where it's actually used. Location should match the moment of use.

### LGTM response patterns

When addressing PR reviews that include "LGTM" summaries: (1) When the reviewer's summary doesn't match the actual implementation, reply politely indicating the mismatch and hint at where to look — don't reveal implementation details. (2) When the summary is accurate, confirm with a short acknowledgment.

### Structured footnotes for multi-agent comment identity

When multiple agents (addresser, reviewer) post comments from the same account, use structured metadata in comment footers to distinguish them:

```
---
*Co-Authored with [Claude Code](https://claude.ai/code) (<model>)*
*Persona:* <persona or "none">
*Role:* <Addresser|Reviewer|...>
```

The `Role` field enables role-based filtering: `select(.body | test("Role: Addresser"))` skips self-replies without false-positiving on reviewer bot comments. Better than content-based heuristics ("Co-authored") which can't distinguish between agents sharing an account.

### Never dismiss review comments as duplicates based on topic

Each comment ID is a distinct interaction requiring its own response — even if a previous comment covered the same topic. "Duplicate" means the exact same comment ID being re-processed, not a different comment about the same subject. Comments from different review passes are separate interactions, not redundant noise.

### Review summary vs inline comments: no duplication

Review summaries name themes ("some learnings may not earn their context cost"); inline comments carry the specifics ("this pattern on line 103 is basic OOP"). A reader skimming the summary gets the full picture without clicking into files; a reader reviewing the diff gets details in context. No finding should appear in both places.

- **Takeaway**: Summary = themes grouped by concern; inline = file-specific details. Zero overlap.

### Emoji reactions for resolved review comments

When re-reviewing a PR and a previous comment has been addressed, react with a 👍 emoji instead of posting a text reply. This signals acknowledgment without creating noise in the comment thread. Reserve text replies for partially-addressed or unresolved findings.

- **Takeaway**: Resolved = emoji react (lightweight); partially addressed = follow-up reply (substantive).

### Don't post empty reviews

If analysis produces no findings, no inline comments, no reactions, and no follow-ups, skip posting entirely. An empty review that says "no concerns" or "all findings resolved" adds noise to the PR thread without value. This applies to both first-review and re-review modes. The absence of a review is itself a signal — it means the reviewer found nothing to flag.

- **Takeaway**: No findings = no post. Silence is a valid review outcome.

### Verify safeguards survive fixes

When fixing one problem, verify the original problem's safeguards are preserved or replaced. Pattern: when removing a workaround, ask "what was this protecting against?" before deleting. After the fix, test that the original safeguard still works — not just that the symptom is gone.

Example: removing `?per_page=100` from URLs to fix quoting issues silently reverted to the 30-result default, hiding comments beyond page 1. The fix (`--paginate`) replaced the safeguard — but verification ("command runs without permission prompt" ✅ but "command still returns all results" ❌) would have caught the regression immediately.

### Keep Approval Flows On-Platform

When a skill interacts with a review platform (GitHub/GitLab), post suggestion summaries and approval requests as PR/MR comments — not CLI prompts. This keeps review context unified and enables async workflows (e.g., polling loops where the reviewer approves via the PR itself). The agent should only implement changes when explicit approval appears in a subsequent platform comment.

### Separate identification from suggestion in review comments

Identifying an issue ("this looks off") and suggesting a fix ("change it to X") are two distinct steps that require independent reasoning. Don't let the identification drive the suggestion mechanically — a rule that flags the issue may not prescribe the right fix, or may not even apply. The suggestion compounds: the addresser implements it, the reviewer confirms it, and both roles gain false confidence in a wrong fix. The operator then has to unwind multiple layers.

- **Verify rule scope before citing it.** A rule about "numbered steps in skills" doesn't apply to numbered lists in reference documents. Surface-level pattern matches ("3a looks like a half-step") are not sufficient — check that the rule's stated context matches.
- **Think independently about what would make the content better.** Even within a correctly-applied rule, the default remedy may be wrong. "Renumber sequentially" flattens a deliberate grouping; "restructure as sub-items" preserves the author's intent. Lead with the suggestion that improves the content, not the one the rule defaults to.
- **When uncertain, identify without prescribing.** "This `3a` numbering looks odd — is the intent to group these as variants of the same gotcha, or are they independent items?" surfaces the issue without committing to a fix direction.

### Fix the source, not just the behavior

When a correction traces back to a template or reference file, fix the file — not just your current behavior. Otherwise the next session reads the same bad template and repeats the mistake. If you're corrected on a command format and the command came from a template, update the template immediately.

### Update PR Description When Scope Drifts During Review

When mid-review work significantly expands a PR's scope beyond its original intent (e.g., an extraction PR gains cron infrastructure, permission patterns, and new learnings sections), update the PR title and description before shipping. Future readers use the description to set expectations — a mismatch between title and content makes the PR harder to review and reference.

## See also

- `~/.claude/learnings/multi-agent-patterns.md` — agent-to-agent review cycle and mutual agreement patterns that reference the structured footnote convention defined here
- `~/.claude/learnings/code-quality-instincts.md` — code-level quality patterns (complementary: code vs process)
