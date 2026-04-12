Skill design fundamentals — composition, creation heuristics, responsibility boundaries, and validation patterns.
- **Keywords:** skill design, compose, AskUserQuestion, skill responsibility, stateful mode, gap vs inconsistency, exploration skill, portable, bash commands, validation, intake gate, triage, open contribution, $ARGUMENTS, disable-model-invocation, irreversible
- **Related:** none

---

> Platform features, cross-platform compatibility, plugins, and agent definitions → `skill-platform-portability.md`
> Polling loops, quick-exit, re-review, reviewer timestamps → `polling-review-skills.md`

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
- If the operator wants fixes, they initiate that as a separate task

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

When two skills share setup (e.g., locating a project, reading files) but diverge in purpose (one exploratory, one operational), keep them separate and composable. Duplicate the shared setup in each skill (~10 lines of instructions is fine) rather than making one depend on the other. Add a hint in the operational skill pointing to the exploratory one for operators who need context first. Example: `/ralph:resume` mentions `/ralph:brief` but doesn't invoke it — the operator composes them when needed.

## Merging Diverged Skills Across Repos

When two repos have independently evolved the same skill, merge by keeping unique features from both sides. Use the more complete version as the base, append unique sections from the other. For platform-specific commands (gh vs glab), parameterize via a shared reference file with detection logic and a mapping table. One codebase to maintain means no future drift.

**When to unify vs keep separate:** Unify when the workflow is shared and only the plumbing differs (CLI commands, API field names, terminology). Keep separate when the workflows themselves diverge — different steps, decision points, or operator interactions with no equivalent on the other platform.

## Skill Improvement: Fix and Assess In-Session

Apply skill improvements in the same session they surface — context fades across sessions. After running a skill, note what worked, what didn't, and prioritize: regression prevention >> efficiency; one-line fixes >> structural overhauls. Cap at 3-5 improvements. If a skill hits a bug mid-execution, fix immediately — scope to one constraint workaround per incident.

## AskUserQuestion Has a 4-Option Maximum

`AskUserQuestion` enforces `maxItems: 4` on the options array. This is a hard schema constraint — not configurable. Skills that present learnings, tasks, or choices to the operator will fail at runtime if they try to offer >4 options.

**Workarounds (in order of preference):**
1. **Auto-save high-confidence items** — Remove them from the selection set entirely. Only prompt for uncertain items, which usually fit in 4 options.
2. **Group by theme** — Combine related items into a single option (e.g., "CI patterns (3 items)" instead of 3 separate options).
3. **Use free-text input** — Present a numbered table and let the operator type "1,3,5" or "all" as a regular message instead of using the widget.
4. **Multi-round prompting** — Split into batches of 4, though this adds friction.

