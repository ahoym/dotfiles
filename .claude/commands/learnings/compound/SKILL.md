---
description: Capture session learnings and save to skills, guidelines, or reference docs
---

# Compound Learnings

Save new patterns and learnings from the current session into global skills, guidelines, or learnings under `~/.claude/`.

## Usage

- `/learnings:compound` - Capture learnings from current session

## Reference Files (conditional — read only when needed)

- `content-type-decisions.md` — Read if categorization is ambiguous
- `skill-template.md` — Read only when a Skill-type learning is selected
- `writing-best-practices.md` — Read only when a Skill-type learning is selected
- `skill-authoring.md` — Read only when a Skill-type learning is selected
- `iterative-loop-design.md` — Read only when learning involves iterative/loop patterns
- `public-release-review.md` — Read when learning will be shared publicly or across repos

## Instructions

1. **Identify learnings from current session**:
   - Review the conversation for new patterns, processes, or guidelines discovered
   - List each learning with a brief description
   - Categorize using this decision tree:
     - Command with clear, repeatable steps? → **Skill**
     - Changes behavior or approach? → **Guideline**
     - Reference info, patterns, or examples? → **Learning**

2. **Display learnings for selection**:

   **ALWAYS use a markdown table** — never use section breaks, horizontal rules, or prose paragraphs to list learnings.

   ```
   Identified learnings from this session:

   | # | Learning | Type | Target File | Utility |
   |---|----------|------|-------------|---------|
   | 1 | LGTM verification process | Skill | commands/address-pr-review/SKILL.md | High - novel project pattern |
   | 2 | Co-authorship in PR replies | Guideline | guidelines/git-workflow.md | Low - already documented |
   | 3 | SessionEnd hook configuration | Learning | learnings/ci-cd.md | High - useful reference |
   ```

   Target files are relative to `~/.claude/`.

   **Utility ratings** (self-assessment of value to Claude):
   - **High** - Novel pattern I wouldn't know without documenting
   - **Medium** - Useful reminder, but I could rediscover if needed
   - **Low** - Standard knowledge or already documented (shown for transparency)

   Use `AskUserQuestion` with multi-select to let user choose which learnings to capture.
   **Include the utility rating in each option's `description` field** (e.g., `"Utility: High — novel pattern I wouldn't know without documenting"`). This ensures utility is visible in the interactive selection widget, since the markdown table above may be clipped by the terminal UI.
   Store selected items as `SELECTED_LEARNINGS`.

   **Do NOT proceed until user selects.** If no learnings selected, inform user and exit.

3. **Write learnings to files**:
   - If any Skill-type learning is selected: read `skill-template.md`, `writing-best-practices.md`, and `skill-authoring.md` first
   - For each item in `SELECTED_LEARNINGS`:
     - Read the target file (`~/.claude/<relative-path>`) to check if it exists
     - **Existing file**: use Edit to append new sections (find a unique string near the end, replace with itself + new content)
     - **New file** (Read returned error): use Write with full content
   - File placement rules:
     - **Skills** → `~/.claude/commands/<skill-name>/SKILL.md`
     - **Guidelines** → `~/.claude/guidelines/<guideline-name>.md`
     - **Learnings** → `~/.claude/learnings/<topic>.md`

4. **Verify and report**:
   - Read back each written file to confirm content was saved correctly
   - Output a summary:
     ```
     Updated files:
     - <path> — <what was added> (Utility: <High/Medium/Low>)

     Wrote N learnings to ~/.claude/.
     ```

## Prerequisites

For prompt-free execution, add these allow patterns to **user-level** `~/.claude/settings.local.json`:

```json
"Read(~/.claude/commands/**)",
"Read(~/.claude/learnings/**)",
"Read(~/.claude/guidelines/**)",
"Write(~/.claude/learnings/**)",
"Write(~/.claude/commands/**)",
"Write(~/.claude/guidelines/**)",
"Edit(~/.claude/learnings/**)",
"Edit(~/.claude/commands/**)",
"Edit(~/.claude/guidelines/**)"
```

## Important Notes

- Prefer updating existing files over creating new ones
- Keep learnings atomic — one concept per section
- **Type selection when unsure**: Learning > Guideline > Skill (least to most structured)
- Be honest in utility self-assessments
