---
name: set-persona
description: "Activate a named domain persona to set focus, priorities, and gotchas for the current session."
argument-hint: "[persona-name]"
allowed-tools:
  - Read
---

# Set Persona

Activate a domain-specific lens that shapes how you approach code in this session.

## Usage

- `/set-persona <name>` — Load a persona by name
- `/set-persona` — List available personas

## Instructions

1. Parse `$ARGUMENTS` for the persona name.

2. **If no argument provided**:
   - Glob for personas in both locations (see below)
   - List available personas by filename (without extension)
   - Ask which one to activate

3. **If argument provided**:
   - Look for the persona file in this order:
     1. `.claude/personas/<name>.md` in the current project (project-specific override)
     2. `.claude/commands/set-persona/<name>.md` in dotfiles (shared/common)
   - If not found in either location, report what's available and ask the user to pick

4. **Adopt the persona**:
   - Read the persona file contents
   - After reading the persona file, check for an `## Extends: <name>` heading
   - If found, resolve and read the parent persona using the same lookup order (project-local → dotfiles)
   - Load the parent first as foundational context, then layer the child persona on top
   - Child sections supplement the parent — they don't replace them
   - Only one level of extension is supported (no chaining)
   - Confirm activation with a one-line summary of what you're now focused on
   - If the persona extends a parent, mention both: "Activated **child** (extends **parent**)"
   - Apply the priorities and focus areas from that point forward in the session

## Prerequisites

For prompt-free execution, add these allow patterns to `~/.claude/settings.local.json`:

```json
"Read(~/.claude/commands/set-persona/**)",
"Read(.claude/personas/**)"
```

## Important Notes

- Personas set focus and priorities — they don't restrict what you can do
- A persona doesn't replace project CLAUDE.md context, it layers on top
- Project-local personas take precedence over shared ones with the same name
- If the user says something that conflicts with the persona's priorities, the user wins
- Personas can extend one parent via `## Extends: <name>` — the parent is loaded first, then the child layers on top
- Only single-level extension is supported (a parent cannot itself extend another persona)
