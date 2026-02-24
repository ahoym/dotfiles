# Deep Research: `commands/` to `skills/` Migration

## TL;DR

**Migration is lower priority than expected.** The official docs confirm `commands/` supports the **same frontmatter** as `skills/`. Every improvement (allowed-tools, disable-model-invocation, context: fork, model overrides) can be done in-place without renaming any directories. Migration to `skills/` is a cosmetic/future-proofing decision, not a prerequisite for any feature.

---

## 1. Feature Parity: commands/ vs skills/

### What the docs say

From [Extend Claude with skills](https://code.claude.com/docs/en/skills):

> **Custom slash commands have been merged into skills.** A file at `.claude/commands/review.md` and a skill at `.claude/skills/review/SKILL.md` both create `/review` and work the same way. Your existing `.claude/commands/` files keep working.

> Files in `.claude/commands/` still work and **support the same frontmatter**. Skills are recommended since they support additional features like supporting files.

### Feature comparison

| Feature | `commands/` | `skills/` | Notes |
|:--------|:------------|:----------|:------|
| `description` frontmatter | ✅ | ✅ | Both |
| `disable-model-invocation` | ✅ | ✅ | Both |
| `allowed-tools` | ✅ | ✅ | Both |
| `context: fork` | ✅ | ✅ | Both |
| `agent:` | ✅ | ✅ | Both |
| `model:` | ✅ | ✅ | Both |
| `user-invocable` | ✅ | ✅ | Both |
| `argument-hint` | ✅ | ✅ | Both |
| `hooks` | ✅ | ✅ | Both |
| `$ARGUMENTS` / `$N` | ✅ | ✅ | Both |
| `` !`command` `` preprocessing | ✅ | ✅ | Both |
| `{baseDir}` | ✅ | ✅ | Both (resolves to skill's own dir) |
| SKILL.md in subdirectory | ✅ | ✅ | This repo already does this |
| Supporting files in same dir | ✅ | ✅ | This repo already does this |
| Monorepo auto-discovery | ✅ | ✅ | Docs only describe `skills/`, but confirmed working in `commands/` via user testing |
| `--add-dir` live detection | ✅ | ✅ | Docs only describe `skills/`, but confirmed working in `commands/` via user testing |
| Plugin packaging | ✅ | ✅ | [Plugin docs](https://code.claude.com/docs/en/plugins) list both: `commands/` ("Skills as Markdown files") and `skills/` ("Agent Skills with SKILL.md files") |

### Key finding

**No features are exclusive to `skills/`.** The original research identified three features as `skills/`-only, but all three have been corrected:
1. **Monorepo auto-discovery** — docs only mention `skills/`, but user testing confirms `commands/` works too
2. **`--add-dir` live detection** — same: docs describe `skills/` only, but `commands/` works in practice
3. **Plugin packaging** — original research was wrong; the [plugin structure docs](https://code.claude.com/docs/en/plugins) explicitly list `commands/` as a valid plugin root directory alongside `skills/`

The only difference is **convention** — Anthropic's docs and examples use `skills/` as the recommended path for new work, and the quickstart guides default to `skills/`. But `commands/` is fully functional and the official docs state they "work the same way."

---

## 2. What Migration Would Change

### Directory rename

```
~/.claude/commands/  →  ~/.claude/skills/
```

All 22 skill directories move. Internal structure stays identical — every skill already uses `SKILL.md` in a subdirectory with supporting files.

### Settings.json impact

**Already partially prepared.** Permissions for both directories exist:

Current `commands/` permissions (need removal after migration):
```json
"Bash(bash ~/.claude/commands/**)"
"Read(~/.claude/commands/**)"
```

Already-present `skills/` permissions (ready to use):
```json
"Edit(~/.claude/skills/**)"
"Read(~/.claude/skills/**)"
"Write(~/.claude/skills/**)"
```

**Gap:** No `Bash(bash ~/.claude/skills/**)` permission exists for `skills/` yet. Would need to be added.

### settings.local.json impact

Contains a hardcoded reference:
```json
"Bash(bash ~/.claude/commands/compound-learnings/file-io.sh:*)"
```
This path would break and needs updating.

### quantum-tunnel-claudes impact (HIGH RISK)

The sync tool's `inventory.sh` **hardcodes directory names**:
```bash
src_files=$(cd "$SOURCE" && find .claude/commands .claude/guidelines .claude/learnings ...)
tgt_files=$(cd "$TARGET" && find .claude/commands .claude/guidelines .claude/learnings ...)
```

This would need updating to search `.claude/skills` instead of (or in addition to) `.claude/commands`. The SKILL.md also references `commands/` in its configuration block.

Additionally, the **sync source** repo (`~/WORKSPACE/mahoy-claude-stuff`) would need to be migrated simultaneously, or inventory.sh needs to handle both directory names during a transition period.

### Internal path references (7 files)

These skills reference `~/.claude/commands/` paths internally:
1. `learnings/curate/SKILL.md`
2. `learnings/consolidate/SKILL.md`
3. `learnings/compound/SKILL.md`
4. `learnings/curate/persona-design.md`
5. `quantum-tunnel-claudes/SKILL.md`
6. `set-persona/SKILL.md`
7. `learnings/distribute/SKILL.md`

All would need path updates from `~/.claude/commands/` → `~/.claude/skills/`.

### External references

- `README.md` — references `commands/` directory and workflow examples
- `learnings/claude-code.md` — permission scoping examples
- `learnings/multi-agent-patterns.md` — permission pattern example
- `skill-references/corpus-cross-reference.md` — globs for `commands/*/SKILL.md`

---

## 3. Migration Strategies

### Strategy A: Stay on `commands/` + Add Frontmatter (Recommended)

**Do nothing to directories. Add frontmatter features in-place.**

- ✅ Zero risk of breakage
- ✅ All features available immediately
- ✅ No sync tool changes needed
- ✅ No permission updates needed
- ✅ No path find-and-replace across files
- ❌ Doesn't align with Anthropic's "recommended" terminology

**When to reconsider:** If Anthropic announces `commands/` deprecation.

### Strategy B: Clean Cutover to `skills/`

**Rename directory + update all references in one pass.**

- ✅ Fully aligned with Anthropic conventions
- ✅ Clean state going forward
- ❌ ~15 files need path updates
- ❌ inventory.sh needs update
- ❌ Sync source repo needs simultaneous migration
- ❌ settings.json/local need updates
- ❌ Risk of missed references causing subtle failures
- ❌ Git history discontinuity (rename vs move)

**Effort estimate:** Low-medium (1-2 focused sessions), but coordination with sync source is the main complexity.

### Strategy C: Incremental Migration (Not Recommended)

**Move skills one-at-a-time with both directories coexisting.**

- ✅ Lower per-change risk
- ❌ Increased complexity: inventory.sh must handle both dirs
- ❌ Permission patterns must cover both dirs (already true)
- ❌ Confusing mental model during transition
- ❌ Shared references (skill-references/) don't move incrementally

**Why not:** The all-or-nothing nature of shared resources (`skill-references/`, `learnings/`) means most of the migration complexity exists regardless of how many skills have moved. Incremental adds complexity without reducing risk.

---

## 4. `context: fork` Behavior (Relevant Finding)

From GitHub issues [#14661](https://github.com/anthropics/claude-code/issues/14661) and [#17283](https://github.com/anthropics/claude-code/issues/17283):

- `context: fork` creates a **clean context**, NOT a fork of the current conversation
- The subagent receives the SKILL.md content as its prompt but **no conversation history**
- This is now documented as intended behavior
- Issue #17283 (Skill tool not honoring `context: fork` and `agent:`) was closed as fixed

**Implication for this repo:** Skills that need conversation context (like `learnings:compound` which analyzes what happened in the session) should NOT use `context: fork`. Good candidates are truly independent tasks like `explore-repo`, `do-security-audit`, and `do-refactor-code`.

---

## 5. Recommendation

**Pursue Strategy A: frontmatter improvements in-place, no directory rename.**

Rationale:
1. Every desired feature (`allowed-tools`, `disable-model-invocation`, `context: fork`, `model:`) works in `commands/`
2. Migration risk (sync tool, permissions, path references) provides no functional benefit
3. No features are exclusive to `skills/` — monorepo discovery, hot-reload, and plugin packaging all work in `commands/` (see feature comparison table above)
4. If deprecation is ever announced, the migration is mechanical — a scripted find-and-replace + directory rename

**Track as a future contingency, not an active work item.** Focus deep research efforts on the frontmatter improvements themselves.

---

## 6. Impact on Other Deep Research Tasks

| Task | Impact of this finding |
|:-----|:-----------------------|
| `allowed-tools` scoping | ✅ Unblocked — works in `commands/` |
| `disable-model-invocation` budget | ✅ Unblocked — works in `commands/` |
| `context: fork` candidates | ✅ Unblocked — works in `commands/` |
| Dynamic context injection | ✅ Unblocked — works in `commands/` |
| `{baseDir}` path portability | ⬇️ Lower priority — confirmed it resolves to skill dir, not `~/.claude/` |
| Model selection strategy | ✅ Unblocked — works in `commands/` |
| Anthropic skills repo deep dive | Unchanged |
| Implementation plan | Significantly simplified — no migration phase needed |

---

## Sources

- [Extend Claude with skills — Claude Code Docs](https://code.claude.com/docs/en/skills)
- [GitHub #14661: context: fork for slash commands](https://github.com/anthropics/claude-code/issues/14661)
- [GitHub #17283: Skill tool should honor context: fork](https://github.com/anthropics/claude-code/issues/17283)
- [Inside Claude Code Skills — Mikhail Shilkov](https://mikhail.io/2025/10/claude-code-skills/)
- Internal: `~/.claude/commands/quantum-tunnel-claudes/SKILL.md`, `inventory.sh`
- Internal: `~/.claude/settings.json`, `~/.claude/settings.local.json`
