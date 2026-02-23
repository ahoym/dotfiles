# Skill Design Patterns

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

## "LLM Knows X" ≠ "LLM Consistently Applies X"

When deciding whether to codify a pattern, the question isn't "can the model execute this when asked?" but "does it reliably do so unprompted?" Textbook patterns (extract class, DRY, factories) that the model knows but doesn't consistently apply during implementation still warrant codification — as a lightweight checklist reminder, not a tutorial. The correct form factor is a slim reference file (~15 lines) that reminds, not a 229-line reference file that teaches.

## Stale Path References Are the Primary Skill Maintenance Issue

Skills referencing specific file paths (`~/.claude/lab/script.sh`, `docs/learnings/topic.md`) go stale when files are moved, deleted, or renamed. In curation of 4 skills, 2 had broken path references. During curation, verify every file path in SKILL.md and reference files actually resolves. Paths to external scripts and cross-directory references are more fragile than paths within the skill's own directory.

**Symlink gotcha:** `~/.claude/` subdirectories are directory-level symlinks to the dotfiles repo. `Glob` doesn't reliably resolve paths through these symlinks — a file can exist but Glob reports "No files found." Always verify path existence with `Read` (which resolves symlinks correctly), not `Glob`.

