# Analysis Guide: Identifying Parallelism in Plans

## File-Conflict Matrix

For each step in the plan, list every file it touches — **including test files**. Then build a matrix:

```
                   step1  step2  step3  step4  step5
src/file-a           M                    M
src/file-b                  C
test/file-a.test     C                    M
test/file-b.test            C
test/helpers         M             M             M
src/file-c                         M             M
```

Legend: M = modify, C = create, D = delete

**Conflict rules:**
- Two M's in the same row = conflict (can't run in parallel)
- C + C in the same row = conflict (same new file)
- M + C or M + D = conflict
- C in one row, M in another row = no conflict (different files)
- A step that only creates NEW files never conflicts with steps that only modify EXISTING files

**Test file ownership:** Each agent owns its test files alongside its source files. When building the matrix, include the test files the agent will create or modify. Shared test infrastructure (e.g., `conftest.py`, shared fixtures) should be consolidated into an early agent, just like shared utility files.

## Dependency Types

### Hard dependencies (`depends_on`)
Agent B needs Agent A's work to be **fully completed and verified** before starting. Use when:
- Agent B imports and calls functions that Agent A implements (not just type signatures)
- Agent B modifies files that Agent A also modifies (sequential access)
- Agent B needs Agent A's tests to pass to validate its own assumptions

### Soft dependencies (`soft_depends_on`)
Agent B only needs Agent A's **interface contract** (types, signatures, file structure) — not the full implementation. Use when:
- Agent B imports types/interfaces that Agent A creates (just needs the file to exist)
- Agent B implements against a protocol/interface that Agent A defines
- Agent B creates a component that accepts props defined by Agent A's types

The executor can start soft-dependent agents as soon as the dependency's files are written to disk, without waiting for full verification. This reduces wall-clock time on deep DAGs.

```
# Hard: B waits for A to fully complete
A (60s, verified) ──→ B (50s) → total: 110s

# Soft: B starts as soon as A's files exist (~30s into A's run)
A (60s) ──soft──→ B (50s, starts at ~30s) → total: ~80s
```

### Integration dependencies
A "wiring" agent that connects outputs from multiple agents (e.g., passing props from parent to children modified by separate agents). Integration agents almost always use hard dependencies.

### Interface-first pattern

When the plan introduces shared types or test fixtures that multiple agents depend on, create a small, fast **Agent A** dedicated solely to defining these. This agent:
- Creates type/interface definition files and shared test helpers
- Has no dependencies itself
- Completes quickly (< 60s), unblocking the rest of the DAG
- All other agents soft-depend on it (they just need the types to exist)

```
A (types, 30s) ──soft──┬──→ B (implementation)
                       ├──→ C (implementation)
                       └──→ D (implementation) ──hard──→ E (integration)
```

This is the highest-impact parallelism pattern — one fast agent unblocks many concurrent agents.

## DAG Design

### Think in swim lanes, not phases

Instead of grouping agents into sequential phases, define a dependency DAG where each agent lists its specific predecessors. This allows agents to start as soon as their individual dependencies complete, rather than waiting for an entire phase.

**Batch phases (suboptimal):**
```
Phase 1: [A(60s), C(80s)]  → wait for both → 80s
Phase 2: [B(50s)]           → B depends only on A, but waits for C too → 130s
Phase 3: [D(30s)]           → 160s total
```

**Swim lanes (optimal):**
```
A(60s) ──→ B(50s) ──→ D(30s)
C(80s) ───────────────→↑

A done at 60s → B starts immediately (doesn't wait for C)
B done at 110s, C done at 80s → D starts at 110s
Total: 140s (saved 20s)
```

### Common DAG Patterns

**Pattern 1: Fan-out / Fan-in**
Most common. Independent work fans out, then an integration agent fans in.
```
A ──┐
B ──┼──→ E (integration)
C ──┤
D ──┘
```

**Pattern 2: Pipeline with parallel branches**
A foundation agent, then parallel work, then integration.
```
A (setup) ──→ B ──┐
         └──→ C ──┼──→ E (integration)
              D ──┘
```
Here B depends on A, but C and D are independent. D can start immediately.

**Pattern 3: Diamond**
Two parallel streams that converge.
```
A ──→ B ──┐
C ──→ D ──┼──→ E
```

## Soft Dependency Audit

