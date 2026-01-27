# Assumptions & Questions Template

Template for the `assumptions-and-questions.md` file in Ralph loop projects.

## Standard Structure

Use this structure for most projects (fewer than 10 assumptions):

```markdown
# Assumptions & Questions: <Project Name>

## Assumptions

### A1: <Short Title>
**Assumption**: <What we're assuming to be true>
**Rationale**: <Why this assumption is reasonable>
**Confirmed/Trade-offs/Exception**: <Validation or caveats>

### A2: <Next Assumption>
...

## Questions & Answers

### Q1: <Question Title>
**Question**: <The question that arose>
**Answer**: <Resolution based on research>

### Q2: <Next Question>
...

## Open Items for Implementation

### O1: <Item Title>
**Item**: <What needs to be done>
**Approach**: <How to do it>
**Priority**: <Low/Medium/High - brief justification>
```

## Criticality-Based Structure

Use this structure for complex projects with many assumptions (10+):

```markdown
# Assumptions & Questions: <Project Name>

## Critical Assumptions (High Impact, Need Validation)

### A1: <Title>
**Assumption**: <What we're assuming>
**Why It Matters**: <Impact if wrong>
**Questions**: <Specific validation questions>
**Validation Needed**: <How to confirm>

## Moderate Assumptions (Medium Impact)

### A4: <Title>
**Assumption**: <What we're assuming>
**Why It Matters**: <Impact if wrong>
**Validation Needed**: <How to confirm>

## Working Assumptions (Lower Impact, Likely Valid)

### A8: <Title>
**Assumption**: <What we're assuming>
**Rationale**: <Why this is reasonable>
**Status**: ✅ Validated / 🔍 Needs verification

## Open Questions (Requiring Human Input)

### Q1: <Question Title>
**Question**: <The blocking question>
**Options**: <Multiple choice options if applicable>
**Impact**: <What decision this affects>

## Questions Answered During Research

### Resolved: <Question Title>
**Answer**: <Resolution found>
```

## When to Create Assumptions

Document assumptions when:
- Making design choices that could reasonably go another way
- Building on incomplete information
- Trade-offs between approaches need to be captured
- Future iterations need to understand "why" not just "what"

## When to Log Questions

Log questions when:
- Multiple valid interpretations exist
- Research revealed non-obvious answers
- The answer required investigation to find
- Other agents/humans might have the same question

## Priority Ranking

When a project has many open questions, add a priority ranking section:

```markdown
## Priority Ranking

### High Priority (Blocking Implementation)
1. **Q1**: Module organization
2. **Q2**: Data model design

### Medium Priority (Implementation Decisions)
4. **Q4**: Multi-ticker support

### Lower Priority (Can Defer)
7. **Q5**: External data availability
```

**Priority definitions:**
- **High/Blocking**: Cannot begin implementation without resolution
- **Medium**: Affects implementation approach but has reasonable defaults
- **Lower/Deferrable**: Nice to know but can be resolved during implementation

## Default Answers for Blocking Questions

For blocking questions, provide a "Default if no answer" section to enable autonomous progress:

```markdown
#### Q1: Data Storage Strategy (BLOCKING)
**Question**: Should we pre-compute all timeframes or aggregate on demand?

| Option | Pros | Cons |
|--------|------|------|
| Pre-compute | Fast access | Storage overhead |
| On-demand | Single source of truth | Compute cost |

**Context**: <Why this decision matters>

**Default if no answer**: Lean toward on-demand aggregation for simplicity.
```

**When to include defaults:**
- BLOCKING questions that would otherwise halt progress
- HIGH priority questions with a clear "safer" choice
- Technical decisions where one option is more reversible

**When NOT to include defaults:**
- Questions about user preferences (style, naming conventions)
- Scope decisions that affect cost/timeline
- Security-sensitive choices

## Which Structure to Use

| Condition | Use |
|-----------|-----|
| Fewer than 10 assumptions | Standard structure |
| Most assumptions validated during research | Standard structure |
| Many assumptions (10+) | Criticality-based structure |
| Mix of validated/unvalidated assumptions | Criticality-based structure |
| Multiple open questions needing user decisions | Criticality-based structure |
