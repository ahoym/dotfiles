# Background Agent Steps

Steps for the background Task agent launched by the compound-learnings orchestrator.

## Aliases

- `FILE_IO` = the file I/O command provided by the orchestrator (e.g., `bash ~/.claude/commands/compound-learnings/file-io.sh`). IMPORTANT: use `~` literally — do NOT expand to an absolute path, so the command matches the permission pattern in settings.

Use this as shorthand in the instructions below. In actual commands, expand to the full value.

## Step 1: Check existing files

For each item in `SELECTED_LEARNINGS`, check if the target file already exists:

```bash
$FILE_IO read <relative-path>
```

If the exit code is non-zero, the file is new — write from scratch. If it succeeds, merge new content into the existing content.

You can also list existing files to find the right home:

```bash
$FILE_IO list learnings
$FILE_IO list commands
$FILE_IO list guidelines
```

## Step 2: Write files

For each item in `SELECTED_LEARNINGS`:

- **New file** (read returned non-zero): use `write` with full content
- **Existing file**: prefer `append` to add new sections without reproducing existing content

```bash
# New file:
$FILE_IO write <relative-path> <<'ENDOFLEARNINGFILE'
# Full file content here
ENDOFLEARNINGFILE

# Existing file — append new section only:
$FILE_IO append <relative-path> <<'ENDOFLEARNINGFILE'

## New Section Title
New content here
ENDOFLEARNINGFILE
```

**File placement rules:**
- **Skills** → `commands/<skill-name>/SKILL.md`
- **Guidelines** → `guidelines/<guideline-name>.md`
- **Learnings** → `learnings/<topic>.md`

All paths are relative to `~/.claude/`.

> **WARNING**: Do NOT use Write/Edit tools — subagents may not be able to write to `~/.claude/` paths outside the project sandbox. All file operations MUST go through the file-io script.

> **HEREDOC NOTE**: Use a unique delimiter like `ENDOFLEARNINGFILE` — avoid `CONTENT`, `EOF`, or common words that may appear in the file body. The heredoc redirect (`<<'...'`) must keep `bash` as the first word of the command so it matches the pre-approved permission pattern.

## Step 3: Verify

Read back each written file to confirm content was saved correctly:

```bash
$FILE_IO read <relative-path>
```

## Step 4: Report

Output a report in this exact format:

```
Updated files:
- <path> — <what was added> (Utility: <High/Medium/Low>)

Wrote N learnings to ~/.claude/.
```

## Error Recovery

- **Heredoc collision**: If a write fails because the delimiter appears in the file body, retry with a different unique delimiter (e.g., `LEARNINGEOF_42`).
- **File doesn't exist**: If `read` returns non-zero, the file is new — write from scratch (do not treat as an error).
