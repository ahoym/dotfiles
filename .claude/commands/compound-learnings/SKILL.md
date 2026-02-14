---
description: Capture session learnings and save to skills, guidelines, or reference docs
---

# Compound Learnings

Save new patterns and learnings from the current session into global skills, guidelines, or learnings under `~/.claude/`.

## Usage

- `/compound-learnings` - Capture learnings from current session

## Prerequisites

Add this to your project's `.claude/settings.local.json` for background execution:

- `Bash(bash ~/.claude/commands/compound-learnings/file-io.sh:*)`

## Reference Files (conditional — read only when needed)

- `content-type-decisions.md` — Read if categorization is ambiguous
- `skill-template.md` — Read only when a Skill-type learning is selected
- `writing-best-practices.md` — Read only when a Skill-type learning is selected
- `iterative-loop-design.md` — Read only when learning involves iterative/loop patterns
- `background-agent-steps.md` — Read in step 3 to pass to background agent

## Instructions

1. **Identify learnings from current session**:
   - Review the conversation for new patterns, processes, or guidelines discovered
   - List each learning with a brief description
   - Categorize using this decision tree:
     - Command with clear, repeatable steps? → **Skill**
     - Changes behavior or approach? → **Guideline**
     - Reference info, patterns, or examples? → **Learning**

2. **Display learnings for selection**:
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

3. **Launch background agent**:
   - Read `background-agent-steps.md` and include its full content in the Task prompt
   - If any Skill-type learning is selected: also read `skill-template.md` and `writing-best-practices.md`, include relevant excerpts in the prompt
   - Set the `FILE_IO` value to `bash ~/.claude/commands/compound-learnings/file-io.sh` — use the `~` literal so it matches the permission pattern in settings. Do NOT resolve to an absolute path.
   - Provide the background agent with:
     - `SELECTED_LEARNINGS` (descriptions, types, target files, content to write)
     - The `FILE_IO` command string (using `~`, not absolute path)
     - Enough session context to write the learning content
   - Launch with `run_in_background: true`
   - **Do NOT call `TaskOutput` with `block: true` after launching.** Inform the user the agent is running in the background and continue the conversation. The task notification will arrive automatically when the agent finishes.

## Important Notes

- **Plan mode conflict**: The background agent cannot execute bash commands while plan mode is active. If plan mode is on when this skill is invoked, exit plan mode first before launching the background agent.
- **Background execution**: After learning selection, all work runs via background-agent-steps.md in a Task agent
- Prefer updating existing files over creating new ones
- Keep learnings atomic — one concept per section
- **Type selection when unsure**: Learning > Guideline > Skill (least to most structured)
- Be honest in utility self-assessments
