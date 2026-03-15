# Learnings Search Protocol

## Hard Gates (non-negotiable — do not skip under any circumstances)

1. **Session start**: Before your FIRST tool call, glob `~/.claude/learnings/`, `~/.claude/learnings-private/`, and `docs/learnings/` for `*.md`. Match filenames against ambient context + user message. Announce results (including no-matches).
2. **Plan mode entry**: Before calling `EnterPlanMode`, search learnings broadly (filenames + content grep). This is the most valuable checkpoint — plans lock in decisions that are expensive to reverse.
3. **Implementation start**: Before executing an approved plan, check if a persona is active. If not, recommend one by matching `~/.claude/commands/set-persona/` and `.claude/personas/` filenames against the task domain. Announce the check.

These gates apply even when context is pre-loaded (e.g., `@file` references), the question is narrow, or the task feels urgent. No exceptions.

---

## How to search (session start)

One filename glob, no content grep — keep it cheap so narrow opening questions don't tempt you to skip it.

**Step 1: Glob all filenames.** Run `*.md` globs on `~/.claude/learnings/` (global), `~/.claude/learnings-private/` (private), and `docs/learnings/` (project-local, if it exists) to get the full inventory. This is the index — filenames are designed to be scannable.

**Step 2: Derive search terms from ambient context + user message.** Ambient context is often a stronger domain signal than the opening question:
- **Branch name**: `consolidate/2026-02-28` → "consolidat", "ralph"
- **CWD path**: `.claude/worktrees/consolidate-*` → same domain signal
- **Git status snippet**: the session-start git status in the system prompt contains branch, recent commits, and changed files — scan for domain keywords
- **CLAUDE.md / project context**: technologies mentioned (e.g., "Spring Boot", "PostgreSQL", "Vault") → search terms
- **User's message**: extract topic terms as before

**Step 3: Match filenames against terms.** Compare the inventory from step 1 against derived terms. Match broadly — `spring-boot.md` matches "Spring Boot", "startup dependencies", "Flyway", etc. because the file covers the whole domain. Don't embed search terms into glob patterns (e.g., `*spring*`) — that misses hyphenated and compound filenames.

Load matches and announce. If no ambient context is available (fresh repo, no git), fall back to message-only matching.

**Step 4: Follow cross-refs (one level).** After loading matched files, check their `## See also` sections for additional files to load. Follow cross-refs one level deep — don't recurse (that's unbounded). Only follow refs that appear relevant to the current context. Announce cross-ref loads distinctly from keyword loads.

## How to search (plan mode entry)

Search broadly, not just the obvious keywords. Derive search terms from the *current task scope* (which may have evolved significantly from the opening message), not just the surface-level topic. Include:
- Direct topic terms (e.g., "orderbook", "depth")
- Technologies and libraries involved (e.g., "BigNumber", "xrpl", "Next.js")
- Patterns being applied (e.g., "caching", "singleton", "API design")
- Adjacent domains that might have relevant gotchas

Glob `~/.claude/learnings/`, `~/.claude/learnings-private/`, and `docs/learnings/` filenames + grep content for all of the above. Load and announce matches.

**Follow cross-refs (one level).** Same as session-start step 4 — check `## See also` sections on loaded files. In plan mode, also announce skipped cross-refs: `📚 Cross-ref from X → Y (skipped: not relevant to current task)`. This negative announcement is plan-mode only (too noisy for session-start).

**Enhanced plan-mode announcement format.** Include derived search terms, not just results:
```
📚 Plan mode — terms: ["spring boot", "migration", "flyway"] from task scope
   Matched: spring-boot-gotchas.md, spring-boot.md
   Cross-ref: → postgresql-query-patterns.md (migration patterns)
   Cross-ref: → java-observability-gotchas.md (skipped: not relevant)
   No match: "flyway"
```

## Confidence-level gate (soft — experimental)

Before drafting substantial domain-specific content (20+ lines), ask: **"Am I working from loaded knowledge or training memory?"** If you haven't read learnings files in this domain during this session, search first. The user's learnings contain calibrated gotchas and decisions that training knowledge misses.

**Binary self-check**: "Have I loaded files in this domain? Yes/no." Fires when creating/modifying skills, guidelines, learnings, personas, CLAUDE.md; writing architecture docs, design proposals, or reviews; synthesizing domain knowledge into structured artifacts.

Announce: `📚 Confidence check — working from training, not loaded knowledge. Searching learnings for "<domain>"...`

Soft because there's no tool-call trigger — it relies on self-awareness at the moment of drafting. Fires sometimes, not always, but quality improvement is substantial when it does.

## Keyword-based (proactive)

When a domain keyword appears in conversation (e.g., "Fargate," "Terraform," "Vercel," "BigNumber"), glob `~/.claude/learnings/`, `~/.claude/learnings-private/`, and `docs/learnings/` for matching files by filename. Load on first mention of a domain keyword that maps to a learnings file.

- Learnings filenames are the index — `aws-patterns.md`, `vercel-deployment.md`, `bignumber-financial-arithmetic.md`
- Works with or without an active persona
- Cost: low (reading a file). Upside: shapes thinking before decisions are made.

## Observability

Always announce when learnings are loaded or searched — the user needs visibility to iterate on this system. No-match announcements are **mandatory** (they surface gaps and confirm the system is firing).

Formats: `📚 Session start — loaded X (reason)` · `📚 "keyword" → loaded X` · `📚 Searched for "X" — no matches` · `📚 Cross-ref from X → loaded Y (reason)` · `📚 Cross-ref from X → Y (skipped: not relevant)` (plan-mode only)

Persona checks: `🎭 No persona active — recommending X. Set it?` · `🎭 Persona active: X — proceeding` · `🎭 No persona — none relevant, proceeding without`

## Relationship to Personas

Personas provide a **lens** (priorities, tradeoffs, posture). Learnings provide **knowledge** (gotchas, patterns, facts). This guideline makes knowledge active regardless of whether a persona is set.
