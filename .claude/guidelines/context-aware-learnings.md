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

## How to search (plan mode entry)

Search broadly, not just the obvious keywords. Derive search terms from the *current task scope* (which may have evolved significantly from the opening message), not just the surface-level topic. Include:
- Direct topic terms (e.g., "orderbook", "depth")
- Technologies and libraries involved (e.g., "BigNumber", "xrpl", "Next.js")
- Patterns being applied (e.g., "caching", "singleton", "API design")
- Adjacent domains that might have relevant gotchas

Glob `~/.claude/learnings/`, `~/.claude/learnings-private/`, and `docs/learnings/` filenames + grep content for all of the above. Load and announce matches.

## Keyword-based (proactive)

When a domain keyword appears in conversation (e.g., "Fargate," "Terraform," "Vercel," "BigNumber"), glob `~/.claude/learnings/`, `~/.claude/learnings-private/`, and `docs/learnings/` for matching files by filename. Load on first mention of a domain keyword that maps to a learnings file.

- Learnings filenames are the index — `aws-patterns.md`, `vercel-deployment.md`, `bignumber-financial-arithmetic.md`
- Works with or without an active persona
- Cost: low (reading a file). Upside: shapes thinking before decisions are made.

## Observability

Always announce when learnings are loaded or searched. The user needs visibility to iterate on this system.

**Session start:**
```
📚 Session start — loaded `ralph-loop.md` (branch: consolidate/2026-02-28), `claude-code.md` (message: "worktree")
```

**Keyword trigger:**
```
📚 "Fargate" → loaded `aws-patterns.md`
```

**No matches (ALWAYS announce):**
```
📚 Searched learnings for "Kubernetes" — no matches
```

No-match announcements are **mandatory**. They surface gaps in the learnings library and confirm the system is actually firing. Every search — keyword or hard gate — must announce its result, hit or miss.

## Persona check announcements

```
🎭 No persona active — recommending `xrpl-typescript-fullstack` for this task. Set it?
```

```
🎭 Persona active: `xrpl-typescript-fullstack` — proceeding with implementation
```

```
🎭 No persona active — none strongly relevant for <task domain>, proceeding without
```

## Relationship to Personas

Personas provide a **lens** (priorities, tradeoffs, posture). Learnings provide **knowledge** (gotchas, patterns, facts). This guideline makes knowledge active regardless of whether a persona is set. Personas are recommended when relevant — the implementation gate above ensures they're considered before execution begins.
