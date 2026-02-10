# Skill Template & File Organization

Reference for creating new skills and organizing skill files.

## Skill Structure Template

```markdown
---
description: One-line description of what the skill does
---

# Skill Name

One-line description of what the skill does.

## Usage

- `/skill-name` - Default behavior
- `/skill-name <arg>` - With argument
- `/skill-name --flag` - With option

## Reference Files (conditional — read only when needed)

- reference-file.md - Description of what it contains

## Instructions

1. **Step name**:
   - Explanation
   ```bash
   command
   ```

2. **Next step**:
   ...

## Example Output (optional)

```
Example session showing typical usage
```

## Important Notes

- Caveats, warnings, edge cases
```

## Skill File Organization

### Standalone vs Directory Structure

Skills can be organized two ways:

| Structure | When to Use |
|-----------|-------------|
| `skill-name.md` | Simple skills with no reference files |
| `skill-name/SKILL.md` | Skills with templates, scripts, or reference files |

### Migrating to Directory Structure

When a skill grows to need reference files (templates, scripts, etc.):

1. Create directory: `mkdir .claude/commands/skill-name/`
2. Move skill: `mv .claude/commands/skill-name.md .claude/commands/skill-name/SKILL.md`
3. Extract large content blocks into reference files (e.g., `pr-body-template.md`, `init-script.sh`)
4. Add `## Reference Files` section with references to supporting files

**Before:**
```
.claude/commands/
└── git-create-pr.md        # 80+ lines with embedded template
```

**After:**
```
.claude/commands/
└── git-create-pr/
    ├── SKILL.md            # Main instructions, references template
    └── pr-body-template.md # Extracted template
```

### When to Extract Reference Files

Extract content into separate files when:
- Templates are 10+ lines
- Shell scripts are reusable or complex
- Content would benefit from syntax highlighting in its own file
- Multiple skills might share the same reference

See writing-best-practices.md for conventions when writing skill content.

## Related References

- content-type-decisions.md - Deciding if something should be a skill, guideline, or learning
- writing-best-practices.md - Conventions for writing effective skills
- iterative-loop-design.md - Patterns for Ralph-style research loops
