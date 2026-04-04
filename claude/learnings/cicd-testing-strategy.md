CI/CD patterns: test gating, iterative pipeline validation, and the relationship between CI coverage and bug discovery.
- **Keywords:** CI pipeline, test gating, selective tests, latent bugs, iterative validation, test commits, GitLab CI
- **Related:** ~/.claude/learnings/cicd/gitlab.md

---

### Removing selective test gating surfaces latent bugs

When `changes`-based CI filtering was removed and all tests began running on every MR, pre-existing bugs were immediately exposed -- specifically a routing key case mismatch that had been hidden because the affected tests only ran when their module's files changed. This required multiple follow-up commits within the same MR to fix the surfaced failures. Selective test gating trades CI speed for hidden regressions — when removing gating, budget time for fixing the bugs it surfaces.

### Iterative CI validation via test commits on MR branches

When CI changes can't be tested locally, push intermediate commits to validate the fix via MR pipelines. In one case, the author pushed 4 intermediate commits before the final one. CI config changes are tested in CI — multiple intermediate commits on an MR branch is the expected workflow, not a sign of sloppiness.

## Cross-Refs

- `~/.claude/learnings/cicd/gitlab.md` -- GitLab CI/CD patterns and debugging
