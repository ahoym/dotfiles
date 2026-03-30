# Subagent Patterns

Universal patterns for skills that launch parallel or sequential subagents.

## Verify Output Before Acting

When acting on subagent output (presenting to the operator, making edits, merging, recommending), spot-check the key claim first.

**Why:** Subagent output sounds authoritative — structured, detailed, confident — but subagents can misread files, confuse labels, or draw wrong conclusions. Passing unverified output through amplifies errors with your own credibility.

**When to verify:**
- The finding would trigger an action (merge, edit, recommendation)
- The finding is directional ("A has X, B doesn't") — especially error-prone
- The finding contradicts prior understanding or seems surprising

**How:** Read the relevant file/section and confirm the key claim. One targeted read is enough — don't redo the full analysis.

**Skip when:** Output is purely informational and won't be acted on without further investigation.

## Write Output to Intermediate Files

When a skill launches multiple agents and needs to synthesize their outputs, agents should write results to files on disk rather than returning everything to the orchestrator.

**Why:** The orchestrator must hold ALL agent outputs in context simultaneously for synthesis. With 5+ agents returning substantial outputs, this exhausts the context window mid-synthesis. When context compresses, detail is lost.

**Pattern:**
- Agents write full findings to output files (e.g., `docs/analysis/<dimension>.md`)
- Agents return only a 2-3 sentence summary to the orchestrator
- A separate synthesis step reads from the output files with a clean context

## Use Structured Templates Over Hard Size Limits

Instead of hard output size limits (which LLMs can't reliably count), use structured templates to naturally constrain agent output.

**Why hard limits fail:** "Keep under 300 lines" produces anywhere from 150 to 500. Truncation risks cutting findings mid-thought. Hard limits on large repos force agents to silently drop important findings.

**Pattern:**
- Give each agent a template with named sections, bullet-point format, and table structures
- Add a soft guideline: "Aim for 150-250 lines. Prioritize the most significant findings."
- The template structure itself limits verbosity — bullets force conciseness, named sections prevent rambling
