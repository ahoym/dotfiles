Patterns for code review interactions — review judgment, self-review, reviewer behavior, comment etiquette, structured footnotes, approval flows, and review identity.
- **Keywords:** code review, self-review, LGTM, structured footnotes, review comments, emoji reactions, approval flow, reviewer identity, multi-agent review, empty reviews, comment etiquette, identification vs suggestion, prioritization, reversibility, scope discipline
- **Related:** ~/.claude/learnings/process-conventions.md, ~/.claude/learnings/claude-code/multi-agent/orchestration.md

---

### Author self-annotation and self-review as quality gate

When no reviewers are available, authors annotating their own code with design decisions creates a written record. Self-review on the diff view catches issues invisible during implementation — the diff presentation surfaces patterns (like repeated mock data) that aren't obvious in the editor. Not a substitute for external review, but better than no documentation.

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

### PR review response etiquette: reference fixing commit hash

When addressing PR review feedback, reply to each comment with the commit hash that fixes it (e.g., "Fixed in abc123"). Use an appreciative tone ("Thanks for catching this!"). When unclear, state your understanding then ask rather than guessing. When pushing back, explain context and ask for clarification rather than dismissing.

### Codify review feedback as reusable guidelines

Treat review feedback as a source of reusable guidelines rather than one-off corrections. After a review cycle, capture patterns into the project's guideline files (e.g., `.claude/guidelines/`) while context is fresh. Ship via lightweight docs-only PRs with zero-discussion, same-day merge.

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

### Emoji reactions for resolved review comments

Resolved/acknowledged comments are reaction-only — 🚀 for resolved (code change verified), 👍 for acknowledged (agreed, pending fix). No text reply, since it would just re-iterate the addresser's fix. Text replies are reserved for partially-addressed and not-addressed cases that carry new content. Canonical rules: `~/.claude/skill-references/review-comment-classification.md`.

### Don't post empty reviews — unless triggered by new commits

If analysis produces no findings, no inline comments, no reactions, and no follow-ups, the default is to skip posting entirely. However, when the review was triggered by new commits (not just a rerun with no activity), post a brief confirmation (e.g., "Reviewed `<sha>` — no new findings") so operators can verify the commit was actually reviewed. The absence of a review is ambiguous — it could mean "nothing to review" or "review ran and found nothing." New-commit re-reviews should disambiguate by posting.

### Keep Approval Flows On-Platform

When a skill interacts with a review platform (GitHub/GitLab), post suggestion summaries and approval requests as PR/MR comments — not CLI prompts. This keeps review context unified and enables async workflows (e.g., polling loops where the reviewer approves via the PR itself). The agent should only implement changes when explicit approval appears in a subsequent platform comment.

### Separate identification from suggestion in review comments

Identifying an issue ("this looks off") and suggesting a fix ("change it to X") are two distinct steps that require independent reasoning. Don't let the identification drive the suggestion mechanically — a rule that flags the issue may not prescribe the right fix, or may not even apply. The suggestion compounds: the addresser implements it, the reviewer confirms it, and both roles gain false confidence in a wrong fix. The operator then has to unwind multiple layers.

- **Verify rule scope before citing it.** A rule about "numbered steps in skills" doesn't apply to numbered lists in reference documents. Surface-level pattern matches ("3a looks like a half-step") are not sufficient — check that the rule's stated context matches.
- **Think independently about what would make the content better.** Even within a correctly-applied rule, the default remedy may be wrong. "Renumber sequentially" flattens a deliberate grouping; "restructure as sub-items" preserves the author's intent. Lead with the suggestion that improves the content, not the one the rule defaults to.
- **When uncertain, identify without prescribing.** "This `3a` numbering looks odd — is the intent to group these as variants of the same gotcha, or are they independent items?" surfaces the issue without committing to a fix direction.

### Prioritize findings by impact, not discovery order

When a review produces more findings than the author can reasonably act on, rank by:
1. **Dependencies** — does anything block on this fix? (e.g., a broken interface downstream code relies on)
2. **Risk of delay** — what's the cost of merging now vs. fixing first? One-way doors (data model changes, public APIs) rank higher than easily reversed choices.
3. **Learning value** — does surfacing this teach the author something that prevents future issues?
4. **Scope fit** — is this actionable in this PR, or is it really a follow-up?

Drop findings that don't clear at least one bar. "Valid but low-priority" is noise.

### Weigh reversibility when deciding what to push on

Not all findings deserve equal pushback. A naming suggestion (easily changed later) deserves less debate weight than a public API contract or data model change (one-way door). Invest review effort proportionally to how hard the decision is to undo. When two suggestions are close in value, favor the one the author can easily change later — save strong convictions for irreversible choices.

### Scope discipline: "not for this PR" is a finding

Flagging scope creep is as valuable as flagging bugs. "Valid but not for this PR" is a call reviewers should actively make — look for findings that belong in follow-ups and redirect them there rather than inflating the review with out-of-scope suggestions.

