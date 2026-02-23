# Assumptions & Questions

Assumptions made during research, and questions that need user input before proceeding.

---

## Assumptions

### A1: `commands/` and `skills/` are feature-equivalent for this repo

info.md states skills are the "recommended path forward," but our skills all live in `commands/`. We assume migration is mostly a directory rename with frontmatter additions — not a rewrite. **This needs verification**: do any of our 22 skills rely on `commands/`-specific behavior that wouldn't carry over?

**Confidence:** Medium. The docs say "custom slash commands still work" and skill takes precedence if both exist, but we haven't tested simultaneous existence or verified all features work identically from `commands/`.

### A2: All 22 skills should remain as individual skills

No research questioned whether any skills should be consolidated, split, or retired. We assumed the current skill count and boundaries are correct. In practice, some skills may be:
- Rarely used (candidates for `disable-model-invocation: true`)
- Better merged (e.g., `ralph:init` and `ralph:compare` could theoretically be one skill)
- Better split (e.g., 6 skills exceed 300 lines)

**Confidence:** Low. No usage data was gathered to inform this.

### A3: `{baseDir}` can fully replace `~/.claude/` in this repo

Paths in skills currently use `~/.claude/...` (documented in CLAUDE.md as the correct convention for this symlinked repo). We assumed `{baseDir}` would resolve to the same directory. However, `{baseDir}` resolves to the skill's containing directory — which would be `~/.claude/commands/<skill>/` or `~/.claude/skills/<skill>/`, NOT `~/.claude/`.

**Confidence:** Low. This assumption is likely **wrong** for references that point to `~/.claude/learnings/` or `~/.claude/skill-references/`. `{baseDir}` would only work for references relative to the skill's own directory. Cross-directory references (the majority of our `@` loads) would still need `~/.claude/`.

### A4: ~~`context: fork` is beneficial for explore-repo and do-security-audit~~ — INVALIDATED

**Resolution:** Both skills are **incompatible** with `context: fork`. The critical constraint is that subagents cannot spawn other subagents. Both explore-repo (7 parallel Task agents) and do-security-audit (parallel Explore subagents) rely on launching subagents internally — forking them would break their core architecture.