**Where this bites:** `/learnings:compound` when a session produces >4 learnings. The fix applied there: auto-save High-utility learnings (they're almost always worth keeping) and only prompt for Medium/Low.

## "LLM Knows X" ≠ "LLM Consistently Applies X"

When deciding whether to codify a pattern, the question isn't "can the model execute this when asked?" but "does it reliably do so unprompted?" Textbook patterns (extract class, DRY, factories) that the model knows but doesn't consistently apply during implementation still warrant codification — as a lightweight checklist reminder, not a tutorial. The correct form factor is a slim reference file (~15 lines) that reminds, not a 229-line reference file that teaches.

## "Reduces Typing" Is Sufficient Justification for a Skill

Don't overthink whether a repeated sequence "deserves" to be a skill. If the operator types the same N commands every session in the same order, a skill that runs them sequentially is a valid simplification — even if individual steps are conversational or already invoke other skills. The bar is consistency of the sequence, not complexity of the automation.

## Skill Responsibility Boundaries: Compound, Curate, Retro

Compound = intake (captures new learnings from sessions). Curate = maintenance (reorganizes, prunes, migrates existing learnings). Retro = reflection (surfaces discussion, invokes compound). Changes to *what* gets captured belong in compound. Changes to *how* content is organized belong in curate. Retro orchestrates but doesn't own persistence. When deciding where a system change belongs, trace the data flow: if it's about widening or narrowing the intake aperture, it's compound.

## No Half-Steps in Numbered Instructions

When writing numbered steps in skills or protocols, use proper integer steps (Step 0, 1, 2, 3...), not half-steps (Step 1.5). Half-steps signal the structure wasn't planned upfront, add uncertainty about ordering, and make the sequence harder to reference. If a new step needs to be inserted, renumber all subsequent steps.

## Validating Skill Changes

After modifying or creating skills, verify before committing:
1. **Structure** — Directory exists, old files removed (if migrated)
2. **Content** — Key content present in SKILL.md, reference files linked correctly
3. **Permissions** — Required Bash patterns added to settings.json
4. **Function** — Test the actual commands the skill uses when possible

## Bash Commands in Skills

- Use `--force-with-lease` instead of `--force` for safety
- Include the full command, not just fragments
- Show prerequisite commands (fetch, checkout) explicitly
- Use HEREDOC for multi-line commit messages
- When a skill says "parse JSON response" after an API call, include the explicit `jq` command for extraction — especially when output may be auto-persisted to a file. "Parse the JSON" without a prescribed command invites ad-hoc piping that violates verbatim execution rules

## Operator Interaction Points

Mark steps where operator input is needed:
- **Ask for confirmation**: Before destructive operations (force push, reset)
- **Ask for selection**: When multiple paths are possible
- **Show and confirm**: Before committing or pushing

## File Operations in Skills

Keep temp files within repo scope rather than system directories:
- **Use `./tmp/`** instead of `/tmp/` for skill-generated files
- Add `tmp/` to `.gitignore`
- Create the directory with `mkdir -p ./tmp` before use

This keeps operations contained to the repo context and avoids permission issues.

## Making Skills Portable

Skills should work across different projects. Periodically audit skills to remove project-specific content.

| Project-Specific | Generic Replacement |
|------------------|---------------------|
| Class names from your codebase | Domain-neutral names (`DataProcessor`, `BatchProcessor`) |
| File paths from your project | Generic paths (`pipeline.py`, `src/models/`) |
| Internal API names | Generic references (`External API`, `Payment API`) |

**Audit process:** Search skills for project-specific class/file names → check SKILL.md and reference files → replace with domain-neutral examples → verify examples still make sense generically.

## Security Audits on Skill Files: Executable Code vs LLM Instructions

Security audit tools reviewing skill files often flag shell injection, race conditions, and input sanitization issues that don't apply. Key distinctions:

- **Template placeholders are not shell variables.** `<branch>`, `<number>`, `<TS>` in markdown skill instructions are substituted by the LLM when constructing commands via the Bash tool. There's no `shell=True` expansion — the injection surface doesn't exist.
- **Concurrency findings assume unsupported modes.** "Two agents on the same MR" race conditions don't apply when the design contract is one agent per role per MR.
- **Identity checks are defense-in-depth, not security boundaries.** Body-based role detection (`Role:.*Reviewer`) is bypassable in theory, but the independent assessment step is the real gate. Adding username allowlists trades maintenance cost for minimal security gain.

When addressing such reviews: acknowledge the theoretical concerns, push back with the execution model distinction, and implement only findings that are genuinely actionable (missing flags, stale state, pre-flight checks).

### Deduplicate skill content against shared references

When a skill has a "GitLab API Notes" or similar reference section AND a shared base reference (e.g., `request-interaction-base.md`) or learnings file covers the same content, delete the section from the skill. Duplication wastes context tokens on every invocation and creates drift risk. Keep API-specific notes only in the skill when they're step-specific (e.g., `-F` vs `-f` in a GraphQL posting step) — move general patterns to the shared reference.

## Intake Skills on Open-Contribution Repos

When a skill serves as the quality gate for an open-contribution corpus (anyone can branch and submit), separate editorial triage from mechanical findings. Mechanical checks (dedup, format, cross-refs, index sync) have clear right/wrong answers and fit a confidence-based auto-fix model. Usefulness assessment (specificity, redundancy beyond exact duplication, actionability) is subjective — present it as a separate report section with flags, not as findings to fix. The reviewer makes the call; the skill surfaces the signal.

Keep triage non-blocking: flag low-signal contributions rather than gating them. Niche learnings sometimes deliver outsized value months later, so false negatives on "low value" are expensive. The triage section belongs in the MR comment alongside the mechanical report, not in the approval flow.

## Security-Critical Instructions Need Structural Prominence

Advisory phrasing ("sanitize before use", "verify the path") in skill instructions is insufficient for security-critical steps — LLMs skip steps in long instruction chains. Elevate to a **PREREQUISITE** marker with explicit abort-on-failure and fallback values. The visual break and imperative framing increase compliance without adding bash implementation detail (which may not apply to all consumers).

**Pattern:** `**PREREQUISITE — <action> before <trigger>.** <allowlist/validation rule>. Abort if verification fails.`

## Build Skills from Live Sessions

The most effective skill authoring pattern: execute the workflow manually first, then codify. Run the methodology in a real session with the operator, discuss design decisions as they arise (single-pass vs multi-sweep, what to share vs keep self-contained, where to draw boundaries), and write the skill from validated experience. The live session surfaces edge cases, operator preferences, and cost tradeoffs that spec-first design misses. The session also produces a natural test case — if the skill can reproduce what the session did, it's correct.

## Converting Inline Orchestrators to Director Playbook Skills

When a skill spawns agents inline (via the Agent tool, waiting for results in waves), it can be converted to the director playbook pattern: assessment-only skill → artifact generation → `let-it-rip.sh` runner. Key steps:

1. **Split assessment from execution.** The skill generates `manifest.json` + per-item `prompt.txt` + `let-it-rip.sh`, then exits. Execution is `bash let-it-rip.sh`, rerunnable.
2. **Move orchestration logic into prompt templates.** Watermark/skip (steps 1-4 from sweep-scaffold), role-specific work, and artifact writing (results.md, learnings.md, status.md) all go into the prompt template — the runner just pipes prompt.txt to `claude -p`.
3. **Adapt the runner.** The `parallel-claude-runner-template.sh` is PR-centric. For non-PR items (issues, tickets), adapt: directory naming (`issue-<N>`), state checks (issue open/closed vs PR merged), conditional worktrees (only for roles that modify code).
4. **Define convergence per role.** Different roles converge differently (implementer: PR opened; clarifier: comment posted; reviewer: review posted). Document in the skill's Convergence section for directors.

## Learnings Search in Headless Agent Prompts

Agent prompts that do domain work (implementing, reviewing, clarifying) benefit from a learnings search step before the main work begins. Pattern:

1. Read `~/.claude/learnings/CLAUDE.md` index → match clusters to domain → sniff headers → load matches
2. Repeat for team learnings (`learnings-team/`) and project learnings (`docs/learnings/`)
3. Announce with `📚 [pre-<mode>]` tags listing loaded files and intended influence
4. **Provenance in learnings.md** (mandatory) — each agent logs which learnings it loaded and how they shaped the work. This is the only operator-visible record.
5. **Audit trail in output** — implementers include a "Learnings Applied" section in PR bodies; reviewers reference learnings in review comments. Makes the influence reviewable.

This pattern applies to any skill that spawns domain-work agents: sweep:work-items, sweep:review-prs, sweep:address-prs, or custom playbooks.

## Exportable vs Internal Skill Directories

When a repo ships skills meant for cross-project use alongside project-internal skills, separate them with a namespace directory: `.claude/commands/<namespace>/` for exportable, `.claude/commands/` for internal. Devs symlink only the namespace directory (`ln -s ~/.claude/<repo>/.claude/commands/<namespace> ~/.claude/commands/<namespace>`), keeping internal skills invisible outside the repo. Skills in the namespace appear as `/<namespace>:<skill>` — the directory structure produces the command hierarchy.

## Prerequisites Before Instructions

Place `## Prerequisites` (permissions, env vars, symlink setup) above `## Instructions` in skill files. Operators scanning a skill file hit blockers before investing time reading the workflow. This also means prerequisites don't need to be duplicated in README or other docs — the skill is the single source of truth.

## Cross-Skill Convention Consistency Beats Per-Skill Optimization

When N skills share an artifact contract (e.g., sweep:* writing `results.md`/`status.md`/`learnings.md`), prefer one-name-fits-all over per-skill optimization — even when one skill's agent naturally writes a different convention. The maintenance cost of per-skill divergence (forking shared docs, multiple template files, mental lookup table) exceeds the cost of mild forcing on the outlier agent. Example: sweep address agents naturally write `results.md` (plural), sweep work-items agents naturally write `result.md` (singular). The right call is to standardize on one across all sweep skills (plural in this case), not match each skill to its agents' tendency. The "lean into natural agent behavior" rule still holds — within a single skill — but cross-skill consistency is structural and overrides it.

## $ARGUMENTS vs Derived Values

In skill files, `$ARGUMENTS` is the CLI-substituted value (replaced before the model sees the content). When a later phase requires a derived value (e.g., next version calculated from the argument), use descriptive placeholders like `<next-version>` to distinguish computed values from CLI-substituted ones. Mixing `$ARGUMENTS` for both raw input and derived values makes the skill harder to read and debug.

## `disable-model-invocation: true` for Irreversible Skills

Skills with irreversible side effects (publish, tag, deploy) should set `disable-model-invocation: true` — prevents the model from autonomously invoking them when it determines they'd fulfill the user's intent.

## Cross-Refs

- `~/.claude/learnings/claude-code/multi-agent/orchestration.md` — agent-to-agent collaboration architecture (review cycles, auto-implementation patterns migrated from here)