### Smaller, focused MRs get merged faster than mixed-scope ones

Focused single-purpose MRs (one fix, one feature) get same-day review and merge. Cross-cutting MRs touching many files across multiple layers go through multiple force-push cycles and take days. This isn't just about reviewer convenience — each review round on a large MR operates on a changing diff, making it harder to track what's been addressed. When a change naturally spans multiple layers, split it into stacked MRs by layer (domain model, persistence, service/gRPC) rather than one monolithic MR.

### Resolved review suggestions may not have been applied

Both inline review comments with code suggestions and bot-generated suggestions can be "resolved" by the author without applying the suggested change. Resolved threads signal "addressed" to reviewers, but the underlying issue may persist. During re-review, check that resolved threads with code suggestions actually had the fix applied — don't assume resolution equals implementation.

### Re-review: orchestrator-handled verification when fixes are surgical

For multi-persona team-review re-cycles, skip re-launching subagents when each fix commit names the addressed comment ID and changes are well-scoped to one finding. The orchestrator (with team-lead + reviewer lens) can read the new code at the changed lines directly. Re-launching three persona subagents on surgical, single-purpose fixes burns context for no signal gain.

**Re-launch instead when:** broad refactor commits touch unrelated areas, fix commits don't reference the addressed comment, or fixes introduce new public surface (helpers, types, modules) where domain-specific concerns might emerge. Cheap heuristic: if `git log --oneline` since `LAST_REVIEW_TS` reads like a series of `Addresses review comment #X` lines, skip subagents and verify directly.

### Pushback during review: accept vs re-raise

Pushback (addresser declines a finding with reasoning) is a prompt for team-lead deliberation, not a fourth classification. Reflexively maintaining is as wrong as reflexively accepting. Decide via two filters:

- **Accept** when (a) the underlying concern is addressed orthogonally (e.g., structural suggestion declined but auditability addressed via per-account logging), AND (b) the change is high-reversibility (cosmetic, naming, structure of a small collection). Reply with concur + reasoning, mark thread resolved.
- **Re-raise with new context** when the pushback misses the actual failure mode, or the change is low-reversibility (data model, public API, irreversible state).

The auditability/correctness concern that motivated the original finding is the load-bearing piece — if it's been satisfied another way, the structural form rarely matters.

## Re-review after rebase = fresh first-review semantics

When a PR is rebased onto a new base (split, restack, dependency-update force-push), the rebase commit replaces all file content from the old base's perspective — there are no "new commits to scope to" in the diff vs the new base, only one rebase commit that re-presents the entire branch. Re-review tooling that scopes findings to "commits since last review" silently produces zero findings. Detection: rebase commits show every file in the branch with the entire file marked as added/removed. Action: treat the rebased diff as a fresh first-review and run all personas against the full diff.

### PR scope = diff vs new base, not vs old-cycle head

`git diff <prev-cycle-head>..<head>` after a rebase pulls in every change that landed on main between the old base and new base — for an active main, that's typically dozens of unrelated files. Use `git diff <PR-base>..<head>` (diff vs current main) to see PR scope. Diagnostic: if the diff stat lists files unrelated to the PR's stated purpose (docs sweeps, sibling-feature additions, infra changes), you're seeing rebase noise. Switch to base-vs-head before reasoning about findings — code inherited from a recently-merged sibling PR can otherwise look like a new addition and produce false-positive findings.

## Body-content role-footnote filters drift; prefer timestamp-based filtering

A `body ~ "Role: Team-Reviewer"` filter for "comments from previous team review" breaks when the footnote format drifts between cycles (`*Role: Team-Reviewer*` vs `*Role:* Team-Reviewer`). The footnote is human-edited prose; format conventions evolve. For "comments since last team review", store `LAST_REVIEW_TS` and filter `created_at > LAST_REVIEW_TS` — this is invariant to footnote format. Body-content role-tag filters remain valid as a per-comment role check on individual comments, just not as the primary cycle discriminator.

## Author = Reviewer Identity Surface (AI-Assisted Workflows)

In AI-assisted development, the same git/platform user often posts as both PR author *and* reviewer-bot. Identity heuristics that assume "author ≠ reviewer" misfire — username-based self-filters mark reviewer comments as "self" and skip them. **Rule:** key self-filter on the structured footnote `Role:` tag (e.g., `Role: Team-Reviewer`, `Role: Addresser`), not the username. Same applies to "find someone else to review" prompts — the dimension that matters is the agent role, not the account.

## Cross-Refs

- `~/.claude/learnings/process-conventions.md` — PR/MR scoping and workflow patterns (complementary: workflow vs review)
- `~/.claude/learnings/claude-code/multi-agent/orchestration.md` — agent-to-agent review cycle and mutual agreement patterns that reference the structured footnote convention defined here
- `~/.claude/learnings/git-github-api.md` — `commit_id` mutation and empty-body review records that motivate timestamp-based filtering
