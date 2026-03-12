# Skill Design Patterns

> Platform features, cross-platform compatibility, plugins, and agent definitions → `skill-platform-portability.md`

## Gap vs Inconsistency Boundary

When a skill identifies documentation issues, define "gaps" and "inconsistencies" with a clear, non-overlapping boundary:

- **Gap** — Docs don't mention something at all. The code has a pattern/feature/system completely absent from documentation.
- **Inconsistency** — Docs exist but contradict the code. The doc says X, the code does Y.

**Pattern:** In skill instructions, include a preamble for each category:
- Gaps section: "Do NOT include items where docs exist but contradict the code; those belong in inconsistencies."
- Inconsistencies section: "Do NOT duplicate items from the gaps section."

## Exploration Skills Should Default to Report-Only

Skills that analyze, explore, or audit a codebase should produce reports but NOT offer to apply fixes or edit documentation. Separating "understand" from "fix" keeps each phase focused, simplifies skill design (no edit logic or conflict handling), and lets users review findings before deciding what to act on.

**Pattern:**
- Skill produces output files and prints a console summary
- Skill ends — no `AskUserQuestion` for "which fixes to apply"
- If the user wants fixes, they initiate that as a separate task

## Stateful Mode Detection via File Existence

A single skill can operate in different modes across invocations by checking what output files already exist on disk, rather than requiring separate skills for each phase.

**Pattern:**
1. On invocation, glob for expected output files
2. For each file found, read its metadata header (commit hash, date) to check staleness
3. Determine mode based on file state:
   - Missing files → run the scan/generation phase for those files
   - All files present, no synthesized output → run synthesis
   - All present + synthesized, but stale → re-scan stale files
   - Everything current → nothing to do

One command to remember, fresh context per invocation, graceful degradation (if 3 of 7 agents fail, next run picks up only the missing 3), and incremental updates. For staleness detection beyond naive commit comparison, see `explore-repo.md` § Diff-Based Staleness Detection.

## Skills Should Self-Document Permission Needs

Skills that read or write files outside the project directory should include a **Prerequisites** section listing the exact `permissions.allow` patterns needed for prompt-free execution. Permission rule syntax is non-obvious (see `claude-code.md` § "Permission Rules" for details like `Read()` covering Glob/Grep).

**Pattern:** Add a `## Prerequisites` section to SKILL.md with a JSON snippet:
```markdown
## Prerequisites

For prompt-free execution, add these allow patterns to `~/.claude/settings.json`:

\```json
"Read(~/.claude/learnings/**)",
"Edit(~/.claude/learnings/**)"
\```
```

## Compose Skills, Don't Couple Them

When two skills share setup (e.g., locating a project, reading files) but diverge in purpose (one exploratory, one operational), keep them separate and composable. Duplicate the shared setup in each skill (~10 lines of instructions is fine) rather than making one depend on the other. Add a hint in the operational skill pointing to the exploratory one for users who need context first. Example: `/ralph:resume` mentions `/ralph:brief` but doesn't invoke it — the user composes them when needed.

## Merging Diverged Skills Across Repos

When two repos have independently evolved the same skill, merge by keeping unique features from both sides. Use the more complete version as the base, append unique sections from the other. For platform-specific commands (gh vs glab), parameterize via a shared reference file with detection logic and a mapping table. One codebase to maintain means no future drift.

## Skill Improvement: Fix and Assess In-Session

Apply skill improvements in the same session they surface — context fades across sessions. After running a skill, note what worked, what didn't, and prioritize: regression prevention >> efficiency; one-line fixes >> structural overhauls. Cap at 3-5 improvements. If a skill hits a bug mid-execution, fix immediately — scope to one constraint workaround per incident.

## AskUserQuestion Has a 4-Option Maximum

`AskUserQuestion` enforces `maxItems: 4` on the options array. This is a hard schema constraint — not configurable. Skills that present learnings, tasks, or choices to the user will fail at runtime if they try to offer >4 options.

