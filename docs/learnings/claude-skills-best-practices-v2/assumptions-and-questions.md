# Assumptions & Questions: Claude Skills Best Practices

## Assumptions

### Critical (Would block or derail implementation if wrong)

#### A1: `commands/` and `skills/` Are Fully Feature-Equivalent
**Assumption**: No migration from `commands/` to `skills/` is required. Both directories support identical frontmatter, auto-discovery, hot-reload, and plugin packaging.
**Rationale**: Official docs state "both work the same way" and "support the same frontmatter." User empirically confirmed auto-discovery and hot-reload work in `commands/`. Plugin docs explicitly list both directories. Our existing learnings (skill-design.md) document this equivalence.
**Confirmed**: Yes - via docs + user testing. Migration is purely a naming convention preference, not a functional requirement.

#### A2: `disable-model-invocation` Removes Skill from Context Entirely
**Assumption**: Setting `disable-model-invocation: true` not only prevents auto-invocation but completely removes the skill's description from Claude's context budget. This is the primary mechanism for reducing context pressure.
**Rationale**: Official docs state this explicitly. Our learnings confirm it. The trade-off (losing auto-discovery) is acceptable for manual-only skills.
**Confirmed**: Yes - documented behavior. The key trade-off is that Claude won't know the skill exists until manually invoked.

