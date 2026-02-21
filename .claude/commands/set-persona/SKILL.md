---
description: Set domain focus and priorities for the current session
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
   - Confirm activation with a one-line summary of what you're now focused on
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
