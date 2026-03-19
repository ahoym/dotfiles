# Learnings Search Protocol

## Index-Based Loading

`~/.claude/learnings/CLAUDE.md` is a curated index of all learnings files with one-line descriptions grouped by domain. At each gate below, **also read the index** and load any files whose description matches the task domain — in addition to the pipeline search. Both mechanisms run in parallel; source attribution in announcements (see Observability) tracks which is doing the work so we can decide whether to consolidate.

If `~/.claude/learnings-private/CLAUDE.md` exists, read it too. If `docs/learnings/CLAUDE.md` exists in the current project, read it for repo-local learnings.

## Hard Gates (non-negotiable — do not skip under any circumstances)

1. **Session start**: Before your FIRST tool call, glob `~/.claude/learnings/`, `~/.claude/learnings-private/`, and `docs/learnings/` for `*.md`. Match filenames against ambient context + user message. Announce results (including no-matches).
2. **Plan mode entry**: Before calling `EnterPlanMode`, search learnings broadly (filenames + content grep). Plans lock in decisions that are expensive to reverse. Set a persona if none is active — plan mode entry means the task warrants it.
3. **Implementation start**: Before executing an approved plan, glob `~/.claude/commands/set-persona/` and `.claude/personas/` against the task's technology stack. Match → activate. No match → announce and proceed. Never skip based on perceived task simplicity.

These gates apply even when context is pre-loaded (e.g., `@file` references), the question is narrow, the task feels urgent, or a skill is loaded in the opening message. Skill instructions compete for attention — run the search before executing the skill's steps. No exceptions.

---

## Core search pipeline

Every search follows the same four steps. Gate-specific overrides are noted inline.

**Step 1: Glob all filenames.** Run `*.md` globs on `~/.claude/learnings/` (global), `~/.claude/learnings-private/` (private), and `docs/learnings/` (project-local, if it exists) to get the full inventory. Filenames are the index — designed to be scannable.

**Step 2: Derive search terms.** Sources vary by gate:
- **Session start**: ambient context + user message. Ambient context is often a stronger signal than the opening question:
  - **Branch name**: `consolidate/2026-02-28` → "consolidat", "ralph"
  - **CWD path**: `claude/worktrees/consolidate-*` → same domain signal
  - **Git status snippet**: branch, recent commits, changed files — scan for domain keywords
  - **CLAUDE.md / project context**: technologies mentioned (e.g., "Spring Boot", "PostgreSQL", "Vault")
  - **User's message**: extract topic terms
  - If no ambient context is available (fresh repo, no git), fall back to message-only matching.
- **Plan mode**: *current task scope* (which may have evolved from the opening message). Cast a wider net:
  - Direct topic terms (e.g., "orderbook", "depth")
  - Technologies and libraries involved (e.g., "BigNumber", "xrpl", "Next.js")
  - Patterns being applied (e.g., "caching", "singleton", "API design")
  - Adjacent domains that might have relevant gotchas

**Step 3: Match and sniff.** Compare filenames against derived terms. Match broadly — `spring-boot.md` matches "Spring Boot", "startup dependencies", "Flyway", etc. Don't embed search terms into glob patterns (e.g., `*spring*`) — that misses hyphenated and compound filenames.

For each match, `Read(file_path, limit=5)` to see the title and description. Skip on domain mismatch and announce: `📚 Skipped <file> (domain mismatch: <reason>)`. Only fully load files where the sniff confirms relevance. Cost: ~50 tokens per sniff vs ~500-2000 for a false-positive full load.

**Plan mode addition**: also grep file *content* for derived terms — filename-only matching misses learnings buried under a broader topic (e.g., a caching gotcha inside `spring-boot.md` when the search term is "Redis").

**Step 4: Follow cross-refs (up to two levels).** After loading matched files, check `## Cross-Refs` sections for additional files. Follow only when relevant; stop when the next file isn't on-topic. Announce cross-ref loads distinctly from keyword loads.

**Plan mode addition**: also announce skipped cross-refs: `📚 Cross-ref from X → Y (skipped: not relevant to current task)`. Too noisy for session-start.

## Gate-specific notes

**Session start** — one filename glob, no content grep. Keep it cheap so narrow opening questions don't tempt skipping.

**Plan mode** — filename glob + content grep. Plans lock in decisions that are expensive to reverse, so the extra search cost is justified. Use enhanced announcement format:
```
📚 Plan mode — terms: ["spring boot", "migration", "flyway"] from task scope
   Matched: spring-boot-gotchas.md (via both)
   Matched: spring-boot.md (via index)
   Cross-ref: → postgresql-query-patterns.md (via cross-ref, migration patterns)
   Cross-ref: → java-observability-gotchas.md (skipped: not relevant)
   No match: "flyway"
```

## Soft gates (proactive)

Two structural triggers catch domain keywords that the hard gates miss. Both glob `~/.claude/learnings/`, `~/.claude/learnings-private/`, and `docs/learnings/` for matching filenames. Both follow the same dedup rule: don't re-load files already read earlier in the session (when context compression makes load history uncertain, err toward re-checking rather than blindly re-loading).

### User-message domain shift

When a user message introduces a domain not present in earlier messages, treat it as a soft gate trigger **before responding**. The anchor is the user message itself — scan it for domain keywords that map to learnings filenames and haven't been loaded yet. This catches conversational domain shifts (e.g., the user pivots from React work to asking about Fargate).

### Pre-edit domain check

Before your first Edit/Write touching a file whose technology domain hasn't been loaded from learnings yet, glob for matching files. This catches execution-time domain shifts — you're already performing the Edit, so the check piggybacks on an existing action like the hard gates do (e.g., editing a Python file when no Python learnings have been loaded).

### Shared properties

- Learnings filenames are the index — `aws-patterns.md`, `vercel-deployment.md`, `bignumber-financial-arithmetic.md`
- Works with or without an active persona
- Cost: low (reading a file). Upside: shapes thinking before decisions are made.

## Observability

Always announce when learnings are loaded or searched — the user needs visibility to iterate on this system. No-match announcements are **mandatory** (they surface gaps and confirm the system is firing).

**Source attribution** — every load announcement must tag how the file was found. This tracks whether the index or pipeline is doing the work, so we can decide whether to consolidate.

Tags: `(via index)` — matched from index description · `(via pipeline)` — matched from filename glob/sniff · `(via both)` — matched independently by both · `(via content grep)` — plan-mode content search · `(via cross-ref)` — followed from another file's Cross-Refs section · `(via domain shift)` / `(via pre-edit check)` — soft gate triggers

Formats: `📚 Session start — loaded X (via index, reason)` · `📚 Session start — loaded X (via pipeline, reason)` · `📚 "keyword" → loaded X (via index)` · `📚 Searched for "X" — no matches` · `📚 Cross-ref from X → loaded Y (via cross-ref, reason)` · `📚 Cross-ref from X → Y (skipped: not relevant)` (plan-mode only)

Persona checks: `🎭 No persona active — recommending X. Set it?` · `🎭 Persona active: X — proceeding` · `🎭 No persona — none relevant, proceeding without`

## Relationship to Personas

Personas provide a **lens** (priorities, tradeoffs, posture). Learnings provide **knowledge** (gotchas, patterns, facts). This guideline makes knowledge active regardless of whether a persona is set.

**Subagent persona propagation.** Subagents get this protocol but rarely enter plan/implementation phases, so persona gates (#2–3) don't fire. When launching a subagent for domain work, include a persona filename in the prompt — the orchestrator has better context for selection. Skip for utility tasks.
