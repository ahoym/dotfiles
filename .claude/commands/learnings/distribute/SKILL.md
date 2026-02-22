---
description: "Distribute global learnings and guidelines from ~/.claude/ into the current project's .claude/ directory."
---

# Distribute Learnings

Copy or merge global learnings and guidelines from `~/.claude/` into the current project's `.claude/` directory. Skills are excluded — only guidelines and learnings are distributed.

## Usage

- `/learnings:distribute` - Distribute global learnings/guidelines to current project

## Instructions

1. **Detect project root**:
   - Run `git rev-parse --show-toplevel` to find the project root
   - If not a git repo, use the current working directory
   - Store as `PROJECT_ROOT`
   - Verify `<PROJECT_ROOT>/.claude/` exists; if not, note it will be created

2. **Understand the project context**:
   - Read `<PROJECT_ROOT>/CLAUDE.md` if it exists — this is the primary source for project context, stack, conventions, and architecture
   - Scan the project root for stack indicators: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `pom.xml`, `Makefile`, `docker-compose.yml`, etc.
   - Read a sample of these files (just enough to identify language, framework, tooling — don't deep-read everything)
   - Note the project's directory structure (top-level `ls`)
   - Read existing `<PROJECT_ROOT>/.claude/` config if present (existing guidelines/learnings) to understand what's already established
   - Store this as `PROJECT_CONTEXT` — used for relevance assessment in the next step

3. **Inventory and assess global items**:
   - Use Glob to list all files in `~/.claude/guidelines/**` and `~/.claude/learnings/**`
   - Use Glob to list all files in `<PROJECT_ROOT>/.claude/guidelines/**` and `<PROJECT_ROOT>/.claude/learnings/**`
   - For each global file:
     - Determine its relative path (e.g., `guidelines/git-workflow.md`, `learnings/ci-cd.md`)
     - Read the file content
     - Check if the same relative path exists in the project's `.claude/`
   - Assign a **sync status**:
     - **New** — file does not exist in the project
     - **Differs** — file exists in both but content differs (global has updates)
     - **Up to date** — file exists in both with identical content
   - Assess **relevance** to the project using `PROJECT_CONTEXT`:
     - **Relevant** — content directly applies to this project's stack, patterns, or workflows (e.g., a TypeScript guideline for a TypeScript project)
     - **General** — content is stack-agnostic and broadly applicable (e.g., git workflow conventions, communication style)
     - **Not relevant** — content is specific to a different stack or domain (e.g., Rust patterns for a Python project)
   - Skip items marked "Up to date" from the selection table
   - Skip items marked "Not relevant" from the selection table (mention counts of both below the table)

4. **Display items for selection**:

   **ALWAYS use a markdown table** — never use prose paragraphs to list items.

   ```
   Available for distribution to <PROJECT_ROOT>:

   | # | File | Type | Status | Relevance | Summary |
   |---|------|------|--------|-----------|---------|
   | 1 | guidelines/git-workflow.md | Guideline | New | General | Git commit and PR conventions |
   | 2 | learnings/ci-cd.md | Learning | Differs | Relevant | CI pipeline patterns (global has new sections) |
   | 3 | guidelines/testing.md | Guideline | New | Relevant | Testing conventions and patterns |

   N items already up to date (skipped). M items not relevant to this project (skipped).
   ```

   - **Summary** column: brief description of the file's content. For "Differs" items, note what's new in the global version.

   Use `AskUserQuestion` with multi-select to let user choose which items to distribute.
   **Include the status and relevance in each option's `description` field** (e.g., `"New, Relevant — Git commit and PR conventions"` or `"Differs, General — global has new sections on rebase workflow"`).
   Store selected items as `SELECTED_ITEMS`.

   **Do NOT proceed until user selects.** If no items selected, inform user and exit.

5. **Distribute selected items**:
   - For each item in `SELECTED_ITEMS`:
     - **New items**: Read the global file and Write it to `<PROJECT_ROOT>/.claude/<relative-path>`
     - **Differs items**:
       - Read both the global and project versions
       - Merge intelligently: add new sections from global that don't exist in the project version, preserve any project-specific content that was added locally
       - If a section exists in both but with different content, prefer the global version (it's the source of truth for this flow)
       - Use Edit on the project file if it exists, or Write if starting fresh
   - Create any necessary parent directories (e.g., `<PROJECT_ROOT>/.claude/learnings/`) if they don't exist

6. **Verify and report**:
   - Read back each written/updated file to confirm content was saved correctly
   - Output a summary:
     ```
     Distributed to <PROJECT_ROOT>/.claude/:
     - guidelines/git-workflow.md — copied (new)
     - learnings/ci-cd.md — merged (2 new sections added)

     Distributed N items. M items were already up to date.
     ```

## Prerequisites

For prompt-free execution, add these allow patterns to **project-level** `.claude/settings.local.json`:

```json
"Read(.claude/guidelines/**)",
"Read(.claude/learnings/**)",
"Write(.claude/guidelines/**)",
"Write(.claude/learnings/**)",
"Edit(.claude/guidelines/**)",
"Edit(.claude/learnings/**)"
```

And ensure these are in your **user-level** `~/.claude/settings.local.json`:

```json
"Read(~/.claude/guidelines/**)",
"Read(~/.claude/learnings/**)"
```

## Important Notes

- Skills (`~/.claude/commands/`) are excluded — only guidelines and learnings are distributed
- For "Differs" items, the merge preserves project-local additions while incorporating global updates
- This creates copies, not references — project copies will not auto-update when the global version changes
- Run this periodically or when onboarding a new project to sync relevant global knowledge
