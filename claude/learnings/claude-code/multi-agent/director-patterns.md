Director-layer patterns for multi-agent workflows — run lifecycle, inter-run communication, state management across stateless workers.
- **Keywords:** director, manager, directives, watermark, rerun, append-only, sweep, run lifecycle, inter-run, stateless workers, claude -p
- **Related:** ~/.claude/learnings/claude-code/multi-agent/orchestration.md

---

## Hierarchy

Director (operator + main agent) → Manager (`claude -p` session per work item) → Sub-agents (reviewer personas, addressers, etc.). Directors set strategy and steer; managers orchestrate a single work item; sub-agents execute specific tasks. Communication flows down via prompt templates and directives; results flow up via artifacts.

## Watermark-Based Rerun

`claude -p` sessions are stateless — they see existing artifacts (result.md, status.md) and may interpret them as "already done" rather than "prior run output." To make sweep scripts genuinely rerunnable:

**Watermark in status.md**: store `last_reviewed_sha` and `last_comment_id` (or equivalent) after each run. On next launch, compare watermark against current PR state via `gh`. Skip only if both match.

**Append-only artifacts**: `result.md` and `learnings.md` get a new dated section per run (`## Review — <ISO timestamp>`) rather than being overwritten. Each section is self-contained with its own table. Gives an audit trail across runs without directory nesting.

## Directives Channel

A `directives.md` file (global at `RUN_DIR/` and per-work-item at `PR_DIR/`) that directors write between runs. The prompt template reads directives before the watermark check; directives override skip logic even when watermarks match.

Solves the "no way to pass instructions down to running managers" problem. Either director (operator or main agent) can write to it. Format is dated entries, append-only:

```markdown
## <ISO timestamp>

<context and instructions for the manager>
```

## Quick Rerun Without Regenerating

When only a subset of work items need updated prompts (e.g., to add the directives step), edit `pr-<N>/prompt.txt` in-place rather than re-running the sweep skill. Avoids creating a new run directory and preserves existing artifacts. Regeneration is better when the template changed substantially or all items need new prompts.

## Permissions for Sweep Sessions

`claude -p` sessions with `--allowedTools` need explicit `Read` patterns for the run directory (e.g., `Read(~/**/tmp/sweep-reviews/**)`). Without it, the session may not be able to read `status.md` watermarks, `directives.md`, or prior `result.md` sections. `Write` and `Edit` patterns for the same directory do not imply `Read` access. Add matching `Read` patterns to both the skill prerequisites and `settings.json`.

## Cross-Refs

- `~/.claude/learnings/claude-code/multi-agent/orchestration.md` — lower-level orchestration patterns (subagent synthesis, context compaction, runner templates)