**Workarounds (in order of preference):**
1. **Auto-save high-confidence items** — Remove them from the selection set entirely. Only prompt for uncertain items, which usually fit in 4 options.
2. **Group by theme** — Combine related items into a single option (e.g., "CI patterns (3 items)" instead of 3 separate options).
3. **Use free-text input** — Present a numbered table and let the user type "1,3,5" or "all" as a regular message instead of using the widget.
4. **Multi-round prompting** — Split into batches of 4, though this adds friction.

**Where this bites:** `/learnings:compound` when a session produces >4 learnings. The fix applied there: auto-save High-utility learnings (they're almost always worth keeping) and only prompt for Medium/Low.

## Preserve Reference Style During Migrations

When migrating file paths (e.g., relocating shared references), preserve each skill's original reference style rather than normalizing all references to a single style:

- If a skill used `@_shared/file.md` (auto-include directive), update to `@~/.claude/skill-reference/file.md`
- If a skill used `` `~/.claude/commands/.../file.md` `` (bare path in backticks), update to `` `~/.claude/skill-reference/file.md` ``

Adding `@` to files that previously used bare paths changes behavior (auto-include vs manual read instruction). Only update the path portion, not the reference mechanism.

## Compound Skill: Grep Before Creating New Files

When `/learnings:compound` creates a new learnings file, it should first grep `~/.claude/learnings/` for existing files matching the domain. Without this check, near-duplicate files accumulate (e.g., `parallel-planning.md` and `parallel-plans.md` about the same topic). Similarly, check if the insight already exists in a more authoritative location before creating a domain-specific copy — platform behavior patterns compounded from a parallel-plan session may already be covered in `claude-code.md`.

Additionally, when creating a new learnings file, check personas in `~/.claude/commands/set-persona/` for `Detailed references` sections that cover the same domain — a new file won't be discoverable through persona activation unless it's wired in. Suggest adding a reference link to matching personas.

## "LLM Knows X" ≠ "LLM Consistently Applies X"

When deciding whether to codify a pattern, the question isn't "can the model execute this when asked?" but "does it reliably do so unprompted?" Textbook patterns (extract class, DRY, factories) that the model knows but doesn't consistently apply during implementation still warrant codification — as a lightweight checklist reminder, not a tutorial. The correct form factor is a slim reference file (~15 lines) that reminds, not a 229-line reference file that teaches.

## Stale Path References Are the Primary Skill Maintenance Issue

Skills referencing specific file paths (`~/.claude/lab/script.sh`, `docs/learnings/topic.md`) go stale when files are moved, deleted, or renamed. In curation of 4 skills, 2 had broken path references. During curation, verify every file path in SKILL.md and reference files actually resolves. Paths to external scripts and cross-directory references are more fragile than paths within the skill's own directory.

**Use full paths for cross-directory references.** Bare filenames (e.g., `refactoring-patterns.md`) silently break when no local file exists — the intended target may be `~/.claude/learnings/refactoring-patterns.md`. Always use full `~/.claude/...` paths when referencing files outside the skill's own directory.

**Symlink gotcha:** `~/.claude/` subdirectories are directory-level symlinks to the dotfiles repo. `Glob` doesn't reliably resolve paths through these symlinks — a file can exist but Glob reports "No files found." Always verify path existence with `Read` (which resolves symlinks correctly), not `Glob`.

## Verify Producer-Consumer Wiring Across Skills

When a skill produces structured output intended for another workflow (e.g., curate skill's "Suggested Deep Dives" section), verify the consuming workflow actually reads it. A capability defined in a component skill but not wired into the orchestrating spec is a silent no-op — the output exists but nothing acts on it. Check this especially for skills that generate report sections, candidate lists, or action items meant to feed into autonomous loops.

## Skill-Scoped Hooks: Placement Decision Framework

Hooks can live in skill `hooks:` frontmatter (active only during skill execution) or in `settings.json` (active always). Choose placement based on scope:

**Skill frontmatter** — Use for invariants specific to one skill's workflow:
- Conflict marker detection after merge edits (`git/resolve-conflicts`)
- Section count verification after content sync (`quantum-tunnel-claudes`)

**Settings (project/user)** — Use for universal checks that apply to ALL file edits:
- Auto-format after Edit/Write (project settings)
- Secret file protection (user settings)
- CLAUDE.md section preservation (project settings)

**Decision rule**: If you'd need to copy the hook into 3+ skills, it belongs in settings.

### Hook Type Selection

Default to `command` hooks (shell scripts). Only escalate when shell logic can't express the check:
- **`command`** — Deterministic checks, <1s, zero token cost. `jq` + `grep` for most cases.
- **`prompt`** — Simple judgment calls, ~2-5s, ~1K tokens (Haiku default).
- **`agent`** — Complex verification needing tool access, ~10-60s, ~5-50K tokens.

See also: `~/.claude/learnings/claude-code-hooks.md` for PostToolUse limitations, stop hook looping, and other hooks mechanics.

## `@` References in SKILL.md Eagerly Load — Use Conditional References for Large Files

`@` references in SKILL.md eagerly load content into context when the skill is invoked, same as in CLAUDE.md. Every `@` reference adds to the skill's token cost on every invocation.

**When to use `@`**: Small, always-needed references (< 50 lines) used on every invocation.

**When to use conditional (backtick) references**: Larger files or files only needed in specific branches of the skill's logic. Remove the `@` prefix and add a conditional read instruction:

```markdown
# Always loaded (costs tokens every invocation)
## Reference Files
- @./reply-templates.md

# Conditional (loaded only when needed)
## Reference Files (conditional — read only when needed)
- `reply-templates.md` — Read before composing replies (step 5)
- `lgtm-verification.md` — Read only when LGTM comment detected
```

Then in the step itself, explicitly instruct: "Read `template.md` from the skill's base directory (shown in the header)."

**Path resolution gotcha**: `@./` relative paths may have resolution issues — the 3 observed failures with `git:create-mr` where `@./mr-body-template.md` wasn't loaded were likely path resolution bugs, not evidence that `@` doesn't work in SKILL.md. Use `@filename.md` (skill-directory-relative) or `@~/.claude/...` (absolute-ish) paths for reliability. Always add explicit read instructions as a defensive backup regardless of `@` vs backtick style.

**Attention pattern**: Even for `@`-loaded content, explicitly instructing "Read X before step N" in the relevant step improves reliability — the LLM engages more deliberately with content it actively reads vs content passively injected into a large context.

## Update Producer and Consumer Skills Together

When changing a contract between two skills (e.g., the parallel plan format consumed by `/parallel-plan:execute` and produced by `/parallel-plan:make`), update both skills in the same commit. A broken intermediate state — where the producer writes a new format but the consumer still expects the old one — causes silent failures in automated workflows. Add legacy support in the consumer if backwards compatibility is needed.

## Discoverability via Trigger Phrases

Skills are only invoked when the model recognizes the user's intent maps to a skill. If the skill description is too narrow, the model may execute the task manually instead of invoking the skill.

**Fix:** Add natural-language trigger phrases to the skill's `description` field in the YAML frontmatter. Cover common ways a user might express the intent without naming the skill directly.

Example from `git:create-mr`:
```
description: Create a merge request [...]. Use when the user asks to push an MR, in any variation (e.g., "commit and push an MR", "branch and push a MR", "create a merge request", "push this as an MR").
```

The description field serves double duty — documentation for the user and a matching signal for the model. Optimizing for the latter prevents skill bypass.

## Three-Level Skill Routing Works

Claude Code supports three-level directory nesting for skills: `commands/a/b/c/SKILL.md` routes to `/a:b:c`. Confirmed working with `commands/ralph/consolidate/init/SKILL.md` → `/ralph:consolidate:init`. However, skills created mid-session aren't discoverable until a new session starts — the skill discovery cache is populated at session init. The `Skill` tool returns "Unknown skill" for mid-session additions, but invoking from a separate terminal works immediately.

## "Reduces Typing" Is Sufficient Justification for a Skill

Don't overthink whether a repeated sequence "deserves" to be a skill. If the user types the same N commands every session in the same order, a skill that runs them sequentially is a valid simplification — even if individual steps are conversational or already invoke other skills. The bar is consistency of the sequence, not complexity of the automation.

## Persona Value: Judgment Layer, Not Recipe Catalog

A persona's value comes from changing how you *think* about a domain — priorities, tradeoffs, review instincts. Recipe-heavy content (step-by-step patterns, code templates) belongs in learning files, not personas. When creating a persona from a cluster of learnings:

1. Seed with judgment-grade content only (architectural principles, review checks, tradeoff heuristics, gotchas that change decision-making)
2. Reference learning files conditionally (via "Detailed references" section) for recipes and code patterns
3. Start thin — the enrichment loop grows the persona as more judgment-style insights emerge from real work
4. A persona that's 90% recipes and thin on judgment doesn't justify the always-on context cost

The test: "Would activating this persona before a task actually change what I do?" If the answer is just "load a gotcha list," it's not ready to be a persona yet.

## Tools Must Encode the Philosophy They Curate

When a philosophy is established in learnings (e.g., "lean personas as judgment layers, rich learnings as knowledge") but the tools that maintain the corpus don't enforce it, the philosophy erodes. Example: the consolidation spec's Persona Handling section told the agent to "enrich" personas with knowledge content — directly contradicting the lean-persona principle in this very file. The spec was actively working against the philosophy it was supposed to maintain.

**Check**: when updating a curation tool's methodology, cross-reference the principles in the learnings it curates. The tool's actions should reinforce the established philosophy, not contradict it.

## Compose Personas from Shared Learnings

Personas should reference shared learning files for cross-cutting instincts rather than inlining everything. Language-agnostic practices (no duplication, single source of truth, port intent not idioms) go in a shared learning file; language-specific patterns (no IIFEs, no `as` casts) stay inline in the persona. Multiple personas can reference the same learning file without duplication.

Pattern:
```markdown
## Code style
Enforce `learnings/code-quality-instincts.md` (generic instincts).

Language-specific:
- Avoid IIFEs — extract named helpers
- Avoid `as` casts — fix the source type
```

This keeps persona files focused on domain judgment while inheriting shared quality instincts.

## Cross-Persona Duplication: Extract to Shared Dependency

When two peer personas share duplicated content (e.g., both have React/Next.js gotchas), **extract to a shared learning file and reference from both** rather than choosing which persona "owns" the content. Ownership-based resolution ("the more specialized persona owns the gotcha") breaks down when neither persona is clearly more specialized for the shared domain — react-frontend is more specialized for React, xrpl-typescript-fullstack is more specialized for XRPL, but both legitimately need the React patterns.

Extracting to a shared learning eliminates the ownership question and follows the lean-persona philosophy: personas reference knowledge, they don't inline it. Both personas get a Detailed references entry pointing to the same learning file.

## Skill Responsibility Boundaries: Compound, Curate, Retro

Compound = intake (captures new learnings from sessions). Curate = maintenance (reorganizes, prunes, migrates existing learnings). Retro = reflection (surfaces discussion, invokes compound). Changes to *what* gets captured belong in compound. Changes to *how* content is organized belong in curate. Retro orchestrates but doesn't own persistence. When deciding where a system change belongs, trace the data flow: if it's about widening or narrowing the intake aperture, it's compound.

## Explore Agent Upfront for Large Implementation Tasks

For implementation tasks touching 10+ reference files (existing infrastructure, patterns to follow, files to edit), launch a thorough Explore agent upfront before writing anything. The upfront cost (~2 min, 50+ tool calls) eliminates incremental back-and-forth during execution and enables writing all output files in parallel with full context. This is faster end-to-end than reading files incrementally as you discover you need them.

## Skill Maturity Progression

Skills follow a natural lifecycle: **tight feedback loop** (run, inspect output, fix design gaps) → **edge case discovery** (core works, boundary cases emerge) → **operational refinement** (retro shifts to "was it useful" not "did it work") → **folds into /session-retro** (just another tool, no special scrutiny).

Maturity is per-capability, not per-skill. A fundamental change to one capability (e.g., adding a new content type to a curation loop) pulls that capability back to the tight-feedback stage while the rest of the skill remains mature. This is desirable — it means the system adapts rather than calcifying.

## Gotchas Are Proactive Knowledge, Not Reactive Reference

Gotchas and learnings are both knowledge, but they differ in **delivery timing**. A learning can wait until you're in the weeds ("how do I wire a rate limiter?"). A gotcha must be present *before you start* — it prevents mistakes the agent wouldn't think to check for.

**The test:** "Would the agent make this specific mistake without this in-context?" If yes → proactive gotcha. If it's reference knowledge needed only when you're already working in that area → reactive learning.

This distinction matters because reactive-only loading has a failure mode: the agent has to *know it needs the gotcha* to load the file. But the whole point of a gotcha is catching things you wouldn't think to check.

## `*-gotchas.md` Companion File Convention

Proactive gotchas live in dedicated `learnings/*-gotchas.md` files — small (10-30 lines) one-liner tripwires. They're **companions** to `*-patterns.md` files when one exists (e.g., `xrpl-patterns-gotchas.md` alongside `xrpl-patterns.md`), **standalone** when no patterns file exists (e.g., `java-infosec-gotchas.md`).

Personas reference gotcha files via a `## Proactive loads` section — loaded deterministically at persona activation. This is distinct from `## Detailed references` which are reactive/on-demand.

```markdown
## Proactive loads
- `learnings/xrpl-gotchas.md`
- `learnings/react-frontend-gotchas.md`

## Detailed references
- `learnings/xrpl-patterns.md` — full recipes, API details
```

**Why separate files, not sections within patterns files:** The `Read` tool is all-or-nothing — no section-level extraction. Loading `xrpl-patterns.md` (200+ lines) to get 15 lines of gotchas wastes context. Small dedicated files keep proactive loading cheap.

**Every persona's gotchas get a file, even with a single consumer.** Uniform convention over case-by-case optimization — predictability of the pattern matters more than minimizing file count.

This resolves the proactive/shared/lean trilemma: gotcha files are cheap to load (small), single source of truth (shared across personas), and loaded at persona activation (proactive).

## Skill Reference Files Are Authoritative — Deduplicate from Skills

`skill-references/*.md` files are the single source of truth for shared patterns consumed by multiple skills. When skills grow and absorb reference content into their SKILL.md, the duplication should be removed from the *skill*, not the reference. The reference file stays authoritative; skills reference it.

During curation, when a skill section duplicates a reference file section, replace the skill's inline content with a pointer (e.g., "See `agent-prompting.md` § Git Workflow"). This keeps skills lean and prevents the same content from fragmenting across multiple consuming skills.

## Persona Extends Inherits Detailed References

Child personas that declare `## Extends: <parent>` inherit the parent's Detailed references — the set-persona skill loads the parent first, then layers the child. Don't duplicate parent refs in the child; only add refs unique to the child's narrower domain.

## Proactive Loads Require Agent Behavior, Not @ References

Persona `## Proactive loads` sections cannot use `@` references because persona files are data files read via the Read tool at runtime — `@` only resolves in CLAUDE.md and SKILL.md at the CLI level. The set-persona skill's Step 5 explicitly reads each proactive load file, making it agent-dependent but the only viable mechanism. The keyword-based learnings search (`context-aware-learnings.md`) is the fallback for sessions without an active persona.
