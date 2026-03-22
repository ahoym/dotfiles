# Skill Design Patterns

Comprehensive patterns for designing, structuring, and maintaining Claude Code skills — composition, reference files, permissions, token optimization, platform portability, and skill lifecycle.
- **Keywords:** SKILL.md, skill design, reference files, AskUserQuestion, @ references, conditional load, token optimization, platform commands, hub-and-spoke, skill maturity, producer-consumer, worktree, namespace migration
- **Related:** claude-authoring-content-types.md, skill-platform-portability.md, multi-agent-patterns.md, process-conventions.md, claude-authoring-polling-review-skills.md

---

> Platform features, cross-platform compatibility, plugins, and agent definitions → `skill-platform-portability.md`
> Polling loops, quick-exit, re-review, reviewer timestamps → `claude-authoring-polling-review-skills.md`

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

**When to unify vs keep separate:** Unify when the workflow is shared and only the plumbing differs (CLI commands, API field names, terminology). Keep separate when the workflows themselves diverge — different steps, decision points, or user interactions with no equivalent on the other platform.

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

## "LLM Knows X" ≠ "LLM Consistently Applies X"

When deciding whether to codify a pattern, the question isn't "can the model execute this when asked?" but "does it reliably do so unprompted?" Textbook patterns (extract class, DRY, factories) that the model knows but doesn't consistently apply during implementation still warrant codification — as a lightweight checklist reminder, not a tutorial. The correct form factor is a slim reference file (~15 lines) that reminds, not a 229-line reference file that teaches.

## Stale Path References Are the Primary Skill Maintenance Issue

Skills referencing specific file paths (`~/.claude/lab/script.sh`, `docs/learnings/topic.md`) go stale when files are moved, deleted, or renamed. In curation of 4 skills, 2 had broken path references. During curation, verify every file path in SKILL.md and reference files actually resolves. Paths to external scripts and cross-directory references are more fragile than paths within the skill's own directory.

**Use full paths for cross-directory references.** Bare filenames (e.g., `refactoring-patterns.md`) silently break when no local file exists — the intended target may be `~/.claude/learnings/refactoring-patterns.md`. Always use full `~/.claude/...` paths when referencing files outside the skill's own directory.

**Symlink gotcha:** `~/.claude/` subdirectories are directory-level symlinks to the dotfiles repo. `Glob` doesn't reliably resolve paths through these symlinks — a file can exist but Glob reports "No files found." Always verify path existence with `Read` (which resolves symlinks correctly), not `Glob`.

**When files move outside a skill's directory, `@` refs must become Read instructions.** `@` resolves relative to the SKILL.md file's directory — if a referenced file (e.g., a template) is relocated to an infrastructure directory elsewhere, the `@` path breaks silently. Replace with explicit instructions to Read from the new absolute path (e.g., "Read `~/.claude/ralph/research/templates/spec-template.md`"). This is the migration cost of restructuring; `@` gives you eager loading convenience at the cost of co-location coupling.

**When reviewing a consumer that delegates by section name, verify the section exists.** When a PR changes a skill to delegate to a named section in a reference file (e.g., `"follow 'Check for Existing Review' in the platform cluster files"` instead of inlining a command), verify the section actually exists in the reference file. Section-name delegations fail silently — the agent gets no guidance and improvises — while missing file-path references fail loudly with a Read error. Read the reference file and confirm the section heading during review.

## Producer-Consumer Skill Contracts

