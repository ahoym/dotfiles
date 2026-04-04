---
name: set-persona
description: "Activate a named domain persona to set focus, priorities, and gotchas for the current session."
argument-hint: "[persona-name]"
allowed-tools:
  - Read
  - Glob
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
   - If not found in either location, report what's available and ask the operator to pick

4. **Adopt the persona**:
   - Read the persona file contents
   - After reading the persona file, check for an `## Extends: <name>` or `## Extends: <name1>, <name2>` heading
   - If found, parse the comma-separated list of parent names
   - Resolve and read each parent persona in declaration order using the same lookup order (project-local → dotfiles)
   - Load parents in order as foundational context, then layer the child persona on top
   - Child sections supplement the parents — they don't replace them
   - Only one level of extension is supported (no chaining — parents cannot themselves extend)
   - Confirm activation with a one-line summary of what you're now focused on
   - If the persona extends parents, mention all: "Activated **child** (extends **parent1**, **parent2**)"
   - Apply the priorities and focus areas from that point forward in the session

5. **Load proactive knowledge**:
   - Scan adopted persona (and parent if extended) for `## Proactive loads` sections
   - Each listed path uses the logical form `learnings/...` (no `~/.claude/` prefix)
   - Resolve each path by searching these directories in order, loading the first match:
     1. `~/.claude/learnings-team/learnings/` — shared team learnings (highest precedence)
     2. `docs/learnings/` — repo-local learnings
     3. `~/.claude/learnings/` — personal learnings
     4. `~/.claude/learnings-private/` — private learnings
   - If a file doesn't exist in any location, warn but don't fail
   - Announce: "📚 Loaded proactive gotchas: `xrpl-gotchas.md`, `react-frontend-gotchas.md`"
   - Keep this content active throughout the session

6. **Resolve cross-refs on demand**:
   - When loading a `## Cross-Refs` entry during the session, apply the same multi-source resolution as proactive loads

## Prerequisites

For prompt-free execution, add these allow patterns to `~/.claude/settings.local.json`:

```json
"Read(~/.claude/commands/set-persona/**)",
"Read(.claude/personas/**)",
"Read(~/.claude/learnings/**)",
"Read(~/.claude/learnings-team/learnings/**)"
```

## Important Notes

- Personas set focus and priorities — they don't restrict what you can do
- A persona doesn't replace project CLAUDE.md context, it layers on top
- Project-local personas take precedence over shared ones with the same name
- If the operator says something that conflicts with the persona's priorities, the operator wins
- Personas can extend one or more parents via `## Extends: <name>` or `## Extends: <name1>, <name2>` — parents are loaded in declaration order, then the child layers on top
- Only single-level extension is supported (parents cannot themselves extend another persona)
