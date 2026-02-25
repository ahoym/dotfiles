---
name: resume
description: "Resume a completed or blocked iterative research loop by collecting answers and relaunching."
disable-model-invocation: true
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Resume a Ralph Research Loop

Review the state of a completed or blocked ralph loop, collect answers to blocking questions, update progress.md, and relaunch the loop.

## Usage

- `/ralph:resume <project-path>` - Resume a specific project (e.g., `docs/learnings/claude-skills-best-practices-v2`)
- `/ralph:resume` - List available projects and prompt for selection

## Instructions

### 1. Locate the project

- If `$ARGUMENTS` provided, use as the project path
- Otherwise, list directories under `docs/learnings/` and ask the user to pick one
- If the path exists locally (on the current branch), read from the filesystem
- If not, check for a `research/<basename>` branch:
  - Extract the basename from the path (e.g., `claude-skills-best-practices-v2` from `docs/learnings/claude-skills-best-practices-v2`)
  - Check if a `research/<basename>` branch exists via `git branch -a --list *research/<basename>*`
  - If found, note to the user: "📡 Project lives on branch `research/<basename>`. You'll need to check out that branch or use a worktree before relaunching."
  - If neither local nor branch, error: "Project not found locally or on a research branch."

### 2. Read state

Read these files to understand the current state:

- `progress.md` — status, completed/pending tasks, questions, completion signal
- `spec.md` — topic scope (for context)

### 3. Present status

Output a status summary:

```markdown
# Resume: <Project Name>

## Current State
- **Status**: <COMPLETE | BLOCKED_ON_USER | IN_PROGRESS>
- **Completion signal**: <present | not present>
- **Tasks**: <N completed, M pending>
- **Iterations**: <N>

## Pending Tasks
- [ ] <task 1>
- [ ] <task 2>
- ...

## Blocking Questions
<List unanswered questions from "Questions Requiring User Input" — those WITHOUT **ANSWER:** prefix>

If no blocking questions: "No blocking questions — loop can resume as-is."

💡 *Need to review the research before answering? Run `/ralph:brief <project-path>` first.*
```

### 4. Collect answers

If there are unanswered questions:

- Present each question and ask the user for an answer
- The user may also:
  - Skip a question (leave unanswered)
  - Add new pending tasks
  - Remove or reorder existing pending tasks
  - Provide general notes for the next iteration

### 5. Update progress.md

Apply changes to `progress.md`:

- For each answered question, add `**ANSWER:**` prefix inline (e.g., `- How should X work? **ANSWER:** It should do Y`)
- Remove `WOOT_COMPLETE_WOOT` from the end of the file if present
- Add/remove/reorder pending tasks if the user requested changes
- Update "Notes for Next Iteration" if the user provided notes
- Update "Status" to `IN_PROGRESS`

### 6. Relaunch the loop

After updating progress.md:

```
Ready to resume. Run:
bash ~/.claude/lab/ralph/wiggum.sh <project-path>
```

If the user confirms, execute the command. If the project is on a remote branch (not local), remind the user they need to check out that branch first or use a worktree:

```
The project lives on branch research/<basename>. To resume:

Option A — checkout the branch:
  git checkout research/<basename>
  bash ~/.claude/lab/ralph/wiggum.sh <project-path>

Option B — use a worktree:
  git worktree add .ralph-worktree research/<basename>
  cd .ralph-worktree
  bash ~/.claude/lab/ralph/wiggum.sh <project-path>
```

## Design Notes

- **Follows question tracking convention** — uses `**ANSWER:**` inline prefix, not section header changes. This keeps the "Questions Requiring User Input" header stable for agents to append new questions.
- **Doesn't auto-launch** — presents the command and waits for confirmation, since the user may want to review changes to progress.md first.
- **Branch-aware** — ralph loops often run on `research/<topic>` branches via worktrees. The skill handles this gracefully rather than assuming files are on the current branch.
