# Context-Aware Learnings Pulling

## Behavior

Proactively search `~/.claude/learnings/` for relevant prior knowledge during conversations. Don't wait for the user to ask — detect when learnings would help and load them.

## Hard gate: Session start

**Before your first tool call in a session, search learnings.** This is not optional. One filename glob, no content grep — keep it cheap so narrow opening questions don't tempt you to skip it.

**Step 1: Glob all filenames.** Run `*.md` globs on both `~/.claude/learnings/` (global) and `docs/learnings/` (project-local, if it exists) to get the full inventory. This is the index — filenames are designed to be scannable.

**Step 2: Derive search terms from ambient context + user message.** Ambient context is often a stronger domain signal than the opening question:
- **Branch name**: `consolidate/2026-02-28` → "consolidat", "ralph"
- **CWD path**: `.claude/worktrees/consolidate-*` → same domain signal
- **Git status snippet**: the session-start git status in the system prompt contains branch, recent commits, and changed files — scan for domain keywords
- **CLAUDE.md / project context**: technologies mentioned (e.g., "Spring Boot", "PostgreSQL", "Vault") → search terms
- **User's message**: extract topic terms as before

**Step 3: Match filenames against terms.** Compare the inventory from step 1 against derived terms. Match broadly — `spring-boot.md` matches "Spring Boot", "startup dependencies", "Flyway", etc. because the file covers the whole domain. Don't embed search terms into glob patterns (e.g., `*spring*`) — that misses hyphenated and compound filenames.

Load matches and announce. If no ambient context is available (fresh repo, no git), fall back to message-only matching.

## Keyword-based (proactive)

When a domain keyword appears in conversation (e.g., "Fargate," "Terraform," "Vercel," "BigNumber"), glob `~/.claude/learnings/` and `docs/learnings/` for matching files by filename. Load on first mention of a domain keyword that maps to a learnings file.

- Learnings filenames are the index — `aws-patterns.md`, `vercel-deployment.md`, `bignumber-financial-arithmetic.md`
- Works with or without an active persona
- Cost: low (reading a file). Upside: shapes thinking before decisions are made.

## Hard gate: Plan mode entry

**Before calling `EnterPlanMode`, you MUST search learnings.** This is not optional — it's a prerequisite to entering plan mode. This is the single most valuable checkpoint because plans lock in decisions that are expensive to reverse.

**Search broadly, not just the obvious keywords.** Derive search terms from the *current task scope* (which may have evolved significantly from the opening message), not just the surface-level topic. Include:
- Direct topic terms (e.g., "orderbook", "depth")
- Technologies and libraries involved (e.g., "BigNumber", "xrpl", "Next.js")
- Patterns being applied (e.g., "caching", "singleton", "API design")
- Adjacent domains that might have relevant gotchas

Glob `~/.claude/learnings/` and `docs/learnings/` filenames + grep content for all of the above. Load and announce matches.

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

No-match announcements are **mandatory** during calibration. They surface gaps in the learnings library and confirm the system is actually firing. Every search — keyword or hard gate — must announce its result, hit or miss.

## Hard gate: Implementation start

**Before beginning implementation of an approved plan, check if a persona is active.** If not, glob available personas (`~/.claude/commands/set-persona/` and `.claude/personas/`) and match by filename against the task domain — don't deep-read persona files just to decide which to recommend. Recommend via `AskUserQuestion`. The user can decline — this is a recommendation, not a blocker. The actual persona content is loaded when `/set-persona` runs.

Announce the check:
```
🎭 No persona active — recommending `xrpl-typescript-fullstack` for this task. Set it?
```

If a persona is already active:
```
🎭 Persona active: `xrpl-typescript-fullstack` — proceeding with implementation
```

If no persona is a strong fit for the task:
```
🎭 No persona active — none strongly relevant for <task domain>, proceeding without
```

## Relationship to Personas

Personas provide a **lens** (priorities, tradeoffs, posture). Learnings provide **knowledge** (gotchas, patterns, facts). This guideline makes knowledge active regardless of whether a persona is set. Personas are recommended when relevant — the implementation gate above ensures they're considered before execution begins.
