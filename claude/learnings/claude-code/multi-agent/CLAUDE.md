Multi-agent patterns for Claude Code — orchestration, coordination, quality, parallelization, and autonomous workflows.

| File | When to read |
|------|-------------|
| orchestration.md | Work distribution, synthesis, parallelization, context compaction |
| director/CLAUDE.md | Director-layer sub-cluster: observability, runner-design, watermarks-and-skip, failure-modes, process-and-meta (5 focused files; split from former director-patterns.md) |
| coordination.md | Worktree commit/merge, staging, sandbox workarounds, file coordination |
| quality.md | Verification, trust arc, agent-to-agent review, prompt design |
| parallel-plans.md | Parallel plan execution, DAG shape, speedup bounds |
| autonomous-patterns.md | General autonomous agent patterns: research methodology, validation, confidence |
| headless-nesting.md | Nested `claude -p` hierarchies: multi-tier spawning, `--allowedTools` propagation, prompt construction |
