---
description: Initialize an iterative research project with spec and progress tracking
---

# Initialize Ralph Research Project

Create a new Ralph loop project directory with customized spec and progress files.

## Usage

- `/init-ralph-research <topic>` - Create project for the given topic
- `/init-ralph-research` - Will prompt for topic

## Reference Files

- @spec-template.md - Template for spec.md with v2 features (dynamic tasks, deep research workflow)
- @progress-template.md - Template for progress.md with questions section
- @assumptions-template.md - Template and guidance for assumptions-and-questions.md

## Instructions

1. **Get project topic**:
   - If `$ARGUMENTS` provided, use that as the topic
   - Otherwise, ask: "What topic should this research project cover?"

2. **Derive project name**:
   - Convert topic to kebab-case for directory name (e.g., "Monte Carlo Simulation" → "monte-carlo-simulation")
   - Keep it concise (3-4 words max)

3. **Create project directory**:
   ```bash
   mkdir -p docs/claude-learnings/<project-name>
   ```

4. **Create spec.md** using @spec-template.md:
   - Replace `<PROJECT_NAME>` with the topic (title case)
   - Replace `<TOPIC>` with the topic
   - Replace `<output_file>` with `info.md`
   - Adjust References section to use correct relative path to repository root

5. **Create progress.md** using @progress-template.md:
   - Replace `<TOPIC>` with the topic

6. **Confirm to user**:
   ```
   Created Ralph research project: docs/claude-learnings/<project-name>/

   Files created:
   - spec.md
   - progress.md

   To run the loop:
   bash .claude/lab/ralph/wiggum.sh docs/claude-learnings/<project-name> 10
   ```

## Example

```
/init-ralph-research options pricing models

Created Ralph research project: docs/claude-learnings/options-pricing-models/

Files created:
- spec.md (configured for "Options Pricing Models" research)
- progress.md (ready for first iteration)

To run the loop:
bash .claude/lab/ralph/wiggum.sh docs/claude-learnings/options-pricing-models 10
```

## Research Conventions

### info.md as Investigation Tracker

The "Areas for Deeper Investigation" section in info.md serves as the tracker for research progress. Use strikethrough + links to show completed investigations:

```markdown
## Areas for Deeper Investigation

1. ~~Token optimization strategies~~ → See [token-optimization.md](./token-optimization.md)
2. ~~CI/CD integration~~ → See [ci-cd-integration.md](./ci-cd-integration.md)
3. Quality metrics - measuring output quality across iterations
4. Context handoff patterns - efficient state transfer between iterations
```

**Why this format:**
- Visual progress: Strikethrough shows what's done at a glance
- Navigation: Links let readers jump to detailed research
- Task generation: Remaining non-struck items drive new Deep Research tasks

**Alternative for lighter investigations** (no separate file produced):
```markdown
- [x] Token optimization strategies
- [ ] Quality metrics
```

### Deep Research: Separate Files vs. Consolidation

**Create separate `<topic>.md` files when:**
- Research exceeds ~200 lines
- Topic is self-contained with its own sources
- Content includes code samples, tables, or detailed specifications
- Topic may be referenced independently

**Append to info.md when:**
- Research is brief (<100 lines)
- Findings are closely tied to core research
- Topic doesn't warrant standalone navigation

The hybrid approach keeps info.md lean as a navigation hub while substantial research lives in dedicated files.