When a skill produces structured output intended for another workflow (e.g., curate skill's "Suggested Deep Dives" section), verify the consuming workflow actually reads it. A capability defined in a component skill but not wired into the orchestrating spec is a silent no-op. Check this especially for skills that generate report sections, candidate lists, or action items meant to feed into autonomous loops.

When changing a contract between two skills (e.g., the parallel plan format consumed by `/parallel-plan:execute` and produced by `/parallel-plan:make`), update both skills in the same commit. A broken intermediate state — where the producer writes a new format but the consumer still expects the old one — causes silent failures. Add legacy support in the consumer if backwards compatibility is needed.

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

The `description:` field serves double duty — documentation for the user and a matching signal for the model. **Every** `.claude/commands/*.md` file should include `description` frontmatter — missing descriptions make skills invisible in the command picker.

**Optimize for searchability:** Use widely understood terms (no internal jargon), include action verbs, use standard dev workflow terminology, list key capabilities for multi-purpose skills.

**Add trigger phrases** when the skill name + functional description isn't enough for agent inference — e.g., opaque names or overlapping skills needing disambiguation. Cover common ways a user might express the intent without naming the skill directly. Skip routing hints when the skill name already communicates intent or the functional description covers it.

## Subagent Prompts: Read Shared References Instead of Hardcoding

When a subagent prompt needs platform-specific commands (API calls, CLI syntax), have the subagent `Read` a shared reference file at runtime rather than hardcoding the commands inline. One extra tool call per subagent is cheap; maintaining duplicate command lists across orchestrator + subagent prompts is expensive when they inevitably drift.

## Three-Level Skill Routing Works

Claude Code supports three-level directory nesting for skills: `commands/a/b/c/SKILL.md` routes to `/a:b:c`. Confirmed working with `commands/ralph/consolidate/init/SKILL.md` → `/ralph:consolidate:init`. However, skills created mid-session aren't discoverable until a new session starts — the skill discovery cache is populated at session init. The `Skill` tool returns "Unknown skill" for mid-session additions, but invoking from a separate terminal works immediately.

## "Reduces Typing" Is Sufficient Justification for a Skill

Don't overthink whether a repeated sequence "deserves" to be a skill. If the user types the same N commands every session in the same order, a skill that runs them sequentially is a valid simplification — even if individual steps are conversational or already invoke other skills. The bar is consistency of the sequence, not complexity of the automation.

## Skill Responsibility Boundaries: Compound, Curate, Retro

Compound = intake (captures new learnings from sessions). Curate = maintenance (reorganizes, prunes, migrates existing learnings). Retro = reflection (surfaces discussion, invokes compound). Changes to *what* gets captured belong in compound. Changes to *how* content is organized belong in curate. Retro orchestrates but doesn't own persistence. When deciding where a system change belongs, trace the data flow: if it's about widening or narrowing the intake aperture, it's compound.

## Body-Only Templates for Skill Reference Files

Template reference files should contain only message body content — not posting commands. See `claude-authoring-content-types.md` § "Skill References & Templates" for the full convention.

## Skill Maturity Progression

Skills follow a natural lifecycle: **tight feedback loop** (run, inspect output, fix design gaps) → **edge case discovery** (core works, boundary cases emerge) → **operational refinement** (retro shifts to "was it useful" not "did it work") → **folds into /session-retro** (just another tool, no special scrutiny).

Maturity is per-capability, not per-skill. A fundamental change to one capability (e.g., adding a new content type to a curation loop) pulls that capability back to the tight-feedback stage while the rest of the skill remains mature. This is desirable — it means the system adapts rather than calcifying.

## Inline Critical Conditions — Don't Defer to Lazy-Loaded Files

When a skill step says "follow the logic in `<file>.md`," the agent may cache past the deferral entirely — especially during polling loops where efficiency pressure encourages skipping file reads. Critical branching conditions (e.g., "check commits AND replies AND reviews before skipping") must be inlined in the main SKILL.md, not deferred to a reference file. Use the reference file for detailed procedures, but state the branching conditions where they're evaluated.

The tension: "prefer offset+limit reads, don't re-read files" (efficiency) vs "follow this file's logic" (correctness). Inlining the conditions resolves this — the agent can cache the detailed procedures while still seeing the decision criteria.
## Skill Reference Files Are Authoritative — Deduplicate from Skills

`skill-references/*.md` files are the single source of truth for shared patterns consumed by multiple skills. When skills grow and absorb reference content into their SKILL.md, the duplication should be removed from the *skill*, not the reference. The reference file stays authoritative; skills reference it.

During curation, when a skill section duplicates a reference file section, replace the skill's inline content with a pointer (e.g., "See `agent-prompting.md` § Git Workflow"). This keeps skills lean and prevents the same content from fragmenting across multiple consuming skills.

## /loop Supersedes Purpose-Built Monitor Skills

When a domain skill (e.g., `/git:address-request-comments`) fetches fresh state each invocation, pairing it with `/loop` replaces purpose-built monitor skills that maintain their own state tracking. The monitor skill's state management adds complexity without value — the domain skill's stateless design means every invocation is self-contained. Delete the monitor skill; keep the domain skill + `/loop`.

## Dual Platform Commands for Diverged APIs

When unifying GitHub/GitLab skills, CLI commands (`gh pr create` vs `glab mr create`) can use variable substitution (`$CREATE_CMD`). API calls cannot — JSON field names (`number` vs `iid`, `body` vs `description`), query params (`direction=asc` vs `sort=asc&order_by=created_at`), and endpoint shapes diverge too much. Use side-by-side platform blocks for API calls:

```markdown
**GitHub:**
\```bash
gh api "repos/{owner}/{repo}/pulls/..." | jq '{number, ...}'
\```

**GitLab:**
\```bash
glab api "projects/:id/merge_requests/..." | jq '{iid, ...}'
\```
```

Variable tables in step 1 ("Detect platform") work well for CLI commands and flags.

## Shared Reference Files Reduce Cross-Skill Duplication

When multiple skills duplicate the same platform-specific command blocks (e.g., GitHub vs GitLab API calls), extract them into shared reference files under `~/.claude/skill-references/`. Split by platform (`github-commands.md`, `gitlab-commands.md`) so each skill reads only the file matching its detected platform — avoids loading unused commands. Don't use `@` references for these files; skills should Read selectively after platform detection.

Benefits:
- Bug fixes apply once (e.g., fixing a jq escaping issue in the shared file fixes all skills)
- New platform support added in one place
- Skills stay focused on workflow logic, not API mechanics
- Selective Read loads ~half the tokens vs auto-inlining both platforms

Pattern: skill step 1 defines variables (`$VIEW_CMD`, `$API_CMD`), shared reference uses those variables in command templates, skill steps reference sections by name.

### Session-Stable References: Skip-If-Cached Instruction Pattern

When a shared reference produces a result that's stable within a session (e.g., platform detection — the git remote doesn't change mid-session), add explicit conditional language to the instruction step: "if not already detected this session, read X and follow its logic." This enables the LLM to skip both the file read and the detection bash call on subsequent skill invocations in the same session. Saves ~200 tokens + 1 bash call + 1 file read per subsequent invocation. The reference section should use backtick-quoted paths (not `@`) with a note like "read if platform not yet detected this session."

