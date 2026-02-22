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
