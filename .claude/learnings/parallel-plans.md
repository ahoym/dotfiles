# Parallel Plan Execution Learnings

## DAG Shape Bounds Speedup

Parallel plan speedup is bounded by the **DAG shape** (critical path), not by tooling or agent speed. Before optimizing agent prompts or model selection, analyze the critical path to know the ceiling.

**Example from credential management (4 agents):**
```
A (242s) ──→ B (77s)     ← off critical path (leaf)
A (242s) ──┐
            ├──→ D (117s) ← critical path: A→D = 359s
C (235s) ──┘
```
- Critical path: 359s, actual: ~370s (near-optimal)
- Sum of parts: 671s → speedup: 1.8x
- The 1.8x is a property of the work distribution, not a missed optimization

**Improving speedup:**
- Split agents on the critical path so downstream agents start sooner
- Use soft dependencies to start agents before hard deps fully verify
- Design features with more independent pieces (wider DAG = more parallelism)
- Features with inherent layering (types → logic → UI) have natural parallelism ceilings

## Fast/Slow Track Plan Splitting

When a plan contains multiple independent suggestions of varying complexity, split them into separate tracks:

- **Fast track**: Ship obvious, low-risk changes immediately (documentation edits, trivial additions, mechanical refactors)
- **Slow track**: Open a separate plan for changes benefiting from discussion (new abstractions, API design, architectural choices)

**When to split:** Items are both independent of each other AND different in complexity/discussion-worthiness. Trivial wins ship faster instead of being blocked by unrelated design discussions.

## Progress Checklist for Refactoring Batches

Add a markdown checkbox progress checklist to refactoring plans, grouped by batch with a build/test gate after each:

```markdown
### Batch 1 — Tests
- [ ] **1A** Description
- [ ] **1B** Description
- [ ] Batch 1 gate: `pnpm build && pnpm test` passes
```

**Benefits:** Subagents can work on independent items concurrently. If execution stops mid-way, find first unchecked item and resume. Clear progress tracking across sessions.

## Permissions Are Cached at Session Start

Changes to `settings.json` or `settings.local.json` mid-session are **not picked up** by background agents or the current session. This applies to both project-level (`settings.json`) and local (`settings.local.json`) settings files.

**Impact:** If you add `Edit(~/.claude/commands/**)` mid-session and then launch background agents, they silently fail on Edit with "Permission denied." No error propagates to the coordinator — the agent just reports it couldn't edit.

**Fix:** Add all required permissions **before** starting the session. If you discover missing permissions mid-execution, add them and restart the session. The `/parallel-plan:execute` state file (`.parallel-plan-state.json`) enables seamless resumption after restart.

## Worktree Isolation Creates Permission Mismatches

Edit/Write permission patterns like `Edit(~/.claude/commands/**)` resolve to absolute paths (e.g., `/Users/me/.claude/commands/`). Agents in worktrees edit files at `<worktree>/commands/...` — a different path that doesn't match the permission pattern. Result: silent Edit failures.

**When to skip worktrees:** For tasks where agents have disjoint file scopes (no conflict risk) and no build/test isolation is needed. Especially mechanical edits (YAML, markdown). The Branch Strategy overhead (worktrees, cherry-picks, per-agent PRs) isn't justified when agents can't conflict.

**When worktrees are still needed:** Code tasks with `tsc --noEmit` or build steps where parallel agents would see each other's half-written files.

## Model Selection for Mechanical Edits

haiku handles multi-file mechanical edits well when instructions are explicit (exact field values, clear tables):
- 5 files with mixed frontmatter additions: 27s, 16 tool uses
- 4 files with mixed frontmatter additions: 22s, 12 tool uses

Use haiku for pattern-following edits across many files. Use sonnet when the agent needs judgment (e.g., description quality review, diverse context injection templates).

## Adapting Parallel Plans for Non-Code Tasks

The parallel-plan format (designed for code with TDD) adapts to mechanical editing tasks (YAML frontmatter, markdown sections):

- **Shared Contract** → frontmatter field ordering conventions instead of type definitions
- **TDD steps** → `build-verify → "re-read all files"` instead of test suites
- **Integration tests** → structural checks (field ordering, count verification) instead of cross-module data flow
- **Pre-execution verification** → "no commands needed" (all tools are built-in)
- **Required Bash Permissions** → often none (Read/Edit/Glob/Write only)
