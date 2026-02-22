---
description: "Internal reference — best practices for crafting subagent prompts (speed, landmarks, boundaries). Used by skills that launch subagents, not invoked directly."
---

# Agent Prompting Best Practices

## Prompt Structure

The executor builds each agent's full prompt as: `Shared Contract + Prompt Preamble + Agent Prompt`.

The **Shared Contract** and **Prompt Preamble** are prepended automatically (see SKILL.md Step 5). The agent's own `prompt` field should contain:

```
1. Role and scope declaration (task description)
2. File ownership (what to touch, what NOT to touch) — including test files
3. Specific changes with code landmarks
4. Agent-specific TDD steps (RED → GREEN → REFACTOR with concrete test names)
5. Constraints and DO NOT MODIFY boundaries
```

The shared contract, general TDD workflow template, project commands, and completion report format are provided by the preamble — don't duplicate them in agent prompts.

## What Makes a Fast Agent (< 40s, < 6 tool uses)

- **Complete code snippets** for new content (copy-paste ready)
- **Exact match strings** for Edit tool targets (not paraphrased)
- **Single file** scope
- **No exploration needed** — the prompt tells the agent exactly where to insert/modify

Example of a fast prompt:
```
Read and modify `/path/to/file.tsx`:
1. Add `onRefresh?: () => void` to the props interface on line 12
2. Replace the loading div (the one with className "text-xs text-zinc-500") with:
   [exact JSX snippet]
3. DO NOT modify any other file
```

## What Makes a Slow Agent (> 60s, > 10 tool uses)

- **Vague placement**: "find the appropriate spot" → agent reads the file multiple times
- **Missing context**: "add validation" without specifying variable names → agent explores imports
- **Large scope**: 3+ files to modify → agent context-switches between reads and edits
- **Ambiguous instructions**: "improve the loading state" → agent makes judgment calls

## Scaling Prompts by File Size

**New files < 100 lines:** Provide the complete file content as a code block. Agent just writes it. Fastest possible.

**New files 100-300 lines:** Provide the structure, key functions with full implementations, and let the agent fill in straightforward parts (imports, boilerplate). Describe the boilerplate concisely rather than writing it out.

**New files > 300 lines:** Provide the architecture (exports, helper signatures, component structure), full implementations of complex logic, and describe the simpler sections. The agent will need to make some decisions — constrain these with explicit style/pattern references.

**Modifying existing files:** The agent must read first, then make targeted edits. Reduce time by:
- Providing the exact old_string to match in Edit operations
- Listing changes in order of file position (top to bottom)
- Grouping related changes that are near each other

## Code Landmarks

Instead of: "Add the warning near the submit button"
Write: "Add the warning after the `{summary && (` block, before the Execution Type section"

Instead of: "Update the canSubmit check"
Write: "Find `const canSubmit = !submitting &&` and add `!insufficientBalance &&` after `!submitting`"

The more specific the landmark, the fewer reads the agent needs.

## TDD Workflow in Prompts

Every agent prompt must include a TDD section. The planner defines the TDD steps; the executor copies them verbatim into the prompt.

**Important:** Background agents can use Bash but cannot prompt for permissions. The project's test/build/lint commands must have matching allow patterns in `.claude/settings.local.json` before launching agents. The executor verifies this in Step 0 (pre-execution verification).

**Structure:**
```
## TDD Workflow (mandatory)

For each change, follow RED → GREEN → REFACTOR:

**Step 1: <description>**
- RED: Write `<test_name>` in `<test-file-path>` that tests <behavior>.
  Run it — it MUST fail (the implementation doesn't exist yet).
  ```bash
  <project's test command targeting the specific test>
  ```
- GREEN: Implement the minimal code in `<source-file>` to make the test pass.
  Run it — it MUST pass now.
- REFACTOR: Clean up while keeping tests green.

**Step 2: <description>**
...

Before finishing, run the full test suite:
```bash
<project's full test command>
```
```

**Key points:**
- Use the project's actual test commands (e.g., `uv run pytest`, `npm test`, `go test ./...`, `cargo test`) — never hardcode a specific tool
- Test file paths must be concrete, not "find the appropriate test file"
- Test names must be specific and descriptive, not generic like `test_it_works`
- The RED phase run command should target the specific test, not the full suite (faster feedback)
- If the agent needs shared fixtures from another agent, the dependency must be declared in `depends_on`

## Code Formatting

If the project uses a code formatter (prettier, biome, dprint, etc.), every agent must run it on its files before the final test suite. Look for formatter config files (`.prettierrc`, `.prettierrc.json`, `biome.json`, `.editorconfig`) or format scripts in `package.json` during pre-execution verification.

