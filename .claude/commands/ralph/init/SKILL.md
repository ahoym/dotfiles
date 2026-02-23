---
description: "Initialize an iterative research project with spec and progress tracking."
---

# Initialize Ralph Research Project

Create a new Ralph loop project directory with customized spec and progress files.

## Usage

- `/ralph:init <topic>` - Create project for the given topic
- `/ralph:init` - Will prompt for topic

## Reference Files

- @spec-template.md - Template for spec.md with v2 features (dynamic tasks, deep research workflow)
- @progress-template.md - Template for progress.md with questions section

## Instructions

1. **Get project topic**:
   - If `$ARGUMENTS` provided, use that as the topic
   - Otherwise, ask: "What topic should this research project cover?"

2. **Derive project name**:
   - Convert topic to kebab-case for directory name (e.g., "Monte Carlo Simulation" → "monte-carlo-simulation")
   - Keep it concise (3-4 words max)

3. **Check for existing project**:
   - If `docs/learnings/<project-name>/` already exists, warn the user: "Project directory already exists. Overwriting will destroy any in-progress research. Proceed?"
   - Only continue if the user confirms

4. **Create project directory**:
   ```bash
   mkdir -p docs/learnings/<project-name>
   ```

5. **Create spec.md** using @spec-template.md:
   - Replace `<PROJECT_NAME>` with the topic (title case)
   - Replace `<TOPIC>` with the topic
   - Adjust References section to use correct relative path to repository root

6. **Create progress.md** using @progress-template.md:
   - Replace `<TOPIC>` with the topic

7. **Confirm to user**:
   ```
   Created Ralph research project: docs/learnings/<project-name>/

   Files created:
   - spec.md
   - progress.md

   Next: Run the Ralph loop:
   bash ~/.claude/lab/ralph/wiggum.sh docs/learnings/<project-name>
   ```

## Example

```
/ralph:init options pricing models

Created Ralph research project: docs/learnings/options-pricing-models/

Files created:
- spec.md (configured for "Options Pricing Models" research)
- progress.md (ready for first iteration)

Next: Run the Ralph loop:
bash ~/.claude/lab/ralph/wiggum.sh docs/learnings/options-pricing-models
```