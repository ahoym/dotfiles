# Multi-Agent Patterns

## Agents Should Write Output to Intermediate Files

When a skill launches multiple agents in parallel and needs to synthesize their outputs, agents should write their results to intermediate files on disk rather than returning everything to the orchestrator.

**Why:**
- Agent outputs can be very large (each agent may read hundreds of files and produce detailed reports)
- The orchestrator must hold ALL agent outputs in context simultaneously for synthesis
- With 7 agents returning substantial outputs, this easily exhausts the context window mid-synthesis
- When context compresses, the synthesis works from a summary rather than the full data — detail is lost

**Pattern:**
- Agents write full findings to output files (e.g., `docs/learnings/<dimension>.md`)
- Agents return only a 2-3 sentence summary to the orchestrator (for success/failure tracking)
- Orchestrator stays lightweight — short summaries, not full reports
- A separate synthesis step (or separate invocation) reads from the output files with a clean context

**Discovered from:** Running `/explore-repo` on transfer-server — 7 agents completed successfully but their combined outputs exhausted the orchestrator's context window before synthesis could finish.

## Synthesis Should Run in a Separate Invocation

When combining outputs from multiple agents into a unified document, synthesis should happen in a fresh context — either a separate agent or a separate skill invocation — rather than in the orchestrator that launched the agents.

**Why:**
- The orchestrator's context is already partially consumed by the skill prompt, project context, and agent launch coordination
- A fresh context gets full budget dedicated to reading output files and writing the final synthesis
- If context compression hits during synthesis, you're synthesizing from lossy summaries of findings rather than the findings themselves — quality degrades silently
- If synthesis fails or produces poor results, it can be re-run without re-running all exploration agents

**Pattern (preferred — same skill, separate invocation):**
1. Exploration agents write to output files (see above)
2. Skill detects mode via file existence — first run scans, second run synthesizes (see Stateful Mode Detection in skill-design.md)
3. Synthesis invocation reads each file with a fully clean context, cross-references, writes final output

**Alternative (synthesis as sub-agent):**
1. Exploration agents write to intermediate files
2. Orchestrator launches a synthesis agent with file paths and output format requirements
3. Works but the orchestrator still needs enough context to coordinate

**Implication:** These two patterns together break the "7 agents → 1 orchestrator" bottleneck entirely. The orchestrator becomes a lightweight coordinator rather than a data funnel.

## Agent Output Files as First-Class Documentation

When agents write intermediate files, those files can be standalone useful documentation — not just pipeline artifacts to delete after synthesis.

**Pattern:**
- Name agent output files descriptively (e.g., `data-model.md`, not `_scan-data-model.md`)
- Structure agent output with a consistent template (sections, bullet points, file paths)
- Include scan metadata in a header comment (agent name, commit, branch, date)
- Git-track the files — they persist across sessions and inform future scans

**Benefits:**
- A developer can read `integrations.md` directly without needing the synthesized overview
- The synthesized overview references domain files for deeper context, creating a natural drill-down
- Staleness detection (commit hash comparison) enables incremental re-scanning

**Discovered from:** Redesigning `/explore-repo` — realized the `_scan-` prefix and deletion after synthesis was treating genuinely useful docs as throwaway intermediates.

## Don't Delegate Directional Comparisons to Subagents

When comparing two versions of a file where directionality matters (source vs target, old vs new, before vs after), do the comparison yourself — don't delegate to subagents.

**Why:** Subagents receive two file paths with labels, but can confuse which is which — especially when paths are similar (e.g., two repos with overlapping directory structures). If the agent swaps source and target, it reports the exact opposite of reality, and the error is hard to catch because the analysis *sounds* correct.

**When this applies:**
- quantum-tunnel-claudes: comparing source repo files against target repo files
- Any diff/merge workflow where "which side has X" is the key question
- PR review where "old vs new" determines the recommendation

**What's safe to delegate:** Non-directional analysis (e.g., "does this file contain X?", "how many sections does this file have?") where swapping inputs doesn't change the answer.

**Discovered from:** quantum-tunnel-claudes delegated structural comparison of `execute-parallel-plan/SKILL.md` to an explore agent. The agent reported the target's fresh-eyes review framework was in the source, leading to offering to merge content that was already in the target.

## Verify Subagent Output Before Acting On It

When you delegate research or analysis to a subagent and plan to act on the result (presenting findings to the user, making edits, offering to merge), spot-check the key claim before proceeding.

**Why:** Subagent output *sounds* authoritative — it's structured, detailed, and confident. But subagents can misread files, confuse labels, or draw wrong conclusions. If you pass their output through to the user without verification, you amplify the error with your own credibility.

**When to verify:**
- The subagent's finding would trigger an action (merge, edit, recommendation to user)
- The finding is directional (A has X, B doesn't) — these are especially error-prone
- The finding contradicts your prior understanding or seems surprising

**How to verify:** Read the relevant file/section yourself and confirm the key claim. One targeted read is enough — you don't need to redo the full analysis.

**When to skip:** The subagent's output is purely informational (e.g., "how many files match this pattern?") and you won't act on it without further investigation.

**Discovered from:** quantum-tunnel-claudes accepted an explore agent's claim that the source had a fresh-eyes review framework the target lacked — the opposite was true. A single file read would have caught it.

## Structured Templates as Natural Size Constraints

Instead of hard output size limits (which LLMs can't reliably count or enforce), use structured templates to naturally constrain agent output length.

**Why hard limits don't work:**
- "Keep output under 300 lines" might produce 150 or 500
- Technical enforcement (truncation) risks cutting off findings mid-thought
- Hard limits on large repos force agents to silently drop important findings

**Pattern:**
- Give each agent a template with named sections, bullet-point format, and table structures
- Add a soft guideline: "Aim for 150-250 lines. Prioritize the most architecturally significant findings."
- The template structure itself limits verbosity — bullets force conciseness, named sections prevent rambling
- If an agent genuinely needs 400 lines for a complex domain, that's fine — the synthesizer can handle it

**Discovered from:** Discussing output size limits for `/explore-repo` agents — concluded that templates + soft guidelines give consistent, digestible output without losing signal from large repos.