After building the initial DAG, perform a systematic audit of every `depends_on` (hard) dependency. Hard dependencies are the primary bottleneck for parallelism — every hard dep that could be soft represents wasted wall-clock time.

**For each hard dependency A → B, ask:**

1. **Does B import types/interfaces from A?** → Soft. B only needs the file to exist with the right exports.
2. **Does B call functions that A implements?** → Hard. B needs the function to actually work.
3. **Does B modify files that A also modifies?** → Hard (sequential file access).
4. **Does B need A's tests to pass?** → Hard. B's correctness depends on A's verified behavior.
5. **Does B consume A's output at runtime** (e.g., reads a file A generates, imports a module A creates)? → Depends: if B only needs the file structure/shape, soft. If B needs correct runtime behavior, hard.

**Common upgrades (hard → soft):**
- Agent creates types → downstream agents import those types (soft — just needs file on disk)
- Agent creates a new module → downstream agent imports from it but only uses type information (soft)
- Agent adds constants/config → downstream agent references them (soft — values just need to exist)

**Must stay hard:**
- Agent implements business logic → downstream agent's tests exercise that logic
- Agent modifies a file → another agent also needs to modify the same file (should be same agent)
- Agent creates test fixtures → downstream agent runs tests that use those fixtures with real assertions

**Checklist format for the plan:**
```
Soft dependency audit:
- B depends_on A: B imports types from A → DOWNGRADE to soft_depends_on ✓
- D depends_on B: D calls fetchOrderbook() from B → KEEP as depends_on ✓
- E depends_on A: E imports constants from A → DOWNGRADE to soft_depends_on ✓
```

Include this audit in your analysis (internal working, not in the output plan) to demonstrate that every hard dependency was intentionally chosen.

**Aggressive soft dependency opportunities to look for:**
- **UI components that import types from a lib agent** — the UI only needs the type file to exist, not the implementation behind it. Downgrade to soft.
- **Adapter/provider layers that import param types** — the wallet adapter only needs the interface definitions, not the API route implementations. Downgrade to soft.
- **Integration agents that consume hooks** — if the hook file just needs to exist (correct exports), the integration agent can start before the hook's tests pass. Downgrade to soft.
- **Any agent that only reads from an upstream agent's `creates` list** — if it doesn't call functions or run logic from those files, it's soft.

The soft dependency audit is the single highest-impact step for reducing wall-clock time. Every hard→soft downgrade potentially shaves seconds off the critical path.

## DAG Visualization Verification

After drawing the DAG visualization, perform a cross-check:

1. **Forward check**: For each arrow in the visualization, verify there's a corresponding `depends_on` or `soft_depends_on` in the agent definition.
2. **Reverse check**: For each `depends_on` and `soft_depends_on` declaration, verify there's an arrow in the visualization.
3. **Arrow style**: Use `──→` for hard dependencies and `··→` for soft dependencies to make the distinction visible.

Example:
```
A ──┐
    ├··→ C ──→ D
A ··→ B      ↗
    E ──────┘
```

This means: C soft-depends on A, D hard-depends on C, B soft-depends on A, D hard-depends on E.

Mismatches between visualization and declarations are a common source of confusion.

## Splitting Large Agents

If one agent dominates the critical path, consider splitting it:

**Before:** Agent D touches 5 files, estimated ~140s
**After:** Agent D1 (3 new files, ~60s) + Agent D2 (2 modifications, ~80s)

**Split criteria:**
- The agent creates new files AND modifies existing files → split into "create" and "modify" agents
- The agent modifies files that have no dependency between them → split by file
- The agent has a clear sequential sub-structure → split at the natural boundary

**Don't split when:**
- The files within the agent reference each other (one imports from another being created)
- The overhead of two agents exceeds the time saved
- The agent is already < 60s estimated

## Estimating Agent Time

Based on observed patterns. TDD adds ~40-60% overhead per agent due to writing tests first, verifying RED/GREEN phases, and running test commands.

| Task type | Expected time | Expected tool uses |
|-----------|---------------|-------------------|
| Single file, small edit + test | 40-55s | 6-10 |
| Single file, complex edit + test | 70-100s | 14-20 |
| Create 1 new file + test (< 100 lines) | 40-65s | 6-10 |
| Create 1 new file + test (> 200 lines) | 90-140s | 14-20 |
| Create 2-3 new files + tests + modify 1-2 | 150-220s | 25-38 |
| Integration (wire + integration tests) | 120-160s | 22-32 |

