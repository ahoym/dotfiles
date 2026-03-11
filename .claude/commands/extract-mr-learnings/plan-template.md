# PR Learnings Extraction Plan

## Objective

Systematically extract learnings from all <PR_COUNT> PRs in the <REPO_NAME> GitHub repo.

## Decisions

- **Order**: Oldest-first (resilient to new PRs being pushed during extraction)
- **Scope**: All PR states (open, merged, closed)
- **Batch size**: 5 PRs per batch
- **Discussion PRs**: Full thread summary — capture conclusion + reasoning
- **Zero-discussion PRs**: Quick pass — scan title, diff summary, metadata for patterns
- **Categories**: Emerge organically from the data
- **Deduplication**: Consolidate recurring themes into patterns with frequency tags
- **Progress**: Update tracker after each batch (never lose work)
- **Review**: Autonomous extraction — user reviews learnings files periodically
- **Output locations**:
  - Project-specific: `<PROJECT_LEARNINGS_DIR>`
  - General engineering: `~/.claude/learnings/`

## Learnings Entry Format

```markdown
### Concise title

What the learning is, why it matters, and when it applies.

- **Source**: PR #number (+ any others where this recurred)
- **Frequency**: once | recurring | convention
- **Takeaway**: One-line actionable summary.
```

## Progress Tracker

| Batch | PRs | Status | Notes |
|-------|-----|--------|-------|

<!-- Add rows as batches are processed -->
