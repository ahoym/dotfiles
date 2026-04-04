Staged entries for enrichment of ~/.claude/learnings/review-conventions.md

---

### Smaller, focused MRs get merged faster than mixed-scope ones

Focused single-purpose MRs (one fix, one feature) get same-day review and merge. Cross-cutting MRs touching many files across multiple layers go through multiple force-push cycles and take days. This isn't just about reviewer convenience — each review round on a large MR operates on a changing diff, making it harder to track what's been addressed. When a change naturally spans multiple layers, split it into stacked MRs by layer (domain model, persistence, service/gRPC) rather than one monolithic MR.

### Resolved review suggestions may not have been applied

Both inline review comments with code suggestions and bot-generated suggestions can be "resolved" by the author without applying the suggested change. Resolved threads signal "addressed" to reviewers, but the underlying issue may persist. During re-review, check that resolved threads with code suggestions actually had the fix applied — don't assume resolution equals implementation.