Additionally, `!`command`` preprocessing does work in forked context (it's preprocessing, runs before fork), but this is moot since the skills can't fork for other reasons.

Full analysis of all 22 skills: only `ralph:compare` is a viable fork candidate (read-only, self-contained, no subagent spawning). See [context-fork-candidates.md](./context-fork-candidates.md).

**Confidence:** High. Based on documented limitation in official subagents docs.

### A5: `disable-model-invocation: true` saves meaningful context budget

We assumed all 22 skill descriptions consuming context budget is a problem. The docs say descriptions use ~2% of context window (~16k chars fallback). With 22 skills, descriptions likely total 2-4k chars — well within budget. The savings from disabling auto-invocation on some skills may be marginal.

**Confidence:** Medium. The budget impact depends on total description length (not measured) and whether other context pressures exist. Worth quantifying before treating this as high priority.

### A6: `allowed-tools` scoping improves security without hurting UX

We assumed tool restrictions are universally beneficial. In practice:
- Skills that are only run by the user (manual invocation) may not need scoping — the user is already choosing to run them
- Overly restrictive `allowed-tools` could cause skills to fail when they encounter unexpected situations requiring unlisted tools
- Skills that delegate to subagents (parallel-plan:execute, do-security-audit) may need broad tool access by design

**Confidence:** Medium. Security benefit is real for auto-invoked skills, but the UX cost of debugging permission failures during skill execution could outweigh the benefit for manual-only skills.

### A7: Model overrides (`model:`) would improve cost/latency

We assumed some skills would benefit from haiku (faster, cheaper) or opus (more capable). However:
- The user's session model choice already reflects their preference for the current task
- A skill overriding to haiku when the user chose opus may produce worse results
- Model availability and pricing may change, making hardcoded model choices a maintenance burden

**Confidence:** Low. Benefits are speculative without benchmarking skill quality across models.

### A8: Incremental migration is possible (commands + skills coexisting)

We assumed skills can be migrated one-at-a-time with `commands/` and `skills/` directories coexisting. The docs confirm skill takes precedence when both exist with the same name. But:
- Does `quantum-tunnel-claudes` (sync from source) handle `skills/` in addition to `commands/`?
- Do settings.json permission patterns need updating for the new paths?
- Does the system-reminder skill listing update correctly during mixed-directory states?

**Confidence:** Medium. Coexistence is documented, but tooling and permissions may need updates.

---

## Questions Requiring User Input

### Q1: Is `commands/` to `skills/` migration desired at all?

**Research finding:** Migration is NOT needed for any feature. The docs confirm `commands/` supports the same frontmatter as `skills/`. See [commands-to-skills-migration.md](./commands-to-skills-migration.md) for full analysis. **Recommendation: stay on `commands/`, add frontmatter in-place.**

Still worth confirming with user:
- **(a)** Stay on `commands/` and add frontmatter fields in-place (recommended)
- **(b)** Rename to `skills/` anyway for convention alignment
- **(c)** Wait until forced by deprecation

**Impact:** No longer gates the implementation plan — all improvements can proceed regardless.

### Q2: Which skills are manual-only vs. should remain auto-invocable?

`disable-model-invocation: true` removes a skill from Claude's auto-discovery context. Which skills should **never** be auto-invoked?

Likely candidates for `disable-model-invocation: true`:
- `ralph:init`, `ralph:compare` — specialized workflow, always invoked explicitly
- `learnings:consolidate`, `learnings:curate`, `learnings:distribute` — maintenance tasks, explicit invocation
- `parallel-plan:make`, `parallel-plan:execute` — always preceded by explicit user request
- `quantum-tunnel-claudes` — specialized sync task
- `set-persona` — always explicit

Likely should remain auto-invocable:
- `git:create-pr`, `git:address-pr-review`, `git:resolve-conflicts` — triggered by natural user requests
- `learnings:compound` — designed for contextual invocation
- `explore-repo` — triggered when user wants codebase understanding

**Impact:** Determines context budget savings and which skills get frontmatter changes.

### Q3: What's the priority order for improvements?

Possible priorities:
1. **Context budget** — `disable-model-invocation` on manual-only skills
2. **Security** — `allowed-tools` scoping on auto-invocable skills
3. **Performance** — `context: fork` on heavy read-only skills
4. **Portability** — `{baseDir}` where applicable + `skills/` migration
5. **Size reduction** — Extract large skills (>300 lines) into references + scripts

These aren't mutually exclusive, but the implementation plan ordering depends on what matters most.

### Q4: Should `quantum-tunnel-claudes` be updated to sync `skills/` directories?

Currently it syncs from a configured source repo. If we migrate to `skills/`, the sync tool needs to understand the new directory structure. Should this be:
- Part of the migration plan
- A prerequisite
- Out of scope (handled separately)

### Q5: Are there skills you rarely use that could be candidates for removal?

No usage data exists. Are any of the 22 skills effectively dead weight? Removing unused skills would be a simpler context savings than adding `disable-model-invocation` to each.

### Q6: What's the acceptable risk tolerance for migration?

Options:
- **Conservative:** Add frontmatter to existing `commands/` files only (no directory changes). Low risk, partial benefit.
- **Moderate:** Incremental migration with testing per-skill. Medium risk, full benefit over time.
- **Aggressive:** Full cutover in one pass. Highest risk, fastest payoff.

---

## Assumptions Validation Tracker

| ID | Assumption | Confidence | Validated? | Resolution |
|:---|:-----------|:-----------|:-----------|:-----------|
| A1 | commands/skills equivalence | Medium | **Yes** | Confirmed: docs say "support the same frontmatter." Only monorepo auto-discovery, --add-dir live detection, and plugin packaging are skills-exclusive — none apply to personal global skills. See [commands-to-skills-migration.md](./commands-to-skills-migration.md) |
| A2 | All 22 skills should remain | Low | No | Needs usage data (Q5) |
| A3 | {baseDir} replaces ~/.claude/ | Low | Likely wrong | {baseDir} = skill dir, not repo root |
| A4 | context:fork for explore/audit | Medium | **Invalidated** | Both skills spawn subagents internally via Task tool. Subagents cannot spawn subagents, so forking breaks their core architecture. Only `ralph:compare` is a viable fork candidate. See [context-fork-candidates.md](./context-fork-candidates.md) |
| A5 | disable-model-invocation saves budget | Medium | **Yes** | Measured: 2,813 chars total / 16k budget = 17.6%. Savings of 1,464 chars (9 skills) is marginal for budget but meaningful for noise reduction and safety. See [disable-model-invocation.md](./disable-model-invocation.md) |
| A6 | allowed-tools improves security | Medium | **Partially validated** | Enforcement is currently broken (restriction not enforced [#18837], Bash auto-approval broken [#14956], "Experimental" in spec). Value is documentation/intent-signaling only. Recommended for 5 read-only auto-invocable skills; defer broad adoption. See [allowed-tools-scoping.md](./allowed-tools-scoping.md) |
| A7 | Model overrides improve cost | Low | No | Needs benchmarking |
| A8 | Incremental migration works | Medium | **Moot** | Migration not recommended. All features work in `commands/`. See [commands-to-skills-migration.md](./commands-to-skills-migration.md) |
