# Automation Patterns

## Separate Init, Run, and Cleanup

For automated loops (like ralph), split responsibilities across independent tools rather than bundling everything into one script:

- **Init** (skill/command) — scaffold files, create isolated environment (e.g., worktree), output run instructions
- **Run** (script) — just the loop logic + ephemeral guards (hooks injected at start, removed on exit via trap)
- **Cleanup** (skill/command) — prune stale environments, check if work was merged

**Why:** Each piece can evolve independently. The user stays in control of the git workflow (commit, push) between run and cleanup. No fragile multi-step git gymnastics in the loop script.
