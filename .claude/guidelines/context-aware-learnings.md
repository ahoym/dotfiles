# Learnings Search Protocol

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
  - **CWD path**: `.claude/worktrees/consolidate-*` → same domain signal
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

**Step 4: Follow cross-refs (up to two levels).** After loading matched files, check `## See also` sections for additional files. Follow only when relevant; stop when the next file isn't on-topic. Announce cross-ref loads distinctly from keyword loads.

**Plan mode addition**: also announce skipped cross-refs: `📚 Cross-ref from X → Y (skipped: not relevant to current task)`. Too noisy for session-start.

## Gate-specific notes

**Session start** — one filename glob, no content grep. Keep it cheap so narrow opening questions don't tempt skipping.

**Plan mode** — filename glob + content grep. Plans lock in decisions that are expensive to reverse, so the extra search cost is justified. Use enhanced announcement format:
```
📚 Plan mode — terms: ["spring boot", "migration", "flyway"] from task scope
   Matched: spring-boot-gotchas.md, spring-boot.md
   Cross-ref: → postgresql-query-patterns.md (migration patterns)
   Cross-ref: → java-observability-gotchas.md (skipped: not relevant)
   No match: "flyway"
```

## Confidence-level gate (soft)

Before drafting substantial domain-specific content (20+ lines), ask: **"Am I working from loaded knowledge or training memory?"** If you haven't read learnings files in this domain during this session, search first. The user's learnings contain calibrated gotchas and decisions that training knowledge misses.

**Binary self-check**: "Have I loaded files in this domain? Yes/no." Fires when creating/modifying skills, guidelines, learnings, personas, CLAUDE.md; writing architecture docs, design proposals, or reviews; synthesizing domain knowledge into structured artifacts.

Announce: `📚 Confidence check — working from training, not loaded knowledge. Searching learnings for "<domain>"...`

Soft because there's no tool-call trigger — it relies on self-awareness at the moment of drafting. Fires inconsistently, but quality improvement is substantial when it does.

## Friction-triggered (soft)

When a tool call fails, is rejected, or requires a workaround, glob learnings filenames for the error domain (e.g., permission rejection → "claude-code", "permission"; API error → the service name). Load matches before retrying.

Fires on: tool errors, permission rejections, unexpected state. Not on expected no-ops.

Announce: `📚 Friction check — <error summary>. Searching learnings...`

## Keyword-based (proactive)

When a domain keyword appears in conversation (e.g., "Fargate," "Terraform," "Vercel," "BigNumber"), glob `~/.claude/learnings/`, `~/.claude/learnings-private/`, and `docs/learnings/` for matching files by filename. Load on first mention of a domain keyword that maps to a learnings file.

- Learnings filenames are the index — `aws-patterns.md`, `vercel-deployment.md`, `bignumber-financial-arithmetic.md`
- Works with or without an active persona
- Cost: low (reading a file). Upside: shapes thinking before decisions are made.
- **Dedup**: Don't re-load files already read earlier in the session. When context compression makes load history uncertain, err toward re-checking (glob to confirm the file exists and is relevant) rather than blindly re-loading.

## Observability

Always announce when learnings are loaded or searched — the user needs visibility to iterate on this system. No-match announcements are **mandatory** (they surface gaps and confirm the system is firing).

Formats: `📚 Session start — loaded X (reason)` · `📚 "keyword" → loaded X` · `📚 Searched for "X" — no matches` · `📚 Cross-ref from X → loaded Y (reason)` · `📚 Cross-ref from X → Y (skipped: not relevant)` (plan-mode only)

Persona checks: `🎭 No persona active — recommending X. Set it?` · `🎭 Persona active: X — proceeding` · `🎭 No persona — none relevant, proceeding without`

## Relationship to Personas

Personas provide a **lens** (priorities, tradeoffs, posture). Learnings provide **knowledge** (gotchas, patterns, facts). This guideline makes knowledge active regardless of whether a persona is set.

**Subagent persona propagation.** Subagents get this protocol but rarely enter plan/implementation phases, so persona gates (#2–3) don't fire. When launching a subagent for domain work, include a persona filename in the prompt — the orchestrator has better context for selection. Skip for utility tasks.
