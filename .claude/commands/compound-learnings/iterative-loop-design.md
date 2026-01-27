# Iterative Loop Design

Patterns for creating skills that use iterative AI loops (Ralph loops, research loops, etc.).

## The Problem with Fixed Task Lists

A static list of 4 tasks with "ONE TASK PER ITERATION" means 4 iterations = done. The loop terminates before deeper investigation.

Design for extended autonomous operation rather than quick completion.

## Expansion/Contraction Pattern

Design loops to follow a natural cycle:

1. **Expansion Phase**: Initial tasks generate "areas for deeper investigation" → agents add follow-up tasks → task list grows
2. **Contraction Phase**: Follow-up tasks complete → questions accumulate → task list shrinks
3. **Termination**: Only when genuinely blocked on user input

## Key Template Elements

### 1. Dynamic Task Generation Instructions

```markdown
## Dynamic Task Generation

After completing research tasks, review findings for gaps.

**Add new tasks to Pending Tasks** when you identify:
- Topics in "Areas for Deeper Investigation" sections
- Assumptions needing validation
- Questions answerable with more research

Format:
- [ ] Deep Research: <topic> - <description>
```

### 2. Required "Questions for User" Section

```markdown
## Questions Requiring User Input
<!--
REQUIRED before completion. Add genuine blocking questions:
- What decisions require human judgment?
- What information only the user can provide?

If empty, you haven't gone deep enough. Add more research tasks.
-->
```

### 3. Stricter Completion Criteria

```markdown
## Completion

**Do NOT add completion signal until ALL true:**

1. All tasks complete (including dynamically added ones)
2. "Questions Requiring User Input" has genuine blocking questions
3. You cannot proceed further without user input

**If no blocking questions**: Review research, add more deep research tasks, continue.
```

## Why This Matters

Without these patterns, loops complete in predictable iterations (typically 4) regardless of research depth. With them, loops maximize autonomous progress before requiring human intervention.

## Reference Implementation

See `.claude/commands/init-ralph-research/` for templates implementing this pattern.

## Testing Long-Running Scripts

### Add Timeout Parameters

For scripts that run continuously (monitors, watchers, polling loops), add an optional timeout parameter that auto-exits after a specified duration. This enables automated testing without requiring external process management.

```bash
# Example: Optional timeout in minutes (0 = run indefinitely)
TIMEOUT_MINUTES="${4:-0}"
START_TIME=$(date +%s)

while true; do
    if [ "$TIMEOUT_MINUTES" -gt 0 ]; then
        ELAPSED=$(( $(date +%s) - START_TIME ))
        if [ "$ELAPSED" -ge $(( TIMEOUT_MINUTES * 60 )) ]; then
            echo "Stopped after $TIMEOUT_MINUTES minute(s)"
            exit 0
        fi
    fi
    # ... rest of loop
done
```

## Related References

- @skill-template.md - Template and file organization for skills
- @writing-best-practices.md - General skill writing conventions
