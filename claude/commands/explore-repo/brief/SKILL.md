---
name: brief
description: "Load explore-repo scan artifacts into context and produce a concise repository brief for Q&A."
---

# Brief an Explore-Repo Scan

Load scan artifacts produced by `/explore-repo` and produce a concise synthesis. After the brief, the agent is ready for follow-up Q&A about the repository.

## Usage

- `/explore-repo:brief` - Brief the current repo's scan (default: `docs/learnings/`)
- `/explore-repo:brief <path>` - Brief scan artifacts at a custom path

## Instructions

### 1. Locate artifacts

Determine whether a usable scan exists.

1. **Resolve artifact path:**
   - If `$ARGUMENTS` is provided, use it as the artifact directory
   - Otherwise, use `docs/learnings/` in the current working directory

2. **Glob for all expected files** (run in parallel):
   - `<path>/structure.md`
   - `<path>/api-surface.md`
   - `<path>/data-model.md`
   - `<path>/integrations.md`
   - `<path>/processing-flows.md`
   - `<path>/config-ops.md`
   - `<path>/testing.md`
   - `<path>/SYSTEM_OVERVIEW.md`
   - `<path>/inconsistencies.md`

3. **Classify scan state and gate on SYSTEM_OVERVIEW.md:**

   | Condition | Action |
   |-----------|--------|
   | No files found at all | Error: "No scan artifacts found. Run `/explore-repo` first to scan this repository." **Stop.** |
   | Some domain files but no SYSTEM_OVERVIEW.md | Error: "Scan artifacts found (N/7 domains) but no synthesis yet. Run `/explore-repo` to complete the scan and generate SYSTEM_OVERVIEW.md." **Stop.** |
   | All 7 domain files but no SYSTEM_OVERVIEW.md | Error: "Scan complete but not yet synthesized. Run `/explore-repo` again to generate SYSTEM_OVERVIEW.md." **Stop.** |
   | SYSTEM_OVERVIEW.md exists | Continue to Phase 2 |

4. **Check freshness:**
   - Read the scan metadata from SYSTEM_OVERVIEW.md (first 10 lines) — extract `commit`, `branch`, and `date` fields
   - Run `git rev-parse --short HEAD` to get the current commit
   - If the commits differ, run a **source diff check** to see if anything meaningful changed:
     ```bash
     git diff --name-only <scan-commit>..HEAD -- ':!<artifact-path>/' ':!**/CLAUDE.md'
     ```
     where `<artifact-path>` is the artifact directory resolved in step 1 (e.g., `docs/learnings`).
     - If the diff is **empty** — only scan artifacts and CLAUDE.md files changed since the scan → treat as **current** (the scan commit created these docs, not a code change)
     - If the diff is **non-empty** — source code changed → mark as **stale** and save the list of changed files for the brief output
   - If commits are identical → **current**

---

### 2. Load context

Read files to build the context needed for the brief and Q&A.

1. **SYSTEM_OVERVIEW.md** — read fully (core context, the primary source for the brief)
2. **inconsistencies.md** — read fully if present (short, high-value)
3. **Domain files** — for each existing file, read from the top through the end of the `## Key Findings` section (i.e., until the next `##` heading after Key Findings). This captures metadata + Overview + Key Findings regardless of section length. Full content will be lazy-loaded during Q&A when deeper detail is needed.

---

### 3. Print brief

Output the following to the conversation (do NOT write to a file):