Each agent must include an `estimated_duration` field using these ranges.

### Critical Path Estimation

After assigning durations to each agent, compute the critical path — the longest path through the DAG in wall-clock time.

**How to compute:**
1. For each agent with no dependencies, its start time is 0.
2. For each agent with dependencies, its start time = max(end time of all hard deps). For soft deps, start time = max(30% of soft dep's duration) — soft deps let you start early.
3. End time = start time + estimated_duration.
4. Critical path = the path from start to the agent with the latest end time.

**Example:**
```
A (30s, start=0, end=30)
B (100s, soft_dep=A, start=9, end=109)   ← starts at 30% of A
C (80s, soft_dep=A, start=9, end=89)
D (60s, hard_dep=B, start=109, end=169)  ← waits for B to fully complete
E (120s, hard_dep=[C,D], start=169, end=289)

Critical path: A → B → D → E = 289s
Sequential total: 390s
Speedup: 1.35x
```

Include a **Critical Path Estimate** section in the plan output with a table showing:
- Each path through the DAG
- The agents on that path
- Estimated wall-clock time
- Total sequential estimate vs parallel estimate
- Speedup ratio

This helps reviewers evaluate whether the parallelization is worth the complexity.

### Wall-Clock Reality

Subagents run with partial concurrency, not true parallelism. Observed behavior:
- **2 concurrent agents**: wall-clock ≈ 0.7-0.8x sum of individual times
- **3 concurrent agents**: wall-clock ≈ 0.6-0.8x sum of individual times
- **Speedup is real but modest** — expect 1.5-2x for 3 agents, not 3x

Factor this into critical path estimates. The value of parallelization comes from:
1. Speedup (even if modest)
2. Contract enforcement (agents can't accidentally couple)
3. Reduced context window pressure (each agent has focused context)

## Common Pitfalls

1. **Forgetting the integration agent**: Component agents add new props, but someone must pass them from the parent. Always plan for this.

2. **Implicit file dependencies**: Agent A modifies `types.ts` and Agent B also needs to modify `types.ts` for a different type → conflict. Solution: assign all `types.ts` changes to a single early agent.

3. **Import chain dependencies**: Agent A creates `utils/foo.ts`, Agent B modifies `component.tsx` to import from `utils/foo.ts`. These don't conflict on files, but B depends on A (the import target must exist). Mark this as a dependency.

4. **Shared utility files**: Files like `types.ts`, `constants.ts`, `index.ts` are often touched by multiple steps. Consolidate all changes to these files into a single agent.

5. **Over-splitting**: Creating 6 agents for 200 lines of total code. Agent overhead (prompt processing, file reads) means tiny agents can be slower than merging them. Minimum viable agent: ~30 lines of meaningful changes.

6. **Shared test infrastructure**: Files like test helpers, shared fixtures, or test utilities (e.g., `conftest.py`, `test-utils.ts`, `testhelpers_test.go`) are often needed by multiple agents. Consolidate all changes to shared test files into an early agent (just like shared utility files). Each agent should own its own test files but depend on the agent that sets up shared fixtures.

7. **TDD overhead in splitting decisions**: With TDD, each agent has more tool uses (write test → run test → write code → run test → refactor → run test). Factor this into the minimum viable agent size — an agent with a single 5-line edit now involves ~6-10 tool uses with TDD, so the merge threshold is higher.

## TDD Escape Hatch: build-verify

Not every change is practically unit-testable. Some code changes are better verified by a type-check/build step than by a unit test. The `build-verify` entry type in `tdd_steps` exists for these cases.

### When to use build-verify

- **API route handlers** that need a running server and real HTTP context to test meaningfully — these are better covered by integration tests after all agents complete
- **UI prop-threading** (passing a prop from parent to child without logic) — type-checking catches mismatches; a unit test would just assert "prop was passed" which adds no value
- **Pure wiring code** that connects two existing, tested modules — the individual modules have tests; the wiring is verified by build + integration tests
- **Config/constant additions** where the value is self-evident (e.g., adding a regex constant) — though the constant itself may still warrant a unit test for correctness

### When NOT to use build-verify

- **Any function with logic** (conditionals, loops, transformations) — these MUST have unit tests
- **New utility functions** — always test
- **Data processing/filtering** — always test
- **Anything where "it compiles" doesn't mean "it works correctly"**

### Justification requirement

Every `build-verify` entry MUST include a parenthetical explaining why TDD is impractical:

```
tdd_steps:
    1. "Add hybrid flag to FLAG_MAP" → `lib/xrpl/offers.test.ts::includes hybrid in VALID_OFFER_FLAGS`
    2. build-verify → "pnpm build" (API route handler — tested via integration)
    3. "Filter trades by domain" → `lib/xrpl/__tests__/trades-fetch.test.ts::filters by DomainID`
```

Without the justification, the plan reviewer can't distinguish intentional TDD skips from laziness.

## Integration Test Specificity

The Integration Tests section must describe 2-3 **specific cross-cutting scenarios**, not just generic commands. Each scenario should:

1. **Name the data flow being tested** — which agent's output feeds into which other agent's input
2. **Describe the concrete interaction** — what data crosses the boundary and what should happen
3. **Be verifiable** — describe how to check that the integration works

### Good examples

```
## Integration Tests

1. **Domain ID flows from hook → API → orderbook**: Set `activeDomainID` in `useTradingData` →
   verify `useFetchMarketData` includes `?domain=` in API URL → verify API route calls
   `fetchPermissionedOrderbook()` instead of `fetchAndNormalizeOrderbook()`

2. **Hybrid flag round-trips through wallet adapter**: Call `adapterCreateOffer()` with
   `flags: ["hybrid"]` and `domainID` set → verify `buildOfferCreateTx()` sets both
   `tx.DomainID` and `tfHybrid` flag on the transaction

3. **Account offers include domain metadata**: Fetch offers for an account that has
   domain offers → verify the response includes `domainID` field → verify the orders
   table renders the domain column
```

### Bad examples (too generic)

```
## Integration Tests

Run `pnpm test` to verify all tests pass.
Run `pnpm build` to verify no type errors.
```

These belong in the Verification section, not Integration Tests. Integration Tests must describe cross-agent boundary scenarios.

## Prompt Preamble Pattern

The executor prepends **Shared Contract + Prompt Preamble** to every agent's prompt. This means:
- The Shared Contract section (types, API contracts, import paths) is automatically included — agents always see it
- The Prompt Preamble contains only **process instructions** that apply to all agents

This separation avoids markdown code-fence nesting issues (no TypeScript blocks inside code-fenced preambles) and keeps the shared contract as a single source of truth.

### Benefits

- **Reduces plan size** — common boilerplate appears once instead of N times
- **Ensures consistency** — all agents get identical shared instructions
- **Single source of truth** — the shared contract lives in one place, not duplicated in preamble + agent prompts
- **No markdown nesting** — the preamble contains only prose and lists, no code blocks that could conflict with the plan's own fencing

### What belongs in the preamble

- TDD workflow template (RED → GREEN → REFACTOR cycle description)
- Test/build/lint commands for the project
- Completion Report format
- Common "DO NOT" rules that apply to all agents (e.g., "DO NOT modify files outside your listed scope")

### What does NOT belong in the preamble

- **Shared Contract content** — this is prepended separately by the executor from the Shared Contract section
- **Agent-specific instructions** — these go in each agent's `prompt` field

### What stays in agent-specific prompts

- File scope (creates/modifies/deletes with context)
- Agent-specific TDD steps
- Code landmarks for edits (function names, line numbers, surrounding context)
- Agent-specific "DO NOT modify X" boundaries (files owned by other agents)
- Agent-specific implementation details

### Example structure

```markdown
## Shared Contract
[types, interfaces, import paths — the executor includes this automatically]

## Prompt Preamble

You are implementing part of a parallel plan. Follow these rules:

### Project Commands
- Test: `pnpm test`
- Build: `pnpm build`

### TDD Workflow
For each change, follow RED → GREEN → REFACTOR:
[standard TDD instructions]

### Completion Report
When done, end your output with:
[standard report format]
```

Then each agent's prompt becomes focused:

```markdown
## Agent B: server-libs

[Agent-specific scope, TDD steps, implementation details only]

DO NOT modify: lib/xrpl/types.ts (owned by Agent A), ...
```

The executor builds each agent's full prompt as: `Shared Contract + Prompt Preamble + Agent Prompt`.
