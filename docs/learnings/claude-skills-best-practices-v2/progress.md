## State
Last updated: 2026-02-25 04:30
Current iteration: 12
Status: IN_PROGRESS

## Completed Tasks
- [x] Research & Document - Learn about Claude skills best practices, document findings, and identify areas for deeper investigation -> info.md (completed 2026-02-24)
- [x] Codebase Summary - Review relevant repository code and create summary -> codebase-summary.md (completed 2026-02-24)
- [x] Assumptions & Questions - Log questions and assumptions from documentation work -> assumptions-and-questions.md (completed 2026-02-24)
- [x] Implementation Plan - Create phased implementation plan -> implementation-plan.md (completed 2026-02-24)
- [x] Deep Research: Dynamic context injection adoption -> dynamic-context-injection.md (completed 2026-02-24) — Evaluated all 22 skills against 5-criteria framework. 10 skills recommended for adoption (7 git + explore-repo + distribute + cascade-rebase). Universal pattern: `!`git branch --show-current`` saves 1 Bash call per invocation at ~5 tokens cost. Updated implementation-plan.md Phase 3C with concrete injection table.
- [x] Deep Research: Subagent configuration patterns -> subagent-configuration-patterns.md (completed 2026-02-24) — Full evaluation of custom agent definitions for `~/.claude/agents/`. Documented complete frontmatter reference (12 fields), 3 skill-agent integration patterns, evaluated 4 candidate agents. Recommended `pr-reviewer` as proof-of-concept (3 skills share PR review needs, `memory: user` for cross-project learning). Identified critical nesting constraint: `explore-repo` uses `general-purpose` so agents can sub-delegate — custom agents can't nest. Also covered agent teams (experimental) vs subagents comparison. Updated implementation-plan.md Phase 4C and assumptions-and-questions.md with new open items (O10, O11).
- [x] Deep Research: Hooks integration with skills -> hooks-integration.md (completed 2026-02-24) — Evaluated all 22 skills against hooks system. Documented full hooks reference (events, matchers, types, decision control). Key finding: most hook value belongs in settings, not skill frontmatter. Only 2 high-confidence skill-scoped hooks identified: `git/resolve-conflicts` (conflict marker detection) and `quantum-tunnel-claudes` (merge integrity). 5 hooks recommended for settings-level (format/lint, secret protection, CLAUDE.md preservation). 6 skills deferred (existing instructions sufficient or prompt/agent hook cost not justified). Updated implementation-plan.md Phase 4B with concrete tiers, info.md investigation tracker, assumptions-and-questions.md with A13 and refined O7.
- [x] Deep Research: Skill testing and validation -> skill-testing-validation.md (completed 2026-02-25) — Full analysis of `skills-ref validate` tool (source code, validation rules, test suite, CLI). Critical finding: the spec validator rejects ALL Claude Code extension fields (`disable-model-invocation`, `argument-hint`, `hooks`, etc.) and requires `name` field (missing from all 22 skills). Recommended 3-layer validation architecture: structural (CI), semantic (CI), behavioral (manual). No CI/CD exists in any official repos. Proposed custom validator script for Phase 0.3, new `name` field addition as Phase 1D, and added O12/O13 to open items.
- [x] Deep Research: Skill context budget optimization -> skill-context-budget.md (completed 2026-02-25) — **Major finding: budget is at only 31% utilization** (~4,908/16,000 chars). No skills are being excluded. ~52-skill headroom. Per-skill breakdown with char counts for all 23 loaded skills. SKILL.md line count audit: 1 violation (`learnings/consolidate` at 640 lines). keybindings-help is a built-in skill (~337 chars, always loaded, bug prevents disabling). Updated implementation-plan.md (Phase 0.1 downgraded, Phase 0.2 marked complete, Phase 2A rationale changed from budget to routing), assumptions-and-questions.md (A3 confirmed, Q1 answered), info.md investigation tracker.
- [x] Deep Research: Plugin packaging strategy -> plugin-packaging-strategy.md (completed 2026-02-25) — Comprehensive analysis of Claude Code plugin system (manifest, marketplace, distribution, naming). Key recommendation: **modular plugins by namespace** (mahoy-git, mahoy-parallel-plan, mahoy-explore, mahoy-learnings) rather than monolithic. Documented full conversion steps, marketplace setup, dependency resolution (bundle skill-references per plugin), permission handling (docs only — plugins can't inject settings), and naming strategy. Analyzed 13 official Anthropic plugins for patterns. Added Phase 6 to implementation plan, 4 new assumptions (A14-A16), 5 new open items (O14-O17), 7 open questions needing user input. Plugin readiness assessed at 3/10 — structural work needed.
- [x] Deep Research: Agent Skills cross-platform compatibility -> cross-platform-compatibility.md (completed 2026-02-25) — **8+ platforms adopt Agent Skills standard** (Claude Code, VS Code/Copilot, Cursor, Codex, Gemini CLI, Roo Code, OpenCode, SkillPort). Frontmatter is maximally portable (description-only, all planned additions degrade gracefully). Body content is low portability (all 22 skills reference CC-specific tools). Per-skill tier assessment: 3 near-portable, 10 moderate, 9 deeply coupled. `.agents/skills/` is the universal discovery path. VS Code warns on extension fields (cosmetic, workaround exists). Added `compatibility` field to Phase 1E, cross-platform layout to Phase 6F, new assumptions A17-A18, open items O18-O19.
- [x] Deep Research: `allowed-tools` adoption strategy -> allowed-tools-adoption.md (completed 2026-02-25) — **13/22 skills recommended for adoption** (5 Tier 1 read-only + 8 Tier 2 narrowly-scoped). 9 Tier 3 orchestrators skipped. Full bug landscape: #14956 (open, main enforcement bug), #18837 (closed dup), #18737 (SDK ignores field), #1271 (piped commands bypass). Trail of Bits is primary real-world adopter (YAML list syntax, 4+ skills). Anthropic's 16 reference skills don't use it. Recommended YAML list syntax + bare Bash (scoped patterns deferred to Phase 3). Per-skill tool lists ready to apply. Added Phase 1F to implementation plan, updated A4 and O5 in assumptions-and-questions.md.

## Pending Tasks
*(none — all research tasks complete)*

## Questions Requiring User Input
1. **`commands/` -> `skills/` migration**: **ANSWER: Defer.** Anthropic confirms commands/ and skills/ are equivalent. No rename needed.
2. **Context budget urgency**: **ANSWER: Yes, measure first.** -> **RESOLVED by research:** Budget is at 31% utilization, no urgency. Live `/context` is nice-to-have confirmation, not blocking.
3. **Cross-platform intent**: **ANSWER: Plan to share.** Plugin packaging and cross-platform research should proceed.
4. **Deep research scope**: **ANSWER: Resolved.** With Q3 answered, all pending tasks are now active.
5. **Task nesting in explore-repo**: **ANSWER: Skip the custom codebase-explorer agent.** The existing explore-repo approach (general-purpose subagents) works fine. Keep Phase 4C.3 in the plan as documentation/future reference only.
6. **Validation script priority**: **ANSWER: Shell script.** Zero-dependency approach preferred.
7. **Add `name` field to all skills?**: **ANSWER: Yes, Phase 1.** Add name field to all skills in the first implementation phase.
8. **Plugin name prefix**: What prefix for all plugins? `mahoy-` recommended for brand consistency. Alternatives: shorter abbreviation, or different brand name entirely.
9. **License choice**: MIT recommended for maximum sharing. Apache-2.0 if patent grant matters. Affects all distributed plugins.
10. **Marketplace repo name**: Where to host? Options: `ahoym/mahoy-skills`, `ahoym/claude-plugins`, `ahoym/mahoy-claude-stuff`.
11. **Ralph as plugin?**: Should ralph/ skills be packaged as a separate distributable plugin or kept personal-only?
12. **Flatten nested namespaces?**: Should `git/create-pr` become just `create-pr/` inside the git plugin? Needs empirical verification (O17) but user preference matters for naming UX.

## Implementation Planning Session (2026-02-24)

User reviewed research via `/ralph:brief`, compared v1 vs v2 (ported unique content, deleted v1), then discussed implementation decisions:

**Decided:**
- `disable-model-invocation` on 9 skills (expanded from 4): ralph/init, ralph/compare, ralph/resume, ralph/brief, ralph/cleanup, quantum-tunnel-claudes, learnings/consolidate, learnings/curate, parallel-plan/execute
- Kept auto-invocable: set-persona, parallel-plan/make, learnings/distribute, learnings/compound
- Dynamic injection extended to 12 skills (added ralph/brief, ralph/resume)
- Phase 0.1 confirmed live (769 tokens, 0.4%)
- Phase 0.3 (validation script) deferred
- Phase 1E (compatibility field) deferred
- Phase 2A (descriptions) included in first round
- O8 (consolidate 640 lines) deferred as separate effort
- Phases 4-6 deferred
- Execution via `/parallel-plan:make` + `/parallel-plan:execute`, grouped by skill file

**Ready for execution:** Phases 1A/1B/1C/1D/1F + 3C + 2A. Plan file at `~/.claude/plans/quirky-shimmying-island.md`.

## Notes for Next Iteration
- **Implementation plan updated** with all session decisions. See "Session Decisions" section at top of implementation-plan.md.
- **First execution round is scoped**: 26 skill files + 1 settings file. Group by skill file for parallel execution.
- **Open questions 8-12** (plugin prefix, license, marketplace, ralph as plugin, namespace flattening) only block Phase 6. Not needed for first round.

WOOT_COMPLETE_WOOT
