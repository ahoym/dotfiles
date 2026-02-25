# Parallel Plan Execution Learnings

## DAG Shape Bounds Speedup

Parallel plan speedup is bounded by the **DAG shape** (critical path), not by tooling or agent speed. If actual wall-clock ≈ critical path time, the scheduler is already near-optimal — the speedup is a property of the work distribution, not a missed optimization.

**Improving speedup:**
- Split agents on the critical path so downstream agents start sooner
- Use soft dependencies to start agents before hard deps fully verify
- Design features with more independent pieces (wider DAG = more parallelism)
- Features with inherent layering (types → logic → UI) have natural parallelism ceilings

## Soft Deps for Type-Appending Agents

When Agent A **modifies** (appends to) an existing type file like `lib/types.ts`, downstream agents that import those types in **new files** they create should use `soft_depends_on`, not `depends_on`.

**Why soft works:** The file already exists on disk. Once A writes its additions, the updated types are immediately available for import. Soft dep means "start once A's files are written" — the downstream agent doesn't need to wait for A's full build-verify to pass.

**When hard is needed instead:** If the downstream agent also **modifies** the same file (file conflict), or if it needs verified behavior (not just type signatures) from A's output.

**Example:**
```
A modifies: lib/types.ts (appends AmmPoolInfo interface)
G creates:  app/components/pool-panel.tsx (imports AmmPoolInfo)
→ G soft_depends_on A ✓ (G creates a new file, only needs types on disk)

A modifies: lib/api.ts (extends txFailureResponse signature)
D creates:  app/api/create/route.ts (calls txFailureResponse)
→ D depends_on A ✓ (D needs the actual function to compile, hard is safer)
```


## Fast/Slow Track Plan Splitting

When a plan contains multiple independent suggestions of varying complexity, split them into separate tracks:

- **Fast track**: Ship obvious, low-risk changes immediately (documentation edits, trivial additions, mechanical refactors)
- **Slow track**: Open a separate plan for changes benefiting from discussion (new abstractions, API design, architectural choices)

**When to split:** Items are both independent of each other AND different in complexity/discussion-worthiness. Trivial wins ship faster instead of being blocked by unrelated design discussions.

## E2E Test Suites Are Ideal Fan-Out Candidates

Adding a test suite (Playwright, Cypress, etc.) with N independent spec files is the best-case parallelization scenario. The structure is always:

```
A (foundation: config + helpers) ··→ B (page1.spec)
                                 ··→ C (page2.spec)
                                 ··→ D (page3.spec)
                                 ··→ E (page4.spec)
```

**Why it works so well:**
- Each spec creates a **single new file** — zero file conflicts between agents
- Spec agents only import types/helpers from the foundation — **all deps are soft**
- No integration agent needed — specs are leaf nodes verified by `tsc` + test runner
- Orphaned agents (nothing depends on them) are acceptable because correctness is verified by running the actual test suite post-merge

**Speedup profile:** For N spec agents, speedup ≈ N × 0.6-0.8x (diminishing returns from concurrency contention). A 5-spec suite achieves ~2.5-3x real-world speedup.

**TDD approach:** E2e test agents should use `build-verify → "npx tsc --noEmit"` (or equivalent type-check), NOT TDD. E2e tests require a live running server and external services — they can't be RED/GREEN'd in isolation during agent execution. The actual e2e run is a post-merge verification step.

## Parallel `tsc` on Shared Working Tree Causes Cross-Agent Noise

When multiple agents run `npx tsc --noEmit` concurrently on the same working tree, each agent sees type errors from other agents' half-written files. Agent B reports "2 errors in transact.spec.ts" — those errors are from Agent C's in-progress work, not B's.

**Why it happens:** `tsc --noEmit` checks ALL `.ts` files in the project (per `tsconfig.json` includes). When agents write files incrementally (create file → edit → fix types), a parallel agent running tsc at that moment sees the incomplete file.

**Mitigations:**
- Agents should only check their own file's errors: `npx tsc --noEmit 2>&1 | grep <my-file>` — but this risks missing real errors in their own imports
- Use `isolation: "worktree"` so each agent has its own file tree — eliminates cross-contamination entirely
- Accept the noise: instruct agents to ignore errors in files outside their scope (what we did in the e2e plan)

**Best approach:** `isolation: "worktree"` eliminates this problem completely since each agent's tsc only sees its own files plus the base branch. When worktrees aren't feasible, add "ignore type errors from files outside your scope" to the prompt preamble.

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

## Pre-Register Edit/Write for Skill File Editing

Before launching parallel agents that edit SKILL.md files under `~/.claude/commands/`, ensure these permissions exist in `settings.json`:

```
Edit(~/.claude/commands/**)
Write(~/.claude/commands/**)
```

Without these, background agents silently fail — they can Read but not Edit/Write. The default settings only include `Read(~/.claude/commands/**)`. Also add `Edit(~/.claude/settings.local.json)` if any agent modifies the settings file.

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
