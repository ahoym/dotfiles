---
name: brief
description: "Load a research project's files into context and produce a concise brief for Q&A."
disable-model-invocation: true
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Brief a Ralph Research Project

Load all core research files into context and produce a concise synthesis. After the brief, the agent is ready for follow-up Q&A about the research.

## Usage

- `/ralph:brief <project-path>` - Brief a specific project (e.g., `docs/learnings/claude-skills-best-practices-v2`)
- `/ralph:brief` - List available projects and prompt for selection

## Instructions

### 1. Locate the project

- If `$ARGUMENTS` provided, use as the project path
- Otherwise, list directories under `docs/learnings/` and ask the user to pick one
- If the path exists locally (on the current branch), read from the filesystem
- If not, check for a `research/<basename>` branch:
  - Extract the basename from the path (e.g., `claude-skills-best-practices-v2` from `docs/learnings/claude-skills-best-practices-v2`)
  - Check if a `research/<basename>` branch exists via `git branch -a --list *research/<basename>*`
  - If found, read files via `git show <branch>:<path>` and note to the user: "📡 Reading from branch `research/<basename>` (files not on current branch)"
  - If neither local nor branch, error: "Project not found locally or on a research branch."

### 2. Read core files (loads context for Q&A)

Read these files fully — this is what enables follow-up questions:

- `spec.md` — topic definition, constraints
- `progress.md` — status, completed/pending tasks, answered questions, notes
- `info.md` — comprehensive research findings
- `assumptions-and-questions.md` — key decisions, assumptions, open items
- `implementation-plan.md` — phased action plan

If any core file is missing, note it but continue with what's available.

### 3. Inventory deep research files

List all other `.md` files in the project directory (excluding the 5 core files above). For each:

- Read the first heading + first paragraph (~10-20 lines) to get the topic summary
- Don't read the full file — these load on demand during Q&A

### 4. Synthesize and output the brief

Print the following to the conversation (do NOT write to a file):

```markdown
# <Project Name>

## Overview
<2-3 sentences from spec.md/info.md describing the topic and scope>

## Key Decisions
- <Decision>: <outcome> — <1-line rationale>
- ...
(from assumptions-and-questions.md confirmed items + progress.md **ANSWER:** items)

## Research Areas
- **<Topic>** (<status>): <1-2 line summary>
  → <filename>.md
- ...
(from info.md "Areas for Deeper Investigation" + deep research file inventory)

## Implementation Highlights
<Top 3-5 phases/steps from implementation-plan.md with one-liners>

## Status
<N/M tasks complete, N pending>
<Completion signal status>
<Unanswered questions if any>

## Open Items
- <Item>: <description>
(from assumptions-and-questions.md open items + unanswered progress.md questions)

---
*Context loaded. Ask me anything about this research.*
```

### 5. Ready for Q&A

After output, all core files are in context. When the user asks about a specific topic:

- Answer from already-loaded context (core files) when possible
- Read the full deep research file on demand if the question requires deeper detail

## Design Notes

- **No output file** — the brief is printed to conversation, not saved. It's ephemeral context-loading, not a persistent artifact.
- **Deep research files are lazy-loaded** — reading all 8+ deep research files upfront would be excessive. Headers give enough for the brief; full content loads on demand during Q&A.
- **Branch support** — ralph loops push to `research/<topic>` branches. The brief works whether the user is on that branch or not, using `git show` as fallback.
