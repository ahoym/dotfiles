Multi-agent patterns for Claude Code — orchestration, coordination, quality, parallelization, and autonomous workflows.

| File | When to read |
|------|-------------|
| orchestration.md | Work distribution, synthesis, parallelization, context compaction |
| director/CLAUDE.md | Director-layer sub-cluster: observability, runner-design, watermarks-and-skip, failure-modes, process-and-meta (5 focused files; split from former director-patterns.md) |
| director-work-items.md | Director patterns specific to `sweep:work-items` (lifecycle, per-role convergence, mixed-mode runs, stacked deps) |
| coordination.md | Worktree commit/merge, staging, sandbox workarounds, file coordination |
| quality.md | Verification, trust arc, agent-to-agent review, prompt design |
| parallel-plans.md | Parallel plan execution, DAG shape, speedup bounds |
| autonomous-patterns.md | General autonomous agent patterns: research methodology, validation, confidence |
| headless-nesting.md | Nested `claude -p` hierarchies: multi-tier spawning, `--allowedTools` propagation, prompt construction |
| vp-tier-orchestration.md | VP-tier: multi-repo Director coordination, event-driven monitoring, `--max-turns`, concurrency, session resumption |
| background-agent-capabilities.md | bg Agent vs claude -p: capability matrix, context costs, cross-repo blockers, decision framework |
