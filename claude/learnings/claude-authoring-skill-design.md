Skill authoring: $ARGUMENTS handling, disable-model-invocation for irreversible actions.
- **Keywords:** $ARGUMENTS, disable-model-invocation, skill design, irreversible, slash commands
- **Related:** ~/.claude/learnings/claude-authoring/skill-design.md

---

### $ARGUMENTS vs derived values in Claude Code skills

In skill files, `$ARGUMENTS` is the CLI-substituted value (replaced before the model sees the content). When a later phase requires a derived value (e.g., next version calculated from the argument), use descriptive placeholders like `<next-version>` to distinguish computed values from CLI-substituted ones. Mixing `$ARGUMENTS` for both raw input and derived values makes the skill harder to read and debug — the reader can't tell which values come from the CLI and which are computed during execution.

### `disable-model-invocation: true` for irreversible skills

Skills that perform irreversible actions (publishing artifacts, creating tags, deploying to production) should use `disable-model-invocation: true` in frontmatter so they can only be run as explicit slash commands, not invoked by the model autonomously during a session. This is a safety guard — the model might determine that a release or publish action would fulfill the user's intent, but irreversible side effects should always require explicit human invocation. Enriches existing learning in skill-platform-portability.md by adding the "irreversible actions" heuristic for when to use the flag.
