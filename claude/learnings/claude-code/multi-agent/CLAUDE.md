Multi-agent patterns for Claude Code — orchestration, coordination, quality, parallelization, and autonomous workflows.

| File | When to read |
|------|-------------|
| orchestration.md | Work distribution, synthesis, parallelization, context compaction |
| director-patterns.md | Director-layer: watermark rerun, directives channel, append-only artifacts, run lifecycle |
| director-work-items.md | Director patterns specific to `sweep:work-items` (lifecycle, per-role convergence, mixed-mode runs, stacked deps) |
| coordination.md | Worktree commit/merge, staging, sandbox workarounds, file coordination |
| quality.md | Verification, trust arc, agent-to-agent review, prompt design |
| parallel-plans.md | Parallel plan execution, DAG shape, speedup bounds |
| autonomous-patterns.md | General autonomous agent patterns: research methodology, validation, confidence |
| headless-nesting.md | Nested `claude -p` hierarchies: multi-tier spawning, `--allowedTools` propagation, prompt construction |
