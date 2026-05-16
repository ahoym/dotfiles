Empirical comparison of background Agent subagents vs claude -p sessions for sweep orchestration. Tested 2026-04-14 from a multi-module Java/Spring repo.

**Keywords:** background agent, claude -p, director, sweep, permissions, context window, skill invocation, cross-repo
**Related:** none

---

## Capability Matrix

| Capability | Agent(run_in_background) | claude -p | Notes |
|---|---|---|---|
| Invoke Skill tool | ⚠️ Non-deterministic — permission prompt fires async, approval depends on user timing | ✅ Reliable | Skill loads SKILL.md + refs as system-reminder when it works |
| `!` preprocessor in skills | ❓ Untestable — blocked when Skill is denied | ✅ Yes | Can't reach `!` commands without Skill access |
| cd to different CWD | ⚠️ `cd && glab` ✅, `cd && git` ❌ | ✅ Native (launched from target dir) | Permission patterns are command-specific after `cd` |
| CWD persistence | ❌ Resets every Bash call | ✅ Persistent | Known platform constraint |
| glab/gh CLI | ✅ auth, mr list, mr view | ✅ Yes | No issues either way |
| Read permissions | ✅ settings.json, CLAUDE.md, learnings | ✅ Yes | Full inheritance |
| Write permissions | ✅ tmp/claude-artifacts/ | ✅ Yes | No issues |
| Notifications | ✅ Per-agent, async delivery | ❌ Fire-and-forget | bg agents are strictly better |
| CLAUDE.md inheritance | ✅ Full + @-refs | ✅ From launch CWD | Both work |
| Learnings file access | ✅ Readable | ✅ Readable | Neither reliably triggers search gates without explicit prompt steps |
| Cross-repo git ops | ❌ Permission denied | ✅ Native | Hard blocker for multi-repo sweeps |
| env inspection | ❌ `env \| grep` denied | ✅ Yes | Minor — permission pattern gap |

## Context Window Costs (Same 3-Operation Task)

| Metric | Agent(run_in_background) | claude -p |
|---|---|---|
| Reported total tokens | 16,839 (opaque) | 73,458 (input + cache_create + cache_read) |
| Effective context load | ~16-25k (estimated) | ~24,855 (12,623 cache_create + 12,232 initial cache_read) |
| System prompt tax | ~12k | ~12k |
| Output tokens | ~555 | 555 |
| Duration | 13.0s | 12.4s |
| Cost | Not reported in notification | $0.123 |

bg agent notification reports a single opaque `total_tokens` — no cache breakdown. claude -p stream-json gives full granularity (input, cache_creation, cache_read, output per turn).

Both pay ~12k tokens of CLAUDE.md + system prompt per session. For N workers, that's ~12k × N fixed overhead regardless of strategy. Cache is NOT shared between parallel bg agents or parallel claude -p sessions.

## Decision Framework

**Use bg agents when:** Single-repo operations, need structured notifications, parallelizing subtasks within a Director session, no Skill invocation required.

**Use claude -p when:** Cross-repo git operations needed, reliable Skill invocation required, multi-repo sweeps, CWD must be the target repo.

**Hybrid (recommended for sweeps):** claude -p Director launched from target repo for orchestration + Skill invocation. bg agents for parallel same-repo subtasks where the Director has set up context. The Director creates artifacts, bg agents execute within the repo.

## Never Block on TaskOutput After a Background-Agent Launch

Don't call `TaskOutput` with `block: true` after launching a background agent. The system delivers a `<task-notification>` automatically on completion — blocking the foreground defeats the entire purpose of background execution. Continue with parallel work or respond to the operator; the notification fires when ready.

## Cross-Refs

- `autonomous-patterns.md` § "Skill Invocation in Autonomous Agents" — claude -p Skill validation
- `../platform-worktrees-and-isolation.md` § "Background Agents Need Project-Level Permission Patterns"
- `../sweep-sessions.md` § "Reviewer Prompt Gap" — claude -p skill bypass patterns
- `parallel-plans.md` § "Background Agent CLI Permission Gotcha" — quoted string permission issue
