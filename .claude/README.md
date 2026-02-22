# Claude Code Dotfiles

Shared Claude Code configuration: skills, guidelines, learnings, and settings.

## Setup

Clone this repo and run the setup script:

```sh
git clone <repo-url>
cd dotfiles
./setup-claude.sh
```

This symlinks everything in `.claude/` into `~/.claude/`, making it available globally across all projects. Existing files are backed up before being replaced.

## What's included

| Path | Purpose |
|------|---------|
| `commands/` | Custom skills (slash commands) |
| `guidelines/` | Shared guidelines referenced by CLAUDE.md |
| `learnings/` | Accumulated learnings and reference docs |
| `lab/` | Experimental/research projects |
| `settings.local.json` | Permission rules for dotfile skills |

## Skills

### Git (`/git:*`)

| Skill | Description |
|-------|-------------|
| `/git:create-pr` | Create a PR or update an existing one following project conventions |
| `/git:address-pr-review` | Fetch and address review comments from a PR |
| `/git:explore-pr` | Pull down a PR to get context and ask questions about it |
| `/git:monitor-pr-comments` | Watch a PR in background and address new comments as they arrive |
| `/git:split-pr` | Analyze a large PR and propose how to split it into smaller units |
| `/git:close-redundant-pr` | Close a redundant PR and extract unique content into a new focused PR |
| `/git:repoint-branch` | Extract independent changes from a feature branch into a new PR targeting main |
| `/git:cascade-rebase` | Rebase a chain of stacked/dependent branches when main is updated |
| `/git:preview-conflicts` | Preview merge conflicts between branches without merging |
| `/git:resolve-conflicts` | Resolve merge conflicts between branches |
| `/git:split-commit` | Split a commit with mixed changes into separate, focused commits |
| `/git:create-followup-issue` | Create a GitHub issue from a PR review comment |
| `/git:prune-merged` | Clean up local branches that have been merged into main |

### Learnings (`/learnings:*`)

| Skill | Description |
|-------|-------------|
| `/learnings:compound` | Capture session learnings and save to skills, guidelines, or reference docs |
| `/learnings:curate` | Single-pass curation of learnings, guidelines, and skills |
| `/learnings:consolidate` | Exhaustive multi-sweep curation — auto-applies HIGHs, batches MEDIUMs for approval |
| `/learnings:distribute` | Distribute global learnings and guidelines into the current project |

### Parallel Plan (`/parallel-plan:*`)

| Skill | Description |
|-------|-------------|
| `/parallel-plan:make` | Analyze a sequential plan for parallelization opportunities |
| `/parallel-plan:execute` | Execute a structured parallel plan using concurrent subagents |

### Ralph Research (`/ralph:*`)

| Skill | Description |
|-------|-------------|
| `/ralph:init` | Initialize an iterative research project with spec and progress tracking |
| `/ralph:compare` | Compare duplicate research directories to determine which is superseded |

### Standalone

| Skill | Description |
|-------|-------------|
| `/explore-repo` | Deep-scan a repository to understand its structure and documentation gaps |
| `/do-refactor-code` | Analyze code for structured refactoring: extraction, decomposition, test factories |
| `/do-security-audit` | Run a security audit on one or more projects using parallel agents |
| `/set-persona` | Set domain focus and priorities for the current session |
| `/quantum-tunnel-claudes` | Pull and merge skills, learnings, and guidelines from a configured sync source |

## Workflows

### Parallel Plan: plan → execute

Design a parallel implementation strategy, then run it with concurrent agents.

```
1. Write or discuss a sequential plan with Claude
2. /parallel-plan:make          → analyzes the plan, produces a parallel plan file
3. Review the plan file         → adjust dependencies, agent boundaries, branch strategy
4. /parallel-plan:execute       → runs the plan with concurrent subagents per the DAG
```

The make step identifies which tasks can run concurrently, assigns them to agents with specific file boundaries, and maps dependencies as a DAG. The execute step schedules agents based on that DAG, manages worktrees, and merges results.

**Tips:**
- The plan file is a regular markdown file — edit it between make and execute if needed
- If execution fails partway, re-run execute; it picks up where it left off
- For complex features, the DAG shape (critical path) bounds your speedup, not the number of agents

### Learnings: capture → curate → distribute

Accumulate knowledge over time, keep it organized, and push it to projects that need it.

```
Capture (after any session with useful patterns):
  /learnings:compound           → extracts learnings and saves to ~/.claude/learnings/,
                                  guidelines/, or skill reference files

Curate (targeted cleanup):
  /learnings:curate <file>      → single-pass review of a specific file
  /learnings:consolidate        → exhaustive multi-sweep of everything

Sync (pull from another repo):
  /quantum-tunnel-claudes       → pulls new/changed content from sync source,
                                  then run /learnings:curate to clean up what was pulled

Distribute (push to a project):
  /learnings:distribute         → copies relevant global learnings into the
                                  current project's .claude/ directory
```

**Typical cadences:**
- `compound` — end of any session where you learned something new
- `curate` — after compound adds content, or when a file feels bloated
- `consolidate` — periodic deep clean (weekly/monthly), or after a burst of compound runs
- `distribute` — when starting work in a project that should inherit global knowledge

### Explore Repo + Capture Learnings

Scan an unfamiliar codebase, then persist the patterns you discovered.

```
1. cd into the project
2. /explore-repo               → parallel agents scan structure, APIs, data model, etc.
                                  produces docs/learnings/ files and SYSTEM_OVERVIEW.md
3. /explore-repo               → run again to synthesize (scan and synthesis are separate)
4. /learnings:compound         → capture any cross-project patterns into global learnings
```

Step 4 is optional — only run it if the scan surfaced patterns useful beyond this one project (e.g., a framework gotcha, an API design pattern). Project-specific knowledge stays in the project's `docs/learnings/` files.

### Internal References (`_shared/`)

Not invoked directly — used by other skills as shared reference docs.

**Global** (`commands/_shared/`):

| File | Purpose |
|------|---------|
| `corpus-cross-reference.md` | Procedure for loading and assessing content against existing skills/learnings |

**Git** (`commands/git/_shared/`):

| File | Purpose |
|------|---------|
| `platform-detection.md` | GitHub vs GitLab detection logic |

**Parallel Plan** (`commands/parallel-plan/_shared/`):

| File | Purpose |
|------|---------|
| `agent-prompting.md` | Best practices for crafting subagent prompts |
