# Skill Invocation Guidelines

## Always use the Skill tool for slash commands

When the user writes `/skill-name` (e.g., `/git:create-request`, `/commit`, `/session-retro`), invoke it via the Skill tool. Never manually perform the skill's actions inline — even if you know how to do it yourself. Skills standardize processes into repeatable loops that can be refined, automated, and taught to other agents. Bypassing the skill breaks the loop.

This applies even when the slash command is combined with other instructions (e.g., "commit and `/git:create-request`"). Handle the non-skill part yourself, then invoke the Skill tool for the slash command.

## Don't ask permission to invoke skills within a skill's instructions

When a skill's instructions say "invoke `/other-skill`", just do it — don't ask the user "ready for the next step?" or "should I run this?" first. The skill's instructions are the authorization. This especially applies to orchestrating skills like `/session-retro` that invoke `/learnings:compound` as a defined step. If the user has already signaled they're ready to proceed, that's the green light for everything the current step entails.
