---
description: "Analyze code for structured refactoring opportunities."
---

# Refactor Code

Analyze a file or class for refactoring opportunities and apply selected improvements.

## Usage

- `/do-refactor-code <filepath>` - Analyze a specific file
- `/do-refactor-code <filepath>:<classname>` - Analyze a specific class

## Reference Files

- `~/.claude/skill-references/code-quality-checklist.md` — Shared checklist of structural issues to look for

## Instructions

1. **Read the target file** — parse `$ARGUMENTS` to extract filepath and optional class name.

2. **Analyze using the checklist** — read `~/.claude/skill-references/code-quality-checklist.md` and evaluate the file against each item. Also look for:
   - Deeply nested logic that could be flattened (early returns, guard clauses)
   - Dead code (unused imports, unreachable branches, commented-out code)
   - Naming issues (misleading names, inconsistent conventions)

3. **Present findings** — group by category, with line numbers and specific suggestions:
   ```
   Found X refactoring opportunities:

   **Helper class extraction:**
   - Methods `check_inventory`, `update_inventory` at lines 45-80 only use `inventory_levels` field
     → Extract to `InventoryManager` class

   **Helper method extraction:**
   - Lines 112-118 and 145-151 duplicate DataProcessor creation
     → Extract to `_create_processor(datasets)` helper

   Which refactoring would you like to apply? (Enter number or 'all')
   ```

4. **Apply selected refactoring(s)** — make the changes, preserving behavior.

5. **Run validation** — execute the project's lint and test commands to verify correctness.

## Important Notes

- Always read the file before suggesting changes
- Preserve existing functionality — refactoring should not change behavior
- Follow project conventions (naming, access modifiers, file organization)
- Run tests after each refactoring to verify correctness