## Incremental Fetch Timestamps Must Derive From Data

When polling for new items (PR comments, notifications, etc.), set `LAST_FETCH_TS` to the `created_at` of the newest item returned — not wall-clock time. Wall-clock creates gaps: if a comment arrives between the API call and the timestamp assignment, the next poll's `since` parameter skips past it. If no items are returned, keep the previous timestamp unchanged.

## Re-Read Templates at Point of Use, Not Ahead of Time

When a skill step says "read template X and use it verbatim," read the template immediately before that step — not minutes earlier as pre-work. Stale context causes improvisation: the agent fills in values from memory rather than from the template's prescriptive instructions, missing critical details like staging directories or routing rules. The longer the gap between reading and using, the more likely the agent substitutes its own assumptions.

## Explicit Variable Continuity Across Skill Steps

Multi-step skills should explicitly name variables when data flows between steps. E.g., "Store as `FILES_TO_EXTRACT`" in step 3, then "For each file in `FILES_TO_EXTRACT`" in step 7. Without this, later steps become ambiguous — "add the files" vs "add `FILES_TO_EXTRACT`." Named variables create a traceable data flow through the skill.

## Skills Shouldn't Assume Invocation Context

A skill doesn't know whether it was invoked manually, by `/loop`, or by another skill. Skill instructions should describe *what the skill knows* (e.g., "the review is approved") not *what to do about the caller's context* (e.g., "stop the polling loop"). The agent in conversation can connect the dots — if a loop is running, it'll infer that an approved review means polling is unnecessary. Embedding caller-specific logic in the skill creates instructions that are wrong in other contexts.

## Multi-Session Skills Need Git Remote Sync

Skills that span multiple sessions and create PRs between runs (e.g., batch extraction workflows) must sync with the remote before creating new branches. Local `main` goes stale between sessions as PRs merge. Add a `git fetch origin main` step early in the continue/resume flow, and suggest creating a fresh branch from `origin/main` if the current branch is behind or diverged.

## Hub-and-Spoke for Authoring Guides

