---
name: compound
description: "Capture session learnings and save to skills, guidelines, or reference docs under ~/.claude/."
allowed-tools:
  - Read
  - Glob
  - Grep
  - Edit
  - Write
  - AskUserQuestion
  - Skill
---

# Compound Learnings

Save new patterns and learnings from the current session into global skills, guidelines, or learnings under `~/.claude/`.

## Usage

- `/learnings:compound` — Capture learnings from current session

## Providers

Read `~/.claude/learnings-providers.json` to discover available learning destinations. Each entry has:
- `localPath` — where files are written
- `writeScope` — which learning scope routes here (`global` or `private`)
- `writable` — whether this skill may write here
- `defaultWriteTarget` — the canonical Global destination

**Scope routing:**
- **Global** → provider with `defaultWriteTarget: true` (plus any other `writeScope: "global", writable: true` — multi-provider write)
- **Private** → provider with `writeScope: "private"` (e.g., `~/.claude/learnings-private`)
- **Project-local** → `projectLocal.path` in the current project (resolved relative to project root)

Adding a new provider is just an edit to `~/.claude/learnings-providers.json`. The `~/.claude/learnings*/**` permission pattern covers any provider following the `learnings-<name>/` naming convention.

## Prerequisites

For prompt-free execution, add these allow patterns to user-level `~/.claude/settings.local.json`:

```json
"Read(~/.claude/commands/**)",
"Read(~/.claude/learnings-providers.json)",
"Read(~/.claude/learnings*/**)",
"Read(~/.claude/guidelines/**)",
"Write(~/.claude/learnings*/**)",
"Write(~/.claude/commands/**)",
"Write(~/.claude/guidelines/**)",
"Edit(~/.claude/learnings*/**)",
"Edit(~/.claude/commands/**)",
"Edit(~/.claude/guidelines/**)"
```

## Reference Files (conditional — load only when needed)

- `~/.claude/learnings/claude-authoring/routing-table.md` — categorization ambiguous
- `skill-template.md` + `~/.claude/learnings/claude-authoring-skills.md` — authoring a new Skill
- `iterative-loop-design.md` — learning involves iterative/loop patterns
- `public-release-review.md` — learning will be shared publicly or across repos

## Type Reference

Categorize each candidate against this table — it's the source of truth for routing, target paths, and write behavior.

| Type | When | Target | Write behavior |
|------|------|--------|----------------|
| **Skill** | Command with clear, repeatable steps | `~/.claude/commands/<name>/SKILL.md` (new file from template) | Auto-write if High/Medium utility |
| **Skill fix** | Concrete edit to an existing skill file | `<skill-file>:<approx line>` | Per-fix operator confirm (Apply / Skip / Defer) — never auto-applied, never batched |
| **Guideline** | Changes behavior or approach | `~/.claude/guidelines/<name>.md` | Auto-write if High/Medium utility |
| **Learning** | Reference info, patterns, examples | Provider `localPath` per scope (see Providers above) | Auto-write if High/Medium utility |

**Ambiguous type?** Prefer Learning > Guideline > Skill (least to most structured).

**Utility ratings** (apply to Skill / Guideline / Learning — not Skill fix):
- **High** — Novel pattern OR proven pattern worth reinforcing/expanding → auto-write
- **Medium** — Useful reminder; could rediscover if needed → auto-write
- **Low** — Standard knowledge or already documented → shown for transparency, not written

## Instructions

### 1. Identify candidates

- Review the conversation for new patterns, decisions that worked well, validated existing learnings, and **every implemented change** (edits, fixes, file writes). For each fix, ask "what did I need to know to make this change?"
- Categorize each candidate per the **Type Reference**. Assess scope for Learnings.
- **Prefer extending an existing target file** over creating a new one — bias toward consolidation when the topic overlaps existing keywords.
- **Sniff each target file** (`Read(file, limit=80)` or grep keywords) before finalizing utility. If an existing section already covers the pattern → downgrade utility (Medium → Low) or drop. Catches redundancy before the table is built. Skip when the target file doesn't exist yet.

### 2. Display and select

ALWAYS use a markdown table — never section breaks, horizontal rules, or prose paragraphs.

```
Identified learnings from this session:

| # | Description | Type | Scope | Target | Utility |
|---|-------------|------|-------|--------|---------|
| 1 | LGTM verification process | Skill | Global | ~/.claude/commands/address-pr-review/SKILL.md | High |
| 2 | Co-authorship in PR replies | Guideline | Global | ~/.claude/guidelines/git-workflow.md | Low |
| 3 | SessionEnd hook configuration | Learning | Global | ~/.claude/learnings/ci-cd.md | High |
| 4 | Step 10b skip when no workflows | Skill fix | -- | ~/.claude/commands/sweep/address-prs/addresser-prompt.md:~84 | -- |
```

After the table, announce:
```
Auto-writing N High/Medium learning(s). Skipping K Low. M Skill fix(es) require confirmation.
```

If nothing qualifies (no High/Medium AND no Skill fixes) → state so and exit. Otherwise proceed.

### 3. Write

Read each target before writing.

**Skill fix path** (per-fix, never batched, never auto-applied):
1. Read the target skill file to confirm current state at the cited line.
2. Draft the Edit (`old_string` / `new_string`) per the Conciseness gate below.
3. Present the proposed diff via `AskUserQuestion` with options `Apply` / `Skip` / `Defer`.
4. On `Apply` → Edit. On `Skip` → log "skill fix declined" with a one-line reason. On `Defer` → list in step 4 summary as "pending apply."

**Auto-write path** (Skill / Guideline / Learning):
- **Existing file** → Edit to append a new section (anchor on a unique trailing string).
- **New file** (Read returns error) → Write with full content.
- **Multi-provider** (Learnings only): if multiple providers have `writeScope: "global"` and `writable: true`, write to each. For new files in additional providers, add an index entry to that provider's `CLAUDE.md` (`` - `filename.md` — one-line description ``). Cross-refs in the copy use paths relative to that provider's `localPath`. Single-provider setup → skip silently.

**Conciseness gate** (mandatory):
- One to two sentences per insight. A second sentence is fine for the "why" or a key caveat — if three are needed, split the insight.
- Lead with the rule, not the story. Drop "I discovered that…" framing.
- Use `code` or terse structure (` → `, bullet fragments, tables) over prose when meaning is preserved.
- No hedging ("might", "could potentially"). State the pattern.
- **Strip provenance** — no "discovered while building X" / "learned during Y" notes. The pattern itself is what matters.
- **Code examples are high-value, not verbosity.** A 3-line working command beats a paragraph explaining the same thing.

### 4. Verify and report

Read back each written file to confirm. Output:

```
Updated files:
- <path> — <what was added> (Utility: <High/Medium>)
- <provider path> — multi-provider write (if applicable)
- <skill-file>:<line> — applied / declined / deferred (Skill fix)

Wrote N learnings. Applied K skill fixes (D declined, E deferred). Wrote M to additional providers.
```

## Important Notes

- Keep learnings atomic — one concept per section.
