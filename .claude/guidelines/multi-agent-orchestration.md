# Multi-Agent Orchestration

## Use Verbatim Templates for Subagent Prompts

When spawning multiple subagents for the same task type (e.g., per-item extractors), use the prompt template **verbatim** — fill in placeholders only. Do not abbreviate, paraphrase, or add ad-hoc per-instance instructions.

**Why**: Orchestrators drift when given freedom to rephrase. Each subagent ends up with slightly different instructions, leading to inconsistent data fetching commands, output formats, and coverage depth. The user can't reason about what each agent did because they all did different things.

**Pattern**:
- Store the template in a file (e.g., `extractor-prompt.md`)
- Include standardized tool commands with exact flags and jq filters
- The only per-instance variation is the placeholder values themselves
- Add orchestrator-only instructions above a separator line (not passed to subagents)
