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
