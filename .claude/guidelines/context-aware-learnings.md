# Context-Aware Learnings Pulling

Status: **Experimental** — testing across sessions. Iterate based on user feedback.

## Behavior

Proactively search `~/.claude/learnings/` for relevant prior knowledge during conversations. Don't wait for the user to ask — detect when learnings would help and load them.

## Two-Layer Trigger

### Layer 1: Keyword-based (proactive)

When a domain keyword appears in conversation (e.g., "Fargate," "Terraform," "Vercel," "BigNumber"), glob `~/.claude/learnings/` for matching files by filename. Load on first mention of a domain keyword that maps to a learnings file.

- Learnings filenames are the index — `aws-patterns.md`, `vercel-deployment.md`, `bignumber-financial-arithmetic.md`
- Works with or without an active persona
- Cost: low (reading a file). Upside: shapes thinking before decisions are made.

### Layer 2: Just-in-time (defensive)

Before committing to a recommendation or writing implementation code, do a broader search — scan filenames + grep content for relevant terms. Catches domains the keyword layer missed.

### Hard gate: Plan mode entry

**Before calling `EnterPlanMode`, you MUST search learnings.** This is not optional — it's a prerequisite to entering plan mode. Glob `~/.claude/learnings/` filenames + grep content for terms related to the task. Load and announce matches. This is the single most valuable checkpoint because plans lock in decisions that are expensive to reverse.

## Observability

Always announce when learnings are loaded or searched. The user needs visibility to iterate on this system.

**Keyword trigger:**
```
📚 "Fargate" → loaded `aws-patterns.md`
```

**Just-in-time trigger:**
```
📚 Checked learnings before planning — loaded `vercel-deployment.md`, `aws-patterns.md`
```

**No matches (ALWAYS announce):**
```
📚 Searched learnings for "Kubernetes" — no matches
```

No-match announcements are **mandatory** during calibration. They surface gaps in the learnings library and confirm the system is actually firing. Every search — keyword, just-in-time, or plan-mode gate — must announce its result, hit or miss.

## Relationship to Personas

Personas provide a **lens** (priorities, tradeoffs, posture). Learnings provide **knowledge** (gotchas, patterns, facts). This guideline makes knowledge active regardless of whether a persona is set. Personas remain optional.
