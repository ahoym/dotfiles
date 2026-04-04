Reference file management in skills — @ references, conditional loading, templates, deduplication, and variable continuity.
- **Keywords:** @ reference, conditional load, reference file, template, skill reference, lazy load, eager load, three learnings locations, variable continuity
- **Related:** none

---

## Preserve Reference Style During Migrations

When migrating file paths (e.g., relocating shared references), preserve each skill's original reference style rather than normalizing all references to a single style:

- If a skill used `@_shared/file.md` (auto-include directive), update to `@~/.claude/skill-reference/file.md`
- If a skill used `` `~/.claude/commands/.../file.md` `` (bare path in backticks), update to `` `~/.claude/skill-reference/file.md` ``

Adding `@` to files that previously used bare paths changes behavior (auto-include vs manual read instruction). Only update the path portion, not the reference mechanism.

## `@` References in Skills

`@` references in SKILL.md eagerly load content into context when the skill is invoked. Every `@` reference adds to the skill's token cost on every invocation.

**When to use `@`**: Small, always-needed references (< 50 lines) used on every invocation. Don't add descriptions after `@` paths — the content is auto-inlined and already visible. Keep descriptions only for conditional references.

**When to use conditional (backtick) references**: Larger files or files only needed in specific branches. Wrap filenames in backticks to visually distinguish from `@` references. Add a description explaining *when* to load:

```markdown
## Reference Files
- @./reply-templates.md

## Reference Files (conditional — read only when needed)
- `lgtm-verification.md` — Read only when LGTM comment detected
```

Then in the step itself, explicitly instruct: "Read `template.md` from the skill's base directory."

**Ordering**: List `@` references first, conditional references below. Makes loading behavior scannable at a glance.

**Path resolution**: Use `@filename.md` (skill-directory-relative) or `@~/.claude/...` paths. `@./` relative paths may have resolution issues. Always add explicit read instructions as a defensive backup — active reads engage more deliberately than passively injected context.

## Skill Description Optimization & Discoverability

The `description:` field serves double duty — documentation for the operator and a matching signal for the model. **Every** `.claude/commands/*.md` file should include `description` frontmatter — missing descriptions make skills invisible in the command picker.

**Optimize for searchability:** Use widely understood terms (no internal jargon), include action verbs, use standard dev workflow terminology, list key capabilities for multi-purpose skills.

**Add trigger phrases** when the skill name + functional description isn't enough for agent inference — e.g., opaque names or overlapping skills needing disambiguation. Cover common ways an operator might express the intent without naming the skill directly. Skip routing hints when the skill name already communicates intent or the functional description covers it.

## Subagent Prompts: Read Shared References Instead of Hardcoding

When a subagent prompt needs platform-specific commands (API calls, CLI syntax), have the subagent `Read` a shared reference file at runtime rather than hardcoding the commands inline. One extra tool call per subagent is cheap; maintaining duplicate command lists across orchestrator + subagent prompts is expensive when they inevitably drift.

## Body-Only Templates for Skill Reference Files

Template reference files should contain only message body content — not posting commands. See `routing-table.md` § "Skill References & Templates" for the full convention.

## Inline Critical Conditions — Don't Defer to Lazy-Loaded Files

When a skill step says "follow the logic in `<file>.md`," the agent may cache past the deferral entirely — especially during polling loops where efficiency pressure encourages skipping file reads. Critical branching conditions (e.g., "check commits AND replies AND reviews before skipping") must be inlined in the main SKILL.md, not deferred to a reference file. Use the reference file for detailed procedures, but state the branching conditions where they're evaluated.

The tension: "prefer offset+limit reads, don't re-read files" (efficiency) vs "follow this file's logic" (correctness). Inlining the conditions resolves this — the agent can cache the detailed procedures while still seeing the decision criteria.

## Inline Critical-Path Commands, Keep Behavioral Guidance in References

Reference files containing commands that must be executed precisely (API calls, CLI syntax, fetch patterns) get ignored or partially applied intermittently — the agent may cache past the "read this file" instruction or load it but not follow it. This causes silent skill failures.