Include the format command in the agent prompt's final steps:
```
Before finishing, format your files:
<project's format command, e.g., `npx prettier --write <files>`>

Then run the full test suite to verify nothing broke.
```

If the project has a `format:fix` or equivalent script, prefer that over raw `npx prettier --write`.

## Boundary Constraints

Always include explicit boundaries:

```
DO NOT modify `trade-grid.tsx` or any other file — Agent D handles that.
```

This prevents:
- Agents "helpfully" updating parent components
- File conflicts between parallel agents
- Scope creep that breaks the DAG

## Shared Contract in Prompts

The executor automatically prepends the plan's **Shared Contract** section to every agent prompt (see SKILL.md Step 5). Agent prompts do NOT need to duplicate the shared contract — they can reference it (e.g., "see Shared Contract above").

If the plan has a **Prompt Preamble** section, that is also prepended (after the Shared Contract, before the agent's own prompt). The preamble contains process instructions (TDD workflow, project commands, completion report format) that apply to all agents.

The full prompt sent to each agent is: `Shared Contract + Prompt Preamble + Agent Prompt`.

This ensures all agents agree on interfaces without the planner duplicating the contract in every agent prompt. Agent-specific prompts focus on: task description, landmarks, TDD steps, file scope, and DO NOT MODIFY boundaries.

## Model Selection

The **coordinator** makes the final model decision for each agent, overriding any plan suggestion if appropriate. Consider the agent's actual scope and complexity, not just what the plan estimated.

- **haiku**: Single file, small edit (< 30 lines changed) with a straightforward test. Only when the TDD steps are simple and the test is obvious. Also good for: agents that only create new files by following an existing pattern (e.g., a new API route that mirrors an existing one), and agents with only `build-verify` TDD steps. Fast, cheap.
- **sonnet**: Default for most agents. Handles TDD workflow reliably — can write meaningful tests, verify RED/GREEN phases, and refactor.
- **opus**: Complex logic, large new files (> 200 lines), or agents that need to understand existing patterns and make nuanced decisions. Also use for agents where the test design itself is non-trivial (e.g., testing async behavior, complex mocking).

## Completion Report in Prompts

Every agent prompt must end with instructions to produce a **Completion Report**. This is how the orchestrator captures checkpoints, discoveries, and status from agents whose sessions are otherwise lost.

**Include this section in every prompt:**
```
## Completion Report (required)

When you finish, end your output with this report:

### Files
- Created: [list files created]
- Modified: [list files modified]

### TDD Steps
- Completed: N/N
- Checkpoint: Step N (last fully completed step)

### Discoveries
Report anything surprising, unexpected, or useful for other agents:
- Gotchas (e.g., "API returns dates as ISO strings, not timestamps")
- Pattern observations (e.g., "existing tests use factory fixtures, not raw constructors")
- Edge cases found during implementation
- If nothing notable, write "None"
```

**Why this matters:**
- Agent sessions are isolated — the orchestrator only sees the final output message and the files on disk
- Checkpoints enable resumption from the right step if the agent fails and needs to be re-launched
- Discoveries are collected by the orchestrator and surfaced to the user (and to other agents if relevant)

## Interface-First Agent Prompts

The interface-first agent (typically Agent A) defines shared types and test fixtures. Its prompt should:
- List every type/interface to create with exact field definitions
- Create test fixtures that other agents will import
- Complete quickly — keep scope minimal, no business logic
- Its soft dependents may start as soon as its files are written, so file creation should happen early in the agent's execution

## Integration Agent Prompts

The integration agent (typically the last in the DAG) needs the most context because it must understand what every predecessor produced. Include:

1. **What each predecessor added** (new props, new exports, new state)
2. **Where to thread** each new prop (which parent passes to which child)
3. **Import paths** for new exports
4. **State initialization** (default values, types)

Example:
```
## Context — What other agents already did
1. Agent A created `lib/xrpl/filled-orders.ts` exporting `parseFilledOrders()`
2. Agent B added `filledOrders: FilledOrder[]` and `loadingFilled: boolean` to
   the return value of `useTradingData()` in `lib/hooks/use-trading-data.ts`
3. Agent C created `app/trade/components/orders-sheet.tsx` exporting
   `OrdersSheet` and `OrdersSection`, both accepting props: { filledOrders, loadingFilled, offers, ... }

## Your job
Wire these together in `app/trade/page.tsx` and `app/trade/components/trade-grid.tsx`.
```
