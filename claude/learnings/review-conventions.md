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

## Cross-Refs

- `~/.claude/learnings/process-conventions.md` — PR/MR scoping and workflow patterns (complementary: workflow vs review)
- `~/.claude/learnings/claude-code/multi-agent/orchestration.md` — agent-to-agent review cycle and mutual agreement patterns that reference the structured footnote convention defined here
