# Skill Invocation Guidelines

## Always use the Skill tool for slash commands

When the user writes `/skill-name` (e.g., `/git:create-request`, `/commit`, `/session-retro`), invoke it via the Skill tool. Never manually perform the skill's actions inline — even if you know how to do it yourself. Skills standardize processes into repeatable loops that can be refined, automated, and taught to other agents. Bypassing the skill breaks the loop.

This applies even when the slash command is combined with other instructions (e.g., "commit and `/git:create-request`"). Handle the non-skill part yourself, then invoke the Skill tool for the slash command.

When the Skill tool rejects with `disable-model-invocation`, tell the user the skill can only be run as a slash command. Do NOT read the SKILL.md and follow its steps manually — that bypasses `allowed-tools` constraints and consistency guarantees.

## Follow skill steps in order — don't anchor on examples

When a skill has an explicit numbered step list, execute steps in sequence. Prerequisites and examples sections describe *what you'll need*, not *what to run first*. Detection/setup steps (platform detection, persona verification) always run before platform-specific commands — even when the examples make one platform look obvious.

**Why:** Anchoring on CLI tool names visible in prerequisites (e.g., `gh pr view`) before running platform detection caused a wrong-platform assumption — the repo was GitLab, not GitHub. The error was only caught after the command failed.

## Don't ask permission to invoke skills within a skill's instructions

When a skill's instructions say "invoke `/other-skill`", just do it — don't ask the user "ready for the next step?" or "should I run this?" first. The skill's instructions are the authorization. This especially applies to orchestrating skills like `/session-retro` that invoke `/learnings:compound` as a defined step. If the user has already signaled they're ready to proceed, that's the green light for everything the current step entails.

## Execute skill-classified routine decisions without re-asking

When a skill explicitly classifies a decision as routine ("auto-decide, don't prompt", "decide silently and surface the action taken"), execute the action immediately and report what was done — don't convert it into a question. The skill's decision framework IS the authorization; re-asking undermines the autonomy model and adds friction. Applies to conflict resolution directives, convergence calls, relaunch decisions, and any action the playbook classifies as routine. The reporting ("surface the action taken") is the operator's visibility, not a confirmation gate.

## Load reference files before acting on their content

When a skill step says to read a reference file, load it before proceeding — don't substitute training knowledge for documented templates. Reference files encode accumulated fixes that training recall misses.
