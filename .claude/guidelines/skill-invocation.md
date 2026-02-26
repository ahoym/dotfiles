# Skill Invocation Guidelines

## Always use the Skill tool for slash commands

When the user writes `/skill-name` (e.g., `/git:create-pr`, `/commit`, `/session-retro`), invoke it via the Skill tool. Never manually perform the skill's actions inline — even if you know how to do it yourself. Skills standardize processes into repeatable loops that can be refined, automated, and taught to other agents. Bypassing the skill breaks the loop.

This applies even when the slash command is combined with other instructions (e.g., "commit and `/git:create-pr`"). Handle the non-skill part yourself, then invoke the Skill tool for the slash command.
