---
name: do-refactor-code
description: "Analyze a file for refactoring opportunities and apply selected improvements."
argument-hint: "[filepath]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Edit
  - Write
  - Bash
---

# Refactor Code

Analyze a file or class for refactoring opportunities including helper class extraction, helper method extraction, nested function extraction, and test factory creation.

## Usage

- `/do-refactor-code <filepath>` - Analyze a specific file
- `/do-refactor-code <filepath>:<classname>` - Analyze a specific class

## Reference Files

- `~/.claude/skill-references/code-quality-checklist.md` — Shared checklist of structural issues to look for
- `~/.claude/learnings/refactoring-patterns.md` — Refactoring patterns with multi-language examples

## Instructions

1. **Read the target file**:
   - Parse `$ARGUMENTS` to extract filepath and optional class name
   - Read the file contents

2. **Analyze using the checklist and structural patterns**:
   Read `~/.claude/skill-references/code-quality-checklist.md` and evaluate the file against each item. Also look for:

   **Helper Class Extraction opportunities:**
   - Methods that only operate on a subset of the class's fields
   - Method name prefixes suggesting a separate concern (e.g., `inventory_check`, `inventory_update`)
   - Large classes with distinct groups of related functionality

   **Helper Method Extraction opportunities:**
   - Similar code blocks appearing in multiple methods
   - Object creation with repeated parameters
   - Setup/teardown logic duplicated across methods

   **Nested/Inner Function Extraction opportunities:**
   - Named functions or closures defined inside another function
   - Inner functions that don't actually need enclosing scope

   **Test Factory opportunities** (if test file):
   - Multiple tests creating similar objects with different values
   - Complex object construction with many required fields

   **Large File Decomposition** (500+ lines):
   - Files exceeding 500-1000 lines
   - Distinct sections (constants, models, utilities, main logic)
   - Multiple unrelated classes or function groups

   **General structural issues:**
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

   **Nested function extraction:**
   - `format_value` defined inside `process_data` at line 12
     → Extract to module-level `_format_value` helper

   **Test factory opportunities:**
   - `Order` objects created in 5 tests with mostly identical fields
     → Create `make_order(**overrides)` factory function

   **Module to package extraction:**
   - `pipeline.py` (1089 lines) contains distinct sections:
     - Constants (lines 667-688)
     - Data classes (lines 33-359)
     - Utility functions (lines 362-623)
     - Main class (lines 787-1089)
     → Split into `pipeline/` package with focused modules

   Which refactoring would you like to apply? (Enter number or 'all')
   ```

4. **Apply selected refactoring(s)**:
   - For helper class extraction: Create new file with extracted class, update imports
   - For helper method extraction: Add private method, replace duplicated code with calls
   - For nested function extraction: Move to module/class level with `_` prefix
   - For test factories: Add factory function at module level, update test usages
   - For large file decomposition: Create package/directory, split into submodules, create barrel exports (see `~/.claude/learnings/refactoring-patterns.md` for language-specific patterns)

5. **Run validation**:
   Execute the project's lint and test commands to verify correctness.

## Important Notes

- Always read the file before suggesting changes
- Preserve existing functionality — refactoring should not change behavior
- Follow project conventions (naming, access modifiers, file organization)
- Run tests after each refactoring to verify correctness
