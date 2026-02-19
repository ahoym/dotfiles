# Prompt Writing Guide

Best practices for writing agent prompts in parallel plans. Read this when writing agent prompts in Step 9.

## Prompt Structure

The executor prepends `Shared Contract + Prompt Preamble` to every agent prompt automatically. The agent's `prompt` field should contain only agent-specific content:

1. Role and scope declaration (task description)
2. File ownership (what to touch, what NOT to touch) — including test files
3. Specific changes with code landmarks
4. Agent-specific TDD steps (RED → GREEN → REFACTOR with concrete test names)
5. Constraints and DO NOT MODIFY boundaries

Do not duplicate shared contract or preamble content in agent prompts.

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

Every agent prompt must include a TDD section with concrete test names and file paths.

**Structure:**
```
## TDD Workflow (mandatory)

For each change, follow RED → GREEN → REFACTOR:

**Step 1: <description>**
- RED: Write `<test_name>` in `<test-file-path>` that tests <behavior>.
  Run it — it MUST fail (the implementation doesn't exist yet).
  [project's test command targeting the specific test]
- GREEN: Implement the minimal code in `<source-file>` to make the test pass.
  Run it — it MUST pass now.
- REFACTOR: Clean up while keeping tests green.

**Step 2: <description>**
...

Before finishing, run the full test suite:
[project's full test command]
```

**Key points:**
- Use the project's actual test commands (e.g., `uv run pytest`, `npm test`, `go test ./...`) — never hardcode a specific tool
- Test file paths must be concrete, not "find the appropriate test file"
- Test names must be specific and descriptive, not generic like `test_it_works`
- The RED phase run command should target the specific test, not the full suite (faster feedback)
- If the agent needs shared fixtures from another agent, the dependency must be declared in `depends_on`

## Code Formatting

If the project uses a code formatter (prettier, biome, dprint, etc.), include the format command in each agent prompt's final steps:

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

## Completion Report

Every agent prompt must end with instructions to produce a Completion Report:

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
- Agent sessions are isolated — the coordinator only sees the final output and files on disk
- Checkpoints enable resumption if the agent fails and needs re-launch
- Discoveries are collected by the coordinator and surfaced to the user

## Interface-First Agent Prompts

The interface-first agent (typically Agent A) defines shared types and test fixtures. Its prompt should:
- List every type/interface to create with exact field definitions
- Create test fixtures that other agents will import
- Complete quickly — keep scope minimal, no business logic
- File creation should happen early in execution, since soft dependents may start as soon as files exist

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
