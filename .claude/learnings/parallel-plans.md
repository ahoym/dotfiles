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

## Leaf/Orphaned Agent Tradeoff

When an agent has no downstream dependents (`depends_on` from other agents), it's "orphaned" — its failure only surfaces during final verification.

**Decision criteria:**
- **Keep separate** if parallel speedup > ~40s AND agent has its own tests (failures caught by final `pytest`)
- **Merge into adjacent agent** if agent is tiny (<50 lines) or the parallelism gain is negligible
- **Always document in Review Notes** — flag the tradeoff explicitly so the executor can re-evaluate

Example: Agent D (fireblocks destination config, ~70s) runs parallel with B+C. Merging into E would serialize it after C, adding ~40s to critical path. Keep separate, flag as leaf.

## Context Continuation for parallel-plan:make

When `/parallel-plan:make` spans a context boundary (session compaction or continuation), the session summary captures DAG design decisions (agent ownership, dependency types, speedup) but NOT file-level details needed for agent prompts (line numbers, surrounding code, exact function signatures).

**Impact:** The agent must re-read all target files (~15 reads for a 5-agent plan) to produce concrete landmarks. Budget ~5 minutes of file reads before writing the plan.

**Mitigation:** If the plan is large, consider writing the DAG structure and shared contract first (they don't need line-level detail), then the agent prompts in a second pass after re-reading files.

## Model Selection for Mechanical Edits

haiku handles multi-file mechanical edits well when instructions are explicit (exact field values, clear tables):
- 5 files with mixed frontmatter additions: 27s, 16 tool uses
- 4 files with mixed frontmatter additions: 22s, 12 tool uses

Use haiku for pattern-following edits across many files. Use sonnet when the agent needs judgment (e.g., description quality review, diverse context injection templates).

## Single Branch for Strict-Ownership Plans

When a parallel plan has strict file ownership (no file touched by two agents), use a single feature branch instead of per-agent branches. The multi-branch rebase chain (A → B → C → E, plus D) adds overhead with zero benefit — conflicts are impossible by construction. All agents commit sequentially to one branch, one MR at the end.

**When to use multi-branch:** Only when agents modify overlapping files or when independent review/merge per agent is required.

## Assign Integration Tests to the Wiring Agent

Integration tests (orchestrator-level, router-level) should be explicitly assigned to the last agent in the DAG (typically the wiring agent), not left as unassigned "post-execution" items. Unassigned tests create ambiguous ownership — they either get skipped or require a manual follow-up step that breaks the automated execution flow.

The wiring agent is the natural owner: it has all prior agents' work available and its job is verifying the connections between components.

## Adapting Parallel Plans for Non-Code Tasks

The parallel-plan format (designed for code with TDD) adapts to mechanical editing tasks (YAML frontmatter, markdown sections):

- **Shared Contract** → frontmatter field ordering conventions instead of type definitions
- **TDD steps** → `build-verify → "re-read all files"` instead of test suites
- **Integration tests** → structural checks (field ordering, count verification) instead of cross-module data flow
- **Pre-execution verification** → "no commands needed" (all tools are built-in)
- **Required Bash Permissions** → often none (Read/Edit/Glob/Write only)