#### A3: Context Budget Is ~16K Chars Shared Across All Skills
**Assumption**: All skill descriptions (name + description frontmatter) share a budget of 2% of the context window (~16K chars fallback). Skills exceeding this budget are silently excluded.
**Rationale**: Official docs. Overrideable via `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var. With 22 skills, this could be tight - but unverified empirically.
**Trade-offs**: We haven't measured actual consumption. Some skills may already be silently excluded. The `/context` command can check this but wasn't run (no-mutation constraint in research loop).
**Confidence**: High on the mechanism, **low on whether our 22 skills currently fit within budget**.

#### A4: `allowed-tools` Enforcement Is Broken — Defer Adoption
**Assumption**: The `allowed-tools` feature should not be relied on for runtime enforcement. It can be added for documentation/intent-signaling but should not be a blocking item in the implementation plan.
**Rationale**: Two open GitHub issues ([#18837](https://github.com/anthropics/claude-code/issues/18837), [#14956](https://github.com/anthropics/claude-code/issues/14956)). Anthropic's own 16 reference skills don't use it. Marked "Experimental" in Agent Skills spec.
**Confirmed**: Yes - documented bugs. Revisit when issues are closed.

### Moderate (Affect approach but not viability)

#### A5: `context: fork` Candidates Are Correctly Identified
**Assumption**: `explore-repo` and `do-security-audit` are NOT viable `context: fork` candidates because they internally spawn Task subagents, which is incompatible with fork. No current skills pass the full fork viability checklist.
**Rationale**: Both skills use Task tool for parallel subagent orchestration. Fork disallows nesting. The viability checklist (5 criteria) eliminates all current orchestration-heavy skills.
**Trade-offs**: This means we can't use `context: fork` for ANY existing skill without refactoring it to remove Task usage. New, simpler skills could be designed for fork from scratch.
**Confidence**: High - verified by reading SKILL.md bodies. The fork constraint on Task nesting is explicitly documented.

#### A6: Manual-Only Skill Candidates Are Correct
**Assumption**: These 4 skills should get `disable-model-invocation: true` because they are only meaningful when explicitly invoked by the user:
- `ralph/init` - creates a research project directory
- `ralph/compare` - compares duplicate research directories
- `quantum-tunnel-claudes` - syncs skills from external source
- `set-persona` - sets domain focus for current session
**Rationale**: None of these make sense for Claude to auto-invoke. They're all setup/configuration actions triggered by deliberate user intent.
**Exception**: Could argue `set-persona` might be auto-invoked if Claude detects a domain mismatch, but this would be unusual and the context budget savings outweigh the edge case.

#### A7: `argument-hint` Candidates Are Correct
**Assumption**: These skills would benefit from autocomplete hints:
- `do-refactor-code` → `[filepath]`
- `explore-pr` → `[pr-number]`
- `address-pr-review` → `[pr-number]`
- `set-persona` → `[persona-name]`
- `ralph/init` → `[topic]`
- `ralph/compare` → `[dir1] [dir2]`
**Rationale**: All take meaningful arguments where a hint improves discoverability. The hint text should match the skill's `$ARGUMENTS` usage.
**Confidence**: High - straightforward metadata addition with no behavioral impact.

#### A8: Stale Settings Can Be Fixed Without Breaking Workflows
**Assumption**: Updating `settings.local.json` to fix the old path `compound-learnings/` → `learnings/compound/` and the typo `Read(~.claude/*)` → `Read(~/.claude/*)` won't break existing permission grants.
**Rationale**: These are clearly bugs (stale rename, missing `/`). The current entries match nothing, so they're already non-functional.
**Confidence**: High - fixing dead entries can't break things that aren't working.

### Working (Reasonable defaults, validate opportunistically)

#### A9: Shared Reference Pattern Is the Right Architecture
**Assumption**: The `skill-references/` directory for cross-skill shared references (platform-detection.md, agent-prompting.md, etc.) is the right pattern and should be maintained/expanded rather than inlining content.
**Rationale**: 5 shared files currently serve 10+ skills. Inlining would cause duplication and drift. The pattern also works cross-platform via the Agent Skills standard.
**Confidence**: High - proven in production across the repo.

#### A10: Namespace Groups via Directories Is the Right Organizational Pattern
**Assumption**: The current namespace structure (`git/`, `learnings/`, `parallel-plan/`, `ralph/`) is sound and should be maintained. No reorganization needed.
**Rationale**: Groups are logical, consistently sized (2-9 skills), and the standalone skills are genuinely standalone.
**Confidence**: High - no evidence of organizational problems.

#### A11: No Skills Need Splitting
**Assumption**: None of the 22 current skills need to be broken into multiple skills. All are appropriately scoped.
**Rationale**: Codebase summary shows a healthy complexity spectrum from simple to complex, and even the most complex skills (learnings/compound at 6 refs) have clear single responsibilities.
**Confidence**: Medium - haven't done line-count analysis of all SKILL.md files against the <500 line recommendation.

#### A13: Most Hook Value Belongs in Settings, Not Skill Frontmatter
**Assumption**: General-purpose validation (format/lint after edits, secret file protection, CLAUDE.md section preservation) should live in project/user `settings.json`, not in individual skill `hooks:` frontmatter. Only skill-specific invariants (conflict markers during merge, section count during sync) belong in skill frontmatter.
**Rationale**: Putting format/lint hooks in every skill that edits files means maintaining 10+ copies. Settings-level hooks apply once to ALL file edits regardless of which skill triggered them.
**Confidence**: High — follows DRY principle and matches the hooks documentation's guidance on scope.

#### A12: Cross-Platform Compatibility Is Not a Current Priority
**Assumption**: Optimizing for Agent Skills cross-platform portability (Cursor, Gemini CLI, VS Code) is a nice-to-have, not a driving requirement. Implementation should favor Claude Code-specific features (fork, hooks, disable-model-invocation) over cross-platform purity.
**Rationale**: This is a personal dotfiles repo, not a distributed plugin. The skills are tuned for Claude Code workflows.
**Confidence**: Medium - depends on user's distribution intentions. If they want to share skills publicly, cross-platform matters more.

---

## Questions & Answers

### Q1: What Is the Actual Context Budget Consumption?
**Question**: Are any of the 22 skills currently being silently excluded from context due to budget overflow?
**Answer**: Unknown. Requires running `/context` in a live session to measure. Research loop constraints prevent this. Flagged as a validation item — should be checked before and after implementing `disable-model-invocation` changes.

### Q2: Should We Migrate from `commands/` to `skills/`?
**Question**: Given full feature equivalence, is there value in migrating the directory name?
**Answer**: Low priority. The only benefit is alignment with the newer naming convention. Costs include updating all documentation, settings paths, and user muscle memory. Recommend deferring unless the user has a preference.

### Q3: Are There Skills That Should Be `user-invocable: false`?
**Question**: Are there skills that should be invocable only by Claude, not by users?
**Answer**: Possibly `learnings/curate` — it's primarily invoked by `learnings/consolidate` as a delegate. But it also works standalone for single-pass curation. No strong candidates identified. The `user-invocable: false` pattern is best suited for "helper" skills that only make sense as sub-steps of another skill.

### Q4: Should New Skills Be Designed for `context: fork`?
**Question**: Since no existing skills pass the fork viability checklist, should we design new skills that do?
**Answer**: Yes, but only when the use case naturally fits. Good candidates would be simple analysis/reporting skills (e.g., "analyze this file for X and return a report"). Don't retrofit existing skills — the orchestration patterns they use are more powerful than fork allows.

### Q5: What Model Should Skills Use?
**Question**: Which skills would benefit from per-skill `model:` overrides?
**Answer**: Potential candidates:
- `prune-merged` → `haiku` (simple git cleanup, doesn't need reasoning)
- `distribute` → `haiku` (file copying, straightforward)
- `explore-repo` → `opus` (deep analysis benefits from stronger reasoning)
- `learnings/consolidate` → `opus` (requires nuanced judgment about learning quality)
But model overrides add maintenance complexity and the default model is usually fine. Low priority.

---

## Open Items for Implementation

### O1: Measure Context Budget Consumption
**Item**: Run `/context` to measure actual skill description consumption against the 16K char budget.
**Approach**: In a live session, check current consumption. Calculate expected savings from `disable-model-invocation` candidates.
**Priority**: High - validates A3 and informs the impact of A6.

### O2: Add `disable-model-invocation: true` to Manual-Only Skills
**Item**: Add frontmatter to ralph/init, ralph/compare, quantum-tunnel-claudes, set-persona.
**Approach**: Single frontmatter addition per skill. No body changes needed.
**Priority**: High - easy win, saves context budget, no behavioral downside.

### O3: Add `argument-hint` to Argument-Taking Skills
**Item**: Add autocomplete hints to skills that accept arguments.
**Approach**: Single frontmatter addition per skill. See A7 for candidates.
**Priority**: Medium - improves UX but doesn't affect functionality.

### O4: Fix Stale Settings
**Item**: Update `settings.local.json` to fix dead path references.
**Approach**: Direct edit of two entries.
**Priority**: Medium - fixes existing bugs but they're currently harmless (dead entries).

### O5: Add `allowed-tools` for Intent Documentation
**Item**: Add `allowed-tools` to read-only or narrowly scoped skills for documentation purposes.
**Approach**: Identify skills with clear tool boundaries. Add `allowed-tools` as documentation, not enforcement.
**Priority**: Low - no runtime impact while enforcement is broken. Revisit when fixed.

### O6: Evaluate `context: fork` for Future Skills
**Item**: When designing new skills, evaluate against the fork viability checklist.
**Approach**: Apply the 5-criteria checklist before choosing inline vs. fork.
**Priority**: Low - design-time consideration, not a retrofit task.

### O7: Add Skill-Scoped Hooks (Tier 1)
**Item**: Add `hooks:` frontmatter to `git/resolve-conflicts` (conflict marker detection) and `quantum-tunnel-claudes` (merge integrity check).
**Approach**: PostToolUse(`Edit`) command hooks. Simple `jq` + `grep` one-liners. See [hooks-integration.md](./hooks-integration.md) for full evaluation of all 22 skills.
**Priority**: Medium - two high-confidence candidates with deterministic checks, zero token cost, <1s latency. Remaining candidates either belong in settings (general format/lint) or are deferred (prompt/agent hooks not justified by risk).

### O8: Validate Line Counts Against <500 Line Recommendation
**Item**: Check that all SKILL.md files are under 500 lines. Identify any that need reference extraction.
**Approach**: Line count audit of all 22 SKILL.md files.
**Priority**: Medium - validates A11 and may reveal optimization opportunities.

### O9: Add Dynamic Context Injection to Git Skills
**Item**: Add `!`command`` preprocessing to inject runtime git state into skill prompts.
**Approach**: Add `## Context` section with `!`git branch --show-current`` to 7 git skills + `explore-repo` + `learnings/distribute`. See [dynamic-context-injection.md](./dynamic-context-injection.md) for full evaluation.
**Priority**: Medium - saves Claude one Bash call per invocation, negligible token cost (~5-100 tokens), zero behavioral risk. Purely additive improvement.

### O10: Create `pr-reviewer` Custom Agent
**Item**: Create `~/.claude/agents/pr-reviewer.md` with `memory: user` to provide persistent learning across PR reviews.
**Approach**: Define agent with read-only tools + Bash (for gh commands), `memory: user` scope, inherit model. Update `git/address-pr-review` to reference via `subagent_type: "pr-reviewer"` in Task calls. See [subagent-configuration-patterns.md](./subagent-configuration-patterns.md) for full evaluation.
**Priority**: Medium - proof-of-concept for custom agents. Low risk (read-only), high overlap (3 skills share PR review needs).

### O11: Verify Task Nesting in explore-repo
**Item**: Empirically test whether `explore-repo`'s `general-purpose` subagents actually spawn sub-agents in practice.
**Approach**: Run `explore-repo` on a large repo and observe whether sub-delegation occurs. If it does, custom `codebase-explorer` agent cannot replace `general-purpose` without breaking the skill.
**Priority**: Medium - blocks O10's extension to explore-repo and do-security-audit. Must be resolved before Phase 4C.3.

### O12: Build Custom Skill Validation Script
**Item**: Create a validation script that checks the Claude Code superset of Agent Skills spec fields. See [skill-testing-validation.md](./skill-testing-validation.md) for full architecture.
**Approach**: Python script (~200 lines) using `strictyaml` or `pyyaml`. Implements Layer 1 (structural) + Layer 2 (semantic) validation. Checks: SKILL.md exists, frontmatter parseable, `description` present, Claude Code extension fields have valid types/values, line count < 500, file references resolve, context budget estimation. Run as pre-commit hook and/or GitHub Actions workflow.
**Priority**: Medium - should be implemented as part of Phase 0 (before mass frontmatter changes in Phases 1-4) to provide a safety net.

### O13: Add `name` Field to All Skills
**Item**: Add the spec-required `name:` field to all 22 SKILL.md frontmatter blocks.
**Approach**: Set `name` to match immediate parent directory name (e.g., `create-pr` for `git/create-pr/SKILL.md`). Harmless in Claude Code (accepts explicit name), enables future `skills-ref` compatibility, makes skills self-documenting.
**Priority**: Low-Medium - spec compliance improvement, zero risk, minimal effort (1 line per skill). Could be bundled with Phase 1 frontmatter additions.
