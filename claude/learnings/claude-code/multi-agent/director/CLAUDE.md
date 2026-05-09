Director-layer learnings split by concern. For active recipes (convergence rules, directive patterns, monitoring format), see `~/.claude/skill-references/director-playbook.md`.

| File | When to read |
|------|-------------|
| observability.md | Three-channel interface, state.md vs status.md, live.md, stream-json events, inactivity timeout |
| runner-design.md | Runner template, schema drift, model selection, terminal states, EXIT trap, stale branch, fill-template gaps, permissions |
| watermarks-and-skip.md | Single-pass sessions, post-action watermark, dual-signal, self-comment guard, pre-flight terminal-state-only |
| failure-modes.md | Rate-limit storm, rate-limit competition, TOCTOU, oscillation exception, deferred runs, discovery scope, CI-verification stall, permission-denial loop, single-session API-retry hang |
| process-and-meta.md | Director-as-supervisor, decision matrix is trust, computable state, orchestrate not replicate, directive timing, escalation composition |
