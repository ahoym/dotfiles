# Agent Prompting Best Practices

## Prompt Structure

Every agent prompt should follow this structure:

```
1. Role and scope declaration
2. File ownership (what to touch, what NOT to touch)
3. Shared contract (types, interfaces, API shapes)
4. Specific changes with code landmarks
5. Constraints and anti-patterns
```

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

Each agent prompt must include the relevant parts of the shared contract — don't assume agents can read the plan file:

```
## Shared Contract
- The `FilledOrder` type is defined in `lib/types.ts` as:
  `{ side: "buy" | "sell", price: string, baseAmount: string, ... }`
- The API endpoint returns: `{ address: string, filledOrders: FilledOrder[] }`
- The component accepts: `filledOrders: FilledOrder[]` and `loadingFilled: boolean`
```

This ensures all agents agree on interfaces without seeing each other's code.

## Model Selection

- **haiku**: Single file, small edit (< 30 lines changed), or writing a small new file with a provided template. Fast, cheap.
- **sonnet**: Default for most agents. Good balance of speed and capability.
- **opus**: Complex logic, large new files (> 200 lines), or agents that need to understand existing patterns and make nuanced decisions.

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
