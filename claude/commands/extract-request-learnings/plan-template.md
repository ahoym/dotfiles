# Review Learnings Extraction Plan

## Objective

Systematically extract learnings from all <REVIEW_COUNT> reviews in the <REPO_NAME> repo.

## Decisions

- **Order**: Oldest-first (resilient to new reviews being pushed during extraction)
- **Scope**: All review states (open, merged, closed)
- **Batch size**: 5 reviews per batch
- **Discussion reviews**: Full thread summary — capture conclusion + reasoning
- **Zero-discussion reviews**: Quick pass — scan title, diff summary, metadata for patterns
- **Categories**: Emerge organically from the data
- **Deduplication**: Consolidate recurring themes into patterns with frequency tags
- **Progress**: Update tracker after each batch (never lose work)
- **Review**: Autonomous extraction — user reviews learnings files periodically
- **Output locations**:
  - Project-specific: `<PROJECT_LEARNINGS_DIR>`
  - General engineering: `~/.claude/learnings/`
  - Private (useful across projects but too specific to share): `~/.claude/learnings-private/`

## Learnings Entry Format

```markdown
### Concise title

What the learning is, why it matters, and when it applies.

- **Source**: <REVIEW_UNIT> <REVIEW_PREFIX>number (+ any others where this recurred)
- **Frequency**: once | recurring | convention
- **Takeaway**: One-line actionable summary.
```

## Progress Tracker

| Batch | Reviews | Status | Notes |
|-------|---------|--------|-------|
<!-- Add rows as batches are processed -->