```markdown
# Repository Brief: <Project Name>

**Scan**: commit `<hash>` on `<branch>` at `<date>` [⚠️ stale — HEAD is `<current>`]

## Overview
<2-3 sentences from SYSTEM_OVERVIEW.md project summary>

## Architecture
<Key patterns from SYSTEM_OVERVIEW.md architecture section — component relationships, module dependency highlights>

## Domain Scan Summary
| Domain | Status | Highlights |
|--------|--------|------------|
| Structure | ✅ current / ⚠️ stale / ❌ missing | <1-line from Key Findings> |
| API Surface | ... | ... |
| Data Model | ... | ... |
| Integrations | ... | ... |
| Processing Flows | ... | ... |
| Config & Ops | ... | ... |
| Testing | ... | ... |

## Cross-Cutting Patterns
<Top 3-5 patterns from SYSTEM_OVERVIEW.md cross-cutting patterns section>

## Critical Path
<Top 3-5 files/docs from SYSTEM_OVERVIEW.md "Critical Path to Productivity" section>

## Documentation Health
<Gap counts by severity from SYSTEM_OVERVIEW.md documentation gaps section>
<Inconsistency counts from inconsistencies.md — omit this line if the file doesn't exist>

## 💡 Persona Suggestion
<Conditional — see Phase 4. Omit entire section if skipped.>

---
*Context loaded. Ask me anything about this repository.*
```

**Domain status logic:** For each domain file:
- File doesn't exist → ❌ missing
- Domain's `commit` matches SYSTEM_OVERVIEW.md's `commit` → inherit overall scan freshness (✅ current or ⚠️ stale)
- Domain's `commit` differs from SYSTEM_OVERVIEW.md's `commit` (partial rescan) → run the same source diff check independently for that domain's commit

If any domains are missing or stale, add a note after the table: `Run \`/explore-repo\` to update missing or stale domains.`

**Stale scan line:** Only include `[⚠️ stale — HEAD is <current>]` if the source diff check determined the scan is stale (meaningful source files changed). Omit it when the only changes since the scan commit are scan artifacts and CLAUDE.md files.

**Changed files hint:** When the scan is stale, append a collapsed summary after the Domain Scan Summary table showing the changed source files:
```markdown
<details><summary>N source files changed since scan</summary>

- path/to/changed/file1.kt
- path/to/changed/file2.java
</details>
```

---

### 4. Persona suggestion (conditional)

**Skip this entire section if** a `/set-persona` activation appears earlier in the conversation history (the agent knows from context whether a persona is already active).

If no persona is active:

1. Extract the primary language and framework from the loaded SYSTEM_OVERVIEW.md context
2. Glob for available persona files:
   - Project-local: `.claude/personas/*.md`
   - Shared: `~/.claude/commands/set-persona/*.md` (exclude `SKILL.md`)
3. Match using **filenames only** — compare language + framework keywords from the scan against persona filenames (e.g., a Java Spring Boot repo → `java-backend`). Do NOT read persona file contents for matching.
4. **One clear match** → suggest it with a one-liner: `A **<persona-name>** persona is available that matches this stack. Activate with \`/set-persona <name>\`.`
5. **Multiple plausible matches or ambiguous** → ask the user which fits best rather than guessing. List the options with their filenames.
6. **No match** → omit the `## 💡 Persona Suggestion` section entirely

---

### 5. Ready for Q&A

After outputting the brief, all core context is loaded. When the user asks follow-up questions:

- Answer from SYSTEM_OVERVIEW.md + domain file previews (already loaded) first
- If a question requires deeper detail from a specific domain, read the full domain file on demand
- Note when lazy-loading: "Loading full `<filename>` for details..."

## Design Notes

- **No output file** — the brief is printed to conversation, not saved. It's ephemeral context-loading, not a persistent artifact.
- **SYSTEM_OVERVIEW.md is the gate** — without it, the brief can't produce Architecture, Cross-Cutting Patterns, Critical Path, or Documentation Health. Rather than a degraded brief, push the user to complete the scan.
- **Domain files are lazy-loaded** — reading through the end of Key Findings gives enough for the summary table. Full content loads on demand during Q&A to preserve context budget.
- **No branch fallback** — unlike ralph:brief, scan artifacts live in the repo (not on separate research branches), so a path argument is sufficient for multi-repo/worktree cases.
- **Persona detection is conversation-based** — the agent checks its own conversation history for prior `/set-persona` activation. No state file needed.
