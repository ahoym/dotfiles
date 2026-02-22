---
description: "Compare duplicate research directories to determine which is superseded. Use when the user says \"compare these research dirs\", \"which ralph project is newer\", \"deduplicate research\", or has multiple research loops covering the same topic."
---

# Compare Ralph Projects

Compare multiple Ralph loop directories that cover the same topic to determine which is superseded and whether anything needs porting.

## Usage

- `/ralph:compare <dir1> <dir2>` - Compare two directories
- `/ralph:compare <dir1> <dir2> <dir3>` - Compare three directories
- `/ralph:compare` - Will prompt for directories to compare

## Reference Files (conditional — read in step 3)

- comparison-checklist.md - Aspects to compare and signs of supersession

## Instructions

1. **Get directories to compare**:
   - If `$ARGUMENTS` provided, parse as space-separated directory paths
   - Otherwise, ask: "Which directories would you like to compare? (e.g., `docs/claude-learnings/tmp-feature docs/claude-learnings/feature`)"
   - Verify each directory exists

2. **Read all files from each directory**:
   - List files in each directory
   - Read key files: `spec.md`, `progress.md`, `info.md`, `assumptions-and-questions.md`
   - Note which files are unique to each directory

3. **Build comparison table**:
   Using the checklist in comparison-checklist.md, compare:

   ```markdown
   | Aspect | Dir A | Dir B |
   |--------|-------|-------|
   | Total files | X | Y |
   | Iterations tracked | N | M |
   | Research lines (info.md) | ~200 | ~500 |
   | Implementation phases | 6 | 10 |
   | Has assumptions doc | No | Yes |
   | Has iteration logs | No | Yes |
   | Spec version | v1 | v2 |
   ```

4. **Identify superseded directory**:
   Check for signs of supersession:
   - Minimal progress.md (just completion marker vs structured tracking)
   - Significantly shorter research (fewer lines in info.md)
   - Less structured spec (informal vs proper Ralph loop format)
   - No iteration logs (single incomplete run vs multiple iterations)
   - Missing documentation (no assumptions, codebase analysis, or Q&A)

5. **Check for unique content to port**:
   - Read unique files in the superseded directory
   - Search for sections not covered in the newer version
   - If found, list specific sections that should be ported

6. **Present recommendation**:
   ```markdown
   ## Comparison Summary

   | Aspect | <dir1> | <dir2> |
   |--------|--------|--------|
   | ... | ... | ... |

   ## Recommendation

   **Superseded**: <directory> is superseded by <directory>

   **Porting needed**: <Yes/No>
   <If yes, list specific sections>

   **Action**: `rm -rf <superseded-directory>`
   ```

7. **If consolidation needed instead** (directories have complementary content):
   ```markdown
   ## Recommendation

   **Neither is fully superseded** - directories have complementary content.

   **Consolidation approach**:
   - Keep <directory> as target
   - Port from <directory>:
     - <file or section 1>
     - <file or section 2>
   - Delete <directory> after porting
   ```

## Example

```
User: /ralph:compare docs/claude-learnings/tmp-monte-carlo docs/claude-learnings/monte-carlo-simulation

Claude: Comparing directories...

## Comparison Summary

| Aspect | tmp-monte-carlo | monte-carlo-simulation |
|--------|-----------------|------------------------|
| Total files | 3 | 8 |
| Iterations tracked | 2 | 7 |
| Research lines (info.md) | ~150 | ~480 |
| Implementation phases | 4 | 8 |
| Has assumptions doc | No | Yes |
| Has iteration logs | No | Yes |
| Spec version | v1 | v2 |

## Recommendation

**Superseded**: tmp-monte-carlo is superseded by monte-carlo-simulation

**Porting needed**: No - monte-carlo-simulation covers all topics with more depth

**Action**: `rm -rf docs/claude-learnings/tmp-monte-carlo`
```

## Important Notes

- Always read files before making recommendations - don't assume based on names
- Some directories may need consolidation rather than deletion
- The "better" directory isn't always the one with more files - quality matters
- Check for unique deep research files that may exist only in the "older" directory
