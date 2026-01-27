---
description: Analyze code for refactoring: helper extraction, nested functions, test factories
---

# Refactor Code

Analyze a file or class for refactoring opportunities including helper class extraction, helper method extraction, nested function extraction, and test factory creation.

## Usage

- `/do-refactor-code <filepath>` - Analyze a specific file
- `/do-refactor-code <filepath>:<classname>` - Analyze a specific class

## Instructions

1. **Read the target file**:
   - Parse `$ARGUMENTS` to extract filepath and optional class name
   - Read the file contents

2. **Analyze for Helper Class Extraction opportunities**:
   Look for signs that a class should be split:
   - Methods that only operate on a subset of the class's fields
   - Method name prefixes suggesting a separate concern (e.g., `inventory_check`, `inventory_update`)
   - Large classes with distinct groups of related functionality

   Report findings like:
   ```
   HELPER CLASS EXTRACTION OPPORTUNITIES:
   - Methods `check_inventory`, `update_inventory`, `reserve_stock` all operate on `inventory_levels` field
     → Consider extracting to `InventoryManager` class
   ```

3. **Analyze for Helper Method Extraction opportunities**:
   Look for signs of duplicated code within a class:
   - Similar code blocks appearing in multiple methods
   - Object creation with repeated parameters
   - Setup/teardown logic duplicated across methods

   Report findings like:
   ```
   HELPER METHOD EXTRACTION OPPORTUNITIES:
   - Lines 45-52 and 78-85 both create DataProcessor with identical parameters
     → Extract to `_create_processor(datasets, output_format)` helper
   ```

4. **Analyze for Nested Function Extraction opportunities** (Python):
   Look for functions defined inside other functions:
   - Named `def` statements inside another `def`
   - Closures that don't actually need enclosing scope

   Report findings like:
   ```
   NESTED FUNCTION EXTRACTION OPPORTUNITIES:
   - `format_value` defined inside `process_data` at line 12
     → Extract to module-level `_format_value` helper
   ```

5. **Analyze for Test Factory opportunities** (if test file):
   Look for repeated test object creation:
   - Multiple tests creating similar objects with different values
   - Complex object construction with many required fields

   Report findings like:
   ```
   TEST FACTORY OPPORTUNITIES:
   - `Order` objects created in 5 tests with mostly identical fields
     → Create `make_order(**overrides)` factory function
   ```

6. **Analyze for Module to Package Extraction** (Python, large files):
   Look for monolithic files that should be split:
   - Files exceeding 500-1000 lines
   - Distinct sections (constants, models, utilities, main logic)
   - Multiple unrelated classes or function groups

   Report findings like:
   ```
   MODULE TO PACKAGE EXTRACTION:
   - `pipeline.py` (1089 lines) contains distinct sections:
     • Constants (lines 667-688)
     • Data classes (lines 33-359)
     • Utility functions (lines 362-623)
     • Main class (lines 787-1089)
     → Split into `pipeline/` package with focused modules
   ```

7. **Present summary and ask user**:
   ```
   Found X refactoring opportunities:
   - N helper class extractions
   - M helper method extractions
   - O nested function extractions
   - P test factory opportunities
   - Q module to package extractions

   Which refactoring would you like to apply? (Enter number or 'all')
   ```

8. **Apply selected refactoring(s)**:
   - For helper class extraction: Create new file with extracted class, update imports
   - For helper method extraction: Add private method, replace duplicated code with calls
   - For nested function extraction: Move to module/class level with `_` prefix
   - For test factories: Add factory function at module level, update test usages
   - For module to package: Create package directory, split into submodules, create `__init__.py` with re-exports (see `templates/package-init.py.template`)

9. **Run validation**:
   ```bash
   uv run ruff check <filepath> --fix
   uv run ruff format <filepath>
   uv run pytest <test_filepath> -v
   ```

## Reference

- `refactoring-patterns.md` - Detailed patterns and examples
- `templates/package-init.py.template` - Template for package `__init__.py` re-exports

## Important Notes

- Always read the file before suggesting changes
- Preserve existing functionality - refactoring should not change behavior
- Follow project conventions (private methods use `_` prefix in Python)
- Run tests after each refactoring to verify correctness
