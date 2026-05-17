---
description: "Promote per-agent learnings.md observations from a sweep run into the global learnings system. Bridges the gap between per-issue/per-PR learnings written by claude -p sessions and ~/.claude/learnings/."
---

# Compound Agent Learnings

Per-item `learnings.md` files in `tmp/claude-artifacts/sweep-*/` contain agent observations that otherwise never reach the global learnings system. This skill extracts, classifies, and promotes the generalizable ones.

## Usage

- `/sweep:compound-agent-learnings <RUN_DIR>` — process a single sweep run

## When to Run

- Director Phase 5 wrap-up, after all sessions reach terminal state
- Manually, to retroactively extract from prior run dirs

## Prerequisites

For prompt-free execution, ensure these allow patterns in `~/.claude/settings.json`:

```json
"Read(tmp/claude-artifacts/**)",
"Edit(~/.claude/learnings/**)",
"Write(~/.claude/learnings/**)"
```

## Steps

1. **Find files.** Glob `<RUN_DIR>/{issue,pr}-*/learnings.md`. None → exit "No agent learnings found."

2. **Extract observations** from each file's most recent dated section. Skip "Learnings loaded:" / "provenance" blocks. Capture "Observations:" / "New observations:" blocks only.

3. **Classify each:**
   - **Project-local:** references specific paths/functions/modules; already-fixed bugs (live in PR description)
   - **Generalizable:** pattern statements, language/framework gotchas, testing patterns, refactoring patterns

4. **Triage table:**

   | # | Source | Observation | Class | Target |
   |---|--------|-------------|-------|--------|
   | 1 | issue-97 | Found 2 doc hits beyond plan | Local | (skip) |
   | 2 | issue-98 | sleep patch moves with code | Global | refactoring-patterns.md |
   | 3 | issue-99 | conftest sys.modules pre-mock unblocks __init__.py singletons | Global | python-specific.md |

5. **Verify non-obvious claims before promoting.** Agent observations mix facts ("I couldn't run X") with theories ("X happens because Y"). Facts compound verbatim; theories need verification. If the suggested learning encodes a *theory* about platform/framework behavior — test it (run the command, read the source, check the file) before promoting. A plausible-but-wrong theory compounded becomes a load-bearing lie.

6. **Promote generalizables.** Write directly to the suggested file using the conciseness gate from `/learnings:compound` (lead with rule, one-to-two sentences, no hedging). Direct write is fine for already-classified items — invoking `/learnings:compound` adds overhead.

7. **Report:** what was promoted where, what was skipped, what was flagged for verification but couldn't be verified (left in tmp/).

## Important Notes

- Project-local observations stay in `tmp/` — already in the right place.
- Run BEFORE the operator-facing `/learnings:compound` so duplicates dedupe in that pass.
- Per-item `learnings.md` is append-only — one run after final convergence sees all dated sections.
- **Observation vs theory:** an agent saying "tests didn't run" is a fact; their explanation of *why* may be wrong. Promote the fact, verify the theory.

## Cross-Refs

- `~/.claude/commands/learnings/compound/SKILL.md` — operator-facing compound skill (complementary)
- `~/.claude/learnings/claude-code/sweep-sessions.md` — sweep session patterns
- `~/.claude/learnings/claude-code/multi-agent/director-work-items.md` — when to invoke from director Phase 5
