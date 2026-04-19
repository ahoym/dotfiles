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

- `/learnings:compound` - Capture learnings from current session

## Reference Files (conditional — read only when needed)

- `~/.claude/learnings/claude-authoring/routing-table.md` — Read if categorization is ambiguous
- `skill-template.md` — Read only when a Skill-type learning is selected
- `~/.claude/learnings/claude-authoring/skill-design.md` — Read only when a Skill-type learning is selected
- `iterative-loop-design.md` — Read only when learning involves iterative/loop patterns
- `public-release-review.md` — Read when learning will be shared publicly or across repos

## Instructions

1. **Identify learnings from current session**:
   - Review the conversation for new patterns, processes, or guidelines discovered
   - Review for approaches or decisions that worked well — patterns worth reinforcing or expanding
   - Review for existing learnings that proved valuable (validates the learning, may suggest broadening scope)
   - **Review all implemented changes** (edits, fixes, file writes) — not just experiments or surprising results. Each fix encodes knowledge: a design principle, an API behavior, a platform constraint. Ask "what did I need to know to make this change?" for each one.
   - List each learning with a brief description
   - Categorize using this decision tree:
     - Command with clear, repeatable steps? → **Skill**
     - Gap in a skill you just ran? → **Fix the skill** (not a learning about the gap)
     - Changes behavior or approach? → **Guideline**
     - Reference info, patterns, or examples? → **Learning**
   - Assess scope for each learning:
     - References project-specific entities (table names, API endpoints, service names, config values, internal tooling) → **Project-local**
     - Broadly reusable pattern, no context-specific details → **Global**
     - Useful across projects but too specific to share (internal tool names, team conventions, proprietary domain details) → **Private**

2. **Display learnings for selection**:

   **ALWAYS use a markdown table** — never use section breaks, horizontal rules, or prose paragraphs to list learnings.

   ```
   Identified learnings from this session:

   | # | Learning | Type | Scope | Target File | Utility |
   |---|----------|------|-------|-------------|---------|
   | 1 | LGTM verification process | Skill | Global | ~/.claude/commands/address-pr-review/SKILL.md | High - novel project pattern |
   | 2 | Co-authorship in PR replies | Guideline | Global | ~/.claude/guidelines/git-workflow.md | Low - already documented |
   | 3 | SessionEnd hook configuration | Learning | Global | ~/.claude/learnings/ci-cd.md | High - useful reference |
   ```

   **Target file paths** — Read `~/.claude/learnings-providers.json` and route each learning by scope:
   - Match the learning's scope to a provider entry whose `writeScope` matches. The provider with `defaultWriteTarget: true` is the default for Global scope.
   - **Project-local** → `projectLocal.path` in the current project repo

   **Utility ratings** (self-assessment of value to Claude):
   - **High** - Novel pattern I wouldn't know without documenting, OR proven pattern worth reinforcing/expanding
   - **Medium** - Useful reminder, but I could rediscover if needed
   - **Low** - Standard knowledge or already documented (shown for transparency)

   **Auto-save High and Medium-utility learnings.** High and Medium learnings are automatically included — they represent patterns worth preserving without asking.

   **Low-utility learnings — skip the prompt.** Show them in the table for visibility but do NOT prompt the operator to select. If all identified learnings are Low, state "No High/Medium learnings identified — nothing to save." and exit the compound step. The table provides the transparency; the prompt adds friction with a predictable "none" answer.

   **When High/Medium learnings exist alongside Low ones**, auto-save the High/Medium and skip the Low without prompting.

   After the table, clearly state which learnings will be auto-saved:
   ```
   Auto-saving N High/Medium-utility learning(s). Skipping N Low-utility learning(s).
   ```

   Combine the auto-saved items into `SELECTED_LEARNINGS`.

   **Do NOT proceed until auto-save list is confirmed (or no learnings qualify).** If no learnings are High/Medium, inform the operator and exit.

3. **Write learnings to files**:
   - If any Skill-type learning is selected: read `skill-template.md` and `~/.claude/learnings/claude-authoring-skills.md` first
   - **Conciseness gate** — before writing each learning, draft the content mentally and cut it to the minimum that preserves intent. Rules:
     - Aim for one to two sentences per insight. A second sentence is fine for the "why" or a key caveat — if it needs three, consider splitting the insight.
     - Lead with the rule or pattern, not the story. Drop "I discovered that…" framing.
     - Use `code` or terse structure (` → `, `|` tables, bullet fragments) over prose when meaning is preserved.
     - No hedging ("might", "could potentially", "it seems like"). State the pattern.
     - After drafting, re-read and ask: "Can I cut any words without losing the teaching?" If yes, cut.
   - For each item in `SELECTED_LEARNINGS`:
     - Read the target file (`~/.claude/<relative-path>`) to check if it exists
     - **Existing file**: use Edit to append new sections (find a unique string near the end, replace with itself + new content)
     - **New file** (Read returned error): use Write with full content
   - File placement rules:
     - **Skills** → `~/.claude/commands/<skill-name>/SKILL.md`
     - **Guidelines** → `~/.claude/guidelines/<guideline-name>.md`
     - **Learnings** → resolve `localPath` from the provider whose `writeScope` matches the learning's scope. Project-local learnings use `projectLocal.path` (relative to project root).
   - **Multi-provider write:** For each **Global** learning, write to all providers with `writeScope: "global"` and `writable: true` (not just the `defaultWriteTarget`). **Early exit:** if only one `writeScope: "global"` provider exists (count providers first from `learnings-providers.json`), skip multi-write silently — don't deliberate, don't ask the operator. For each additional writable provider beyond the default:
     - Use `localPath` from the provider entry as the write target
     - **New file**: add an index entry to the provider directory's `CLAUDE.md` (format: `` - `filename.md` — one-sentence description ``)
     - **Existing file**: no index update needed unless the description is stale
     - Cross-refs in the copy must use paths relative to the provider's `localPath` (rewrite any `~/.claude/learnings/` refs)

4. **Verify and report**:
   - Read back each written file to confirm content was saved correctly
   - Output a summary:
     ```
     Updated files:
     - <path> — <what was added> (Utility: <High/Medium/Low>)
     - <provider path> — multi-provider write (if applicable)

     Wrote N learnings. Wrote M to additional providers.
     ```

## Prerequisites

For prompt-free execution, add these allow patterns to **user-level** `~/.claude/settings.local.json`:

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

**Additional providers** (optional):

Add provider entries to `~/.claude/learnings-providers.json` to enable writing to additional directories (e.g., team learnings). Each provider with `writable: true` and a matching `writeScope` will receive writes. The `~/.claude/learnings*/**` wildcard pattern covers all provider directories that follow the `learnings-<name>/` naming convention.

## Important Notes

- Prefer updating existing files over creating new ones
- Keep learnings atomic — one concept per section
- **Write concisely** — every token costs context budget when loaded. The conciseness gate in step 3 is mandatory, not advisory. If a learning reads like a paragraph, it's too long. **Exception: concise code examples are high-value**, not verbosity — agents copy them directly. A 3-line working command example is worth more than a paragraph explaining the same thing.
- **Type selection when unsure**: Learning > Guideline > Skill (least to most structured)
- **Strip provenance before writing.** Remove "discovered while building X" / "learned during Y project" notes — they add no teaching value and leak project context into global learnings. The pattern itself is what matters. (See also: `learnings/claude-authoring-learnings.md` → "Provenance vs structural content")
- Be honest in utility self-assessments
