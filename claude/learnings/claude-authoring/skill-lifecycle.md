Skill lifecycle and maintenance — stale path references, producer-consumer contracts, hooks placement, maturity progression, operational patterns.
- **Keywords:** skill maturity, stale paths, producer-consumer, hooks placement, skill routing, /loop monitors, incremental fetch, invocation context, git remote sync, worktree branches, .gitkeep staging
- **Related:** ~/.claude/learnings/claude-authoring/skill-evolution.md, ~/.claude/learnings/claude-code/skill-platform-portability.md, ~/.claude/learnings/process-conventions.md

---

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

## Three-Level Skill Routing Works

Claude Code supports three-level directory nesting for skills: `commands/a/b/c/SKILL.md` routes to `/a:b:c`. Confirmed working with `commands/ralph/consolidate/init/SKILL.md` → `/ralph:consolidate:init`. However, skills created mid-session aren't discoverable until a new session starts — the skill discovery cache is populated at session init. The `Skill` tool returns "Unknown skill" for mid-session additions, but invoking from a separate terminal works immediately.

## Skill Maturity Progression

Skills follow a natural lifecycle: **tight feedback loop** (run, inspect output, fix design gaps) → **edge case discovery** (core works, boundary cases emerge) → **operational refinement** (retro shifts to "was it useful" not "did it work") → **folds into /session-retro** (just another tool, no special scrutiny).

Maturity is per-capability, not per-skill. A fundamental change to one capability (e.g., adding a new content type to a curation loop) pulls that capability back to the tight-feedback stage while the rest of the skill remains mature. This is desirable — it means the system adapts rather than calcifying.

## /loop Supersedes Purpose-Built Monitor Skills

When a domain skill (e.g., `/git:address-request-comments`) fetches fresh state each invocation, pairing it with `/loop` replaces purpose-built monitor skills that maintain their own state tracking. The monitor skill's state management adds complexity without value — the domain skill's stateless design means every invocation is self-contained. Delete the monitor skill; keep the domain skill + `/loop`.

## Incremental Fetch Timestamps Must Derive From Data

When polling for new items (PR comments, notifications, etc.), set `LAST_FETCH_TS` to the `created_at` of the newest item returned — not wall-clock time. Wall-clock creates gaps: if a comment arrives between the API call and the timestamp assignment, the next poll's `since` parameter skips past it. If no items are returned, keep the previous timestamp unchanged.

## Skills Shouldn't Assume Invocation Context

A skill doesn't know whether it was invoked manually, by `/loop`, or by another skill. Skill instructions should describe *what the skill knows* (e.g., "the review is approved") not *what to do about the caller's context* (e.g., "stop the polling loop"). The agent in conversation can connect the dots — if a loop is running, it'll infer that an approved review means polling is unnecessary. Embedding caller-specific logic in the skill creates instructions that are wrong in other contexts.

## Multi-Session Skills Need Git Remote Sync

Skills that span multiple sessions and create PRs between runs (e.g., batch extraction workflows) must sync with the remote before creating new branches. Local `main` goes stale between sessions as PRs merge. Add a `git fetch origin main` step early in the continue/resume flow, and suggest creating a fresh branch from `origin/main` if the current branch is behind or diverged.

## Persist Staging Directories with .gitkeep

Skills that write temp files to a staging directory (e.g., `tmp/claude-artifacts/change-request-replies/`) should persist the directory with a `.gitkeep` and gitignore the contents (`*.md`, `*.json`). This avoids `mkdir -p` permission prompts on every invocation. Remove `mkdir -p` from skill templates once the directory is tracked.

## Worktree Branches Block `gh pr checkout`

`gh pr checkout` fails when the target branch is already checked out in a worktree (`fatal: '<branch>' is already used by worktree at '<path>'`). Skills should detect this and work from the worktree path instead. Check `git worktree list` for the branch name, extract the worktree path, and use `git -C <worktree-path>` for subsequent operations. Avoid `cd` into the worktree — it shifts the shell's CWD, breaking relative paths in later commands. See also: `claude-code.md` for worktree platform mechanics.

## Runtime Fix → Source Fix Reflex

Every fix to a runtime artifact (generated prompt, `let-it-rip.sh`, status.md format) should immediately prompt: "does the source (SKILL.md) need this too?" Runtime artifacts are ephemeral — the SKILL.md generates new ones each run. A fix that only lands in the runtime artifact will be lost on the next invocation.

## Cross-Refs

- `~/.claude/learnings/claude-code/skill-platform-portability.md` — platform features, frontmatter fields, cross-platform compatibility (complements the design-pattern focus here)
- `~/.claude/learnings/process-conventions.md` — structured footnote template for multi-agent comment identity
