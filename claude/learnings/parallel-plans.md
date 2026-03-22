DAG-based parallel plan design: critical path analysis, agent splitting, branch strategies, fan-in cherry-pick, and plan file structure.
- **Keywords:** DAG, critical path, parallel agents, fast/slow track, worktree, cherry-pick, fan-in, haiku, model selection, strict file ownership, plan splitting, prompts file
- **Related:** multi-agent-patterns.md

---

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

## Import Dependencies Force Agent Merges

When Class A imports from Class B's module (e.g., `OrderCommand` imports `ServiceConfig`), those classes cannot live in separate worktree-isolated agents — the importing class won't compile without the imported class. This forces merging the two agents even if their file lists don't overlap.

**Detection:** During DAG design, trace import chains across agent boundaries. Any cross-agent import where the imported type doesn't exist in the base branch requires merging the agents or restructuring to break the dependency (e.g., extract shared types into a foundation agent that runs first).

**Example:** Agent B (domain model) creates `OrderCommand` which imports `ServiceConfig` from Agent C (config). Neither file exists in the base branch → Agent B's worktree can't compile → merge B and C into one agent.

## Front-Load Shared Config to One Early Agent

When multiple agents need to add entries to a shared file (e.g., `application.properties`, `pom.xml`), assign ALL writes to a single early agent rather than splitting ownership. Later agents reference the config but don't modify it — they use alternative access patterns (e.g., `@Value` annotation instead of `@ConfigurationProperties` class) if their ideal approach would require modifying the shared file.

**Why:** Parallel plans require strict file ownership (no file touched by two agents). Shared config files are the most common violation. Front-loading eliminates the conflict entirely.

## Fan-In Cherry-Pick: Parallel Siblings Miss Each Other's Work

When an agent depends on two parallel siblings (e.g., H depends on F and G, where F∥G), cherry-picking one dependency's branch misses the other's commits — each sibling only has its own work plus shared ancestors.

**Fix:** Cherry-pick the dependency whose branch has the most cumulative DAG history, then separately cherry-pick the other sibling's unique commits. For H depending on F and G (both depending on D): cherry-pick `main..feat/schedulers` (includes A→B→C→D→G), then cherry-pick `feat/service-layer..feat/rest-api` (F's unique commits beyond D).

**Detection:** Any agent with 2+ dependencies where those dependencies are not in a chain (i.e., neither depends on the other). The executor skill's prompt construction should include cherry-pick commands for all dependency branches, not just one.

## Background Agent CLI Permission Gotcha

`Bash(gh *)` / `Bash(glab *)` permission allows PR/MR creation interactively, but background agents hit a secondary permission prompt on quoted string content within the command. The agent silently blocks waiting for approval that never comes.

**Workaround:** Coordinator creates PRs/MRs on behalf of blocked agents using the agent's worktree path and branch. Budget time for this fallback — observed hitting 6/8 agents in a large parallel execution.

**Potential fix:** Use `--no-editor` flag and avoid HEREDOC/quoted descriptions, or pre-register more specific CLI permission patterns.

## Context Compaction Loses Agent Task References

When the coordinator session compacts (context limit), background agent task IDs are lost. The state file (`.parallel-plan-state.json`) preserves agent status but not the runtime task handle needed for `TaskOutput`.

**Recovery:** Check `git worktree list` for active worktrees, `git ls-remote origin <branch>` for pushed branches. Cross-reference with state file to identify which agents completed. Resume orchestration from state file — treat agents with pushed branches as completed.

## Two-File Split: Plan + Prompts

Split monolithic parallel plans into two sibling files:
- **`<name>.plan.md`** — Review surface + status tracking (~300 lines). Contains: Context, Shared Contract, Agent summary table, DAG, Critical Path, Integration Tests, Verification, Branch Strategy, Review Notes, Execution State. This is the only file that changes after creation (Execution State updates).
- **`<name>.prompts.md`** — Execution manifest (~1000+ lines). Contains: Prompt Preamble, full agent definitions (metadata + prompts). Immutable after creation.

**Key properties:**
- Cross-references link the two files (`**Prompts:** ./name.prompts.md` / `**Plan:** ./name.plan.md`)
- Executor reads Shared Contract from plan file + Preamble from prompts file, prepends both to each agent's prompt
- Reviewers only need the plan file; the prompts file is rarely read by humans
- Shared Contract stays in plan file (single source of truth, not duplicated in preamble)

## Cross-Refs

- `multi-agent-patterns.md` — agent orchestration patterns, worktree isolation, background agent lifecycle (complements the DAG/plan-level patterns here)
