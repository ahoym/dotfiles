# Convergence Loop Mode

Read this when the operator requests "run to convergence," "converge," or "go until convergence." This mode auto-chains review→address→re-review cycles without returning to the operator between steps.

## When to enter

- Operator explicitly requests convergence (e.g., "converge on 87 and 88")
- Operator says "run to convergence please" or similar

## Loop

```
1. Launch review runner (background)
2. On completion: read all status.md + results.md
3. Decision gate (per decision matrix):
   a. Any PR has mergeable: CONFLICTING → write directive to addresser, include in address run
   b. Any PR has new findings (inline comments > 0) → proceed to step 4
   c. Any PR has new operator/addresser comments needing reviewer reply → proceed to step 4 (reviewer handles replies)
   d. All PRs: 0 new findings AND no unprocessed comments → CONVERGED, go to step 7
4. Launch address runner (background)
5. On completion: read all status.md + results.md
6. Go to step 1 (re-review to verify address work)
7. Report final state to operator
```

## Rules

- **No intermediate check-ins.** Don't report between cycles unless escalation is needed. The operator asked for convergence — deliver the result, not play-by-play.
- **Decision matrix applies at every step.** Conflicts, persona propagation, relaunch decisions are all routine — auto-decide per the matrix.
- **Read worker learnings after each cycle.** Check `learnings.md` for signal that could influence the next cycle (e.g., new permission gaps, empirical findings).
- **Escalate on:** rate limits, errored sessions after retry, scope-expanding findings. These break the loop and surface to the operator.
- **Maximum cycles:** 5 review→address round-trips. If not converged after 5, report the state and ask the operator. This prevents infinite loops from oscillating findings.

## Convergence criteria

A PR is converged when the re-review cycle produces:
- 0 new findings
- 0 new inline comments
- All prior findings resolved (🚀 reactions) or closed (valid pushback)
- No unprocessed operator comments

All PRs converged → loop exits.

## Output

On convergence, present a single summary:

```
Converged after N cycles.

| PR | Cycles | Findings (total) | Resolved | Commits | Status |
|----|--------|-------------------|----------|---------|--------|
| #87 | 3 | 4 | 4 | 2 | CLEAN, ready for merge |
| #88 | 2 | 3 | 3 | 1 | CLEAN, ready for merge |
```