When authoring knowledge spans multiple content types (skills, guidelines, learnings, personas), organize as a routing hub + per-type spokes rather than a monolithic file or scattered fragments. The hub stays small — routing table, boundary cases, inline guidance for minor types. Spokes handle authoring craft for types with enough depth. This enables selective loading (pay tokens only for the type you're writing) and clean ownership (each spoke stays in its lane).

Naming convention: use a shared prefix (`claude-authoring-*`) to group the cluster and separate from platform knowledge files (`claude-code-*`).

## Guidelines-to-Skills Migration

### Guideline-to-skill conversion signal

Guidelines are always-loaded context (`@`-referenced from CLAUDE.md); skills load on invocation. The conversion signal: procedural workflows with clear invocation triggers. "Do X when triggered" = skill. "Always behave this way" = guideline. Reserve guidelines for rules that genuinely apply to every interaction.

### Skill naming convention: prefix by taxonomy domain

When skill count grows, prefix filenames by domain taxonomy (e.g., `git-create-pr.md`, `git-cascade-rebase.md`) rather than flat names. Pattern: `{domain}-{action}.md`. Apply retroactively in a single atomic PR to avoid transitional inconsistency.

### Consolidate guidelines by removing skill commands that duplicate inline knowledge

When guidelines already document how to run commands (e.g., exact CLI invocations), dedicated skill files wrapping those same commands add no value. Delete the skill when the guideline already covers it.

### Meta-guidelines for skill creation belong in always-loaded context

When converting guidelines to skills, a companion `skill-design.md` guideline codifying skill structure belongs in always-loaded context — it governs the quality of all future skill creation.

## User Interaction Points

Mark steps where user input is needed:
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

## Analyzing Skills for Token Optimization

Periodically review skills 100+ lines to identify content extractable into conditional reference files.

| Content Type | Extract? | Threshold |
|---|---|---|
| Core instructions | No | Always needed |
| Templates, examples, reference tables | Yes | 10+ lines, only needed situationally |
| Edge case documentation | Maybe | 20+ lines |

**Evaluate extraction benefit:** 50+ lines situational = high value, 20-50 = medium, <20 = overhead exceeds benefit. Don't extract content under 15 lines, needed on every invocation, or that loses context when separated.

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

## Runtime Instructions Belong at Point of Use

Instructions that affect agent behavior during skill execution (e.g., "use templates verbatim", "don't simplify commands") must live where the agent reads them at runtime — in the template file, reference file, or SKILL.md itself. Putting them in learnings files only helps during authoring/curation sessions, not during execution. The test: "will the agent see this when it matters?"

## Skills Must Search All Three Learnings Locations

Skills that glob learnings for domain context should search all three locations: `~/.claude/learnings/` (global), `~/.claude/learnings-private/` (private), and `docs/learnings/` (project-local). Missing a location means the skill can't ground its responses in available knowledge. This mirrors the learnings search protocol in `context-aware-learnings.md`.

## Skill Deduplication: Platform-Specific vs Platform-Agnostic

When a platform-agnostic skill (e.g., `address-request-comments`) supersedes a platform-specific one (e.g., `address-pr-review`), check whether the older skill is still referenced or should be removed. Keeping both causes confusion about which to invoke and risks the older one falling out of sync with improvements made to the newer version.

## Skill Decomposition by Execution Path

When a skill has mutually exclusive execution paths (e.g., "content mode" vs "skill mode"), split mode-specific steps into conditional reference files loaded after the mode is determined. This saves context — the unused mode's instructions never load.

**Decision criteria:**
- Paths must be truly independent (never both active in one invocation)
- Savings must exceed coordination cost (an extra Read + cross-file references)
- Report templates and apply actions travel with their mode — they're consumed together, so grouping them avoids extra files

**Anti-pattern: single-file conditional split.** Putting all conditional content into one reference file that's always loaded just adds indirection without saving context. Splits only help when they actually gate content out. Similarly, splitting report templates into their own file when they're always loaded alongside their mode is pure overhead.

**Mode variants stay with their parent mode.** When a mode has a variant (e.g., "broad sweep" is content mode at a different granularity), keep it in the mode's file rather than in the shared SKILL.md or a third file. It's the same execution path with different entry conditions — splitting it out would add coordination cost without meaningful savings.

## Structured Footnote for External Platform Posts

Skills that post to external platforms should include the structured footer from `process-conventions.md` § "Structured footnotes for multi-agent comment identity." The `Persona + Role` composite key enables filtering comment chains — the same persona may act as both Reviewer and Addresser on the same PR. Skills filter their own previous comments by matching both fields, not by username (which catches all comments regardless of role).

## Reference Platform Command Sections by Name, Don't Inline

Skills should reference sections in the platform commands file (e.g., "use **Fetch Diff** from the platform commands file") rather than inlining `gh`/`glab` commands. This keeps skills platform-agnostic — the commands file handles GitHub vs GitLab differences. Inline commands are only appropriate before the commands file is loaded (e.g., platform detection in step 0).

## Cross-Skill Discovery via Cross-Refs

1. **Add "Cross-Refs" section** to skills that have natural follow-ups (table with Next Step → Skill columns)
2. **Reference prerequisite skills** in Important Notes (e.g., "Use `/git:explore-pr` first if you need to understand the PR before splitting")

## Base Reviewer Persona with Extends

Universal review knowledge (code quality instincts, process conventions) belongs in a base `reviewer` persona that domain-specific reviewer personas extend via `## Extends: reviewer`. This ensures every reviewer gets the baseline quality bar without each persona duplicating the same proactive loads. Domain-specific personas add only their unique loads and judgment lens.

## Nest Platform-Specific References in Subdirectories

When reference files are platform-specific (GitHub vs GitLab), nest them in `github/` and `gitlab/` subdirectories rather than using flat prefix naming (`github-foo.md`, `gitlab-foo.md`). Benefits: shorter filenames, natural grouping, cleaner paths in skill instructions. The index file (`commands.md`) lives inside each subdirectory alongside its cluster files.

## Brace-Expansion Path Format for Platform References

Use `~/.claude/skill-references/{github,gitlab}/file.md` in skill instructions rather than "read `file.md` from `dir/github/` or `dir/gitlab/`". The brace-expansion format is a single resolvable path expression. The split format requires assembling a filename with one of two directory options — more cognitive overhead, same information.

## Sweep Sub-Reference Files During Restructuring

When renaming or restructuring reference file paths, sweep conditional reference files (edge-cases, re-review-mode, lgtm-verification, etc.) — not just the parent SKILL.md. These sub-references often contain inline mentions like "see the platform commands file" that also need updating. Use `grep -rn` across the entire `commands/` tree to catch all occurrences.

## Skill Namespace Migration Blast Radius

When renaming a skill namespace (e.g., `ralph:init` → `ralph:research:init`), the SKILL.md files are the obvious targets but infrastructure references are the most commonly missed. Trace all of these: runner script paths (wiggum.sh), hook marker patterns in lib-hooks.sh (used for idempotent injection/cleanup), worktree prefix patterns in cleanup skills, output directory paths across sibling skills (brief/resume/compare may reference different paths than init), and learnings files that document the architecture. Grep the entire `.claude/` tree for the old path fragments before declaring the migration complete.

## Numeric Arg = PR/MR Number Convention

Git skills that operate on a PR/MR should treat a numeric positional arg as a PR/MR number: resolve head/base branches via `gh pr view <N>` / `glab mr view <N>`, check out the branch if needed. Already standard in: address-request-comments, code-review-request, explore-request, split-request, resolve-conflicts. Non-numeric positional args remain branch names or other skill-specific inputs. When adding PR/MR support to a skill, also handle URL args (extract the number) and fall back to current branch detection.

## Persist Staging Directories with .gitkeep

Skills that write temp files to a staging directory (e.g., `tmp/change-request-replies/`) should persist the directory with a `.gitkeep` and gitignore the contents (`*.md`, `*.json`). This avoids `mkdir -p` permission prompts on every invocation. Remove `mkdir -p` from skill templates once the directory is tracked.

## Worktree Branches Block `gh pr checkout`

`gh pr checkout` fails when the target branch is already checked out in a worktree (`fatal: '<branch>' is already used by worktree at '<path>'`). Skills should detect this and work from the worktree path instead. Check `git worktree list` for the branch name, extract the worktree path, and use `git -C <worktree-path>` for subsequent operations. Avoid `cd` into the worktree — it shifts the shell's CWD, breaking relative paths in later commands. See also: `claude-code.md` for worktree platform mechanics.

## Sweep Both Platforms When Fixing Reference Files

When fixing a bug in a platform-specific reference file (e.g., `github/comment-interaction.md`), always check and fix the equivalent file for the other platform (`gitlab/comment-interaction.md`). Same applies to `pr-management.md` and any other paired files. The fix is often mechanical (same pattern, different CLI syntax), but skipping it guarantees drift.

## When to Extract Skill References

The signal to extract shared logic into `skill-references/` is **having to make the same change in two skills** — not a stability analysis of the shared code. If the patterns are still evolving, that's fine — evolving in one place is cheaper than evolving in two. Organize shared references topically (sections skills read selectively) rather than procedurally (step numbers that couple to consumer skills).

## Cross-Refs

- `~/.claude/learnings/claude-authoring-content-types.md` — routing hub for the authoring cluster; boundary cases between content types
- `~/.claude/learnings/skill-platform-portability.md` — platform features, frontmatter fields, cross-platform compatibility (complements the design-pattern focus here)
- `~/.claude/learnings/multi-agent-patterns.md` — agent-to-agent collaboration architecture (review cycles, auto-implementation patterns migrated from here)
- `~/.claude/learnings/process-conventions.md` — structured footnote template for multi-agent comment identity
- `~/.claude/learnings/claude-authoring-polling-review-skills.md` — polling loops, quick-exit logic, re-review detection, reviewer timestamps