**Hybrid pattern:** Inline critical-path commands directly in SKILL.md instruction steps. Keep behavioral guidance (edge cases, tone, conventions, reply templates) in external references — partial application of behavioral guidance is tolerable; partial application of commands is not.

This refines "Inline Critical Conditions" above: that section covers branching logic; this covers the commands themselves. Both share the root cause: reference file loading is a lossy step in skill execution.

**Exception to "Skill Reference Files Are Authoritative":** When a skill inlines commands from a reference file for execution reliability, the skill's inline copy is the authoritative version for that skill. The reference file remains authoritative for *other consumers* and for maintenance (update the reference, then propagate to inlined copies). Add a "Commands Referenced from External Files" section at the bottom of SKILL.md for commands needed by conditional reference files (edge cases, LGTM verification) that can't be inlined into the main steps.

## Skill Reference Files Are Authoritative — Deduplicate from Skills

`skill-references/*.md` files are the single source of truth for shared patterns consumed by multiple skills. When skills grow and absorb reference content into their SKILL.md, the duplication should be removed from the *skill*, not the reference. The reference file stays authoritative; skills reference it. (See exception above for critical-path command inlining.)

During curation, when a skill section duplicates a reference file section, replace the skill's inline content with a pointer (e.g., "See `agent-prompting.md` § Git Workflow"). This keeps skills lean and prevents the same content from fragmenting across multiple consuming skills.

## Re-Read Templates at Point of Use, Not Ahead of Time

When a skill step says "read template X and use it verbatim," read the template immediately before that step — not minutes earlier as pre-work. Stale context causes improvisation: the agent fills in values from memory rather than from the template's prescriptive instructions, missing critical details like staging directories or routing rules. The longer the gap between reading and using, the more likely the agent substitutes its own assumptions.

## Explicit Variable Continuity Across Skill Steps

Multi-step skills should explicitly name variables when data flows between steps. E.g., "Store as `FILES_TO_EXTRACT`" in step 3, then "For each file in `FILES_TO_EXTRACT`" in step 7. Without this, later steps become ambiguous — "add the files" vs "add `FILES_TO_EXTRACT`." Named variables create a traceable data flow through the skill.

## Runtime Instructions Belong at Point of Use

Instructions that affect agent behavior during skill execution (e.g., "use templates verbatim", "don't simplify commands") must live where the agent reads them at runtime — in the template file, reference file, or SKILL.md itself. Putting them in learnings files only helps during authoring/curation sessions, not during execution. The test: "will the agent see this when it matters?"

## Skills Must Search All Three Learnings Locations

Skills that glob learnings for domain context should search all three locations: `~/.claude/learnings/` (global), `~/.claude/learnings-private/` (private), and `docs/learnings/` (project-local). Missing a location means the skill can't ground its responses in available knowledge. This mirrors the learnings search protocol in `context-aware-learnings.md`.

## When to Extract Skill References

The signal to extract shared logic into `skill-references/` is **having to make the same change in two skills** — not a stability analysis of the shared code. If the patterns are still evolving, that's fine — evolving in one place is cheaper than evolving in two. Organize shared references topically (sections skills read selectively) rather than procedurally (step numbers that couple to consumer skills).

## Fix Drift by Deleting, Not Correcting

When a consuming file restates shared reference logic and the restatement has drifted (wrong values, missing fields, outdated data model), delete the inline restatement entirely — don't fix it in place. Fixing preserves the drift surface; deleting eliminates it. Replace with a single-line deferral: "classify per the shared reference and apply its actions." This applies to both skill files consuming `skill-references/` and mode files consuming classification/criteria references.

## Sibling Cross-References Are Drift Risks

When skill A's reference file says "same criteria as skill B's reference file," that's a coupling that silently breaks when B evolves. The fix: extract the shared criteria into `skill-references/` and have both skills consume it. The signal is any phrase like "same as," "same criteria as," or "see `<other-skill>/`" pointing at a sibling skill's internals rather than a shared reference.

## Cross-Refs

No cross-cluster references.
