# Deep Research: `disable-model-invocation` Budget Optimization

## Context Budget Mechanics

### How skill descriptions consume context

Skill descriptions are injected into the Skill tool's `<available_skills>` section in the system prompt. This is a **character budget** — not tokens.

| Parameter | Value |
|:---|:---|
| Budget formula | 2% of context window (chars) |
| Fallback / floor | 16,000 characters |
| Override env var | `SLASH_COMMAND_TOOL_CHAR_BUDGET=<chars>` |
| Historical (pre-v2.1.32) | Fixed 15,000 chars |

For Claude Opus with a ~200k token context window (~800k chars), the budget is ~16,000 chars (the floor applies).

**Only the `description` field counts** toward the budget. The full SKILL.md body is NOT loaded until invocation. When skills exceed the budget, some are truncated from the listing — `/context` shows a warning like "Showing 60 of 169 skills."

Sources: [Official docs](https://code.claude.com/docs/en/skills), [Issue #23406](https://github.com/anthropics/claude-code/issues/23406), [Issue #14549](https://github.com/anthropics/claude-code/issues/14549)

---

## This Repo's Budget Usage

### All 22 descriptions measured

| Skill | Chars |
|:---|---:|
| learnings:consolidate | 259 |
| parallel-plan:execute | 251 |
| parallel-plan:make | 247 |
| learnings:curate | 185 |
| learnings:distribute | 136 |
| quantum-tunnel-claudes | 120 |
| git:split-pr | 110 |
| explore-repo | 107 |
| learnings:compound | 107 |
| git:repoint-branch | 102 |
| ralph:compare | 100 |
| git:create-pr | 95 |
| git:monitor-pr-comments | 94 |
| git:cascade-rebase | 87 |
| ralph:init | 84 |
| set-persona | 82 |
| git:explore-pr | 80 |
| git:address-pr-review | 78 |
| git:prune-merged | 75 |
| do-security-audit | 74 |
| do-refactor-code | 71 |
| git:resolve-conflicts | 59 |
| **Total** | **2,813** |

### Budget headroom

| Metric | Value |
|:---|:---|
| Total description chars | 2,813 |
| Budget available | ~16,000 |
| Usage | **~17.6%** |
| Remaining headroom | ~13,187 chars |

**We are nowhere near the budget limit.** The primary benefit of `disable-model-invocation` is NOT preventing truncation — it's reducing noise in Claude's skill selection decisions and preventing false-positive auto-invocations.

---

## What `disable-model-invocation: true` Actually Does

| Aspect | Behavior |
|:---|:---|
| Description in context | **Completely removed** from `<available_skills>` |
| Claude awareness | **Zero** — Claude doesn't know the skill exists |
| User invocation via `/name` | Still works (at message start) |
| Autocomplete menu | Skill still appears |
| Context budget impact | Description chars fully reclaimed |

This is a **hard removal**, not a soft hide. Claude cannot reference or invoke the skill even if the user asks for it by name in natural language — only the explicit `/skill-name` syntax works.

Source: [Official docs](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill), [DevelopersIO testing](https://dev.classmethod.jp/en/articles/disable-model-invocation-claude-code/)

---

## Known Bugs (as of Feb 2026)

These bugs affect the UX of disabled skills and should factor into the decision:

### Bug 1: Mid-message invocation fails ([#19729](https://github.com/anthropics/claude-code/issues/19729))

When `disable-model-invocation: true` is set, the skill content only loads if `/skill-name` appears **at the start** of the message. Typing "Can you run /skill-name for me?" does NOT load the skill. This is an open bug.

**Impact:** Users must learn to put the slash command first. This is a breaking change for users accustomed to mid-sentence invocation.

### Bug 2: Autocomplete shows but invocation errors ([#24042](https://github.com/anthropics/claude-code/issues/24042))

Disabled skills appear in the `/` autocomplete menu but produce an error when selected: "Skill X cannot be used with Skill tool due to disable-model-invocation." Confusing UX.

**Impact:** Low — the skill still works when typed manually at message start. But the error message is misleading.

### Bug 3: Session resume doesn't re-evaluate ([#20816](https://github.com/anthropics/claude-code/issues/20816))

Adding `disable-model-invocation: true` mid-session and resuming with `--resume` doesn't apply the flag. It's only evaluated on fresh session start.

**Impact:** Low — only matters during the transition. Once set, all new sessions respect it.

---

## Recommended Classification

### Criteria for disabling

A skill should get `disable-model-invocation: true` if **all** are true:
1. Users always invoke it explicitly via `/name` (not natural language)
2. Claude auto-invoking it would be unhelpful or wrong
3. Its description doesn't contain keywords that overlap with natural user requests

### DISABLE auto-invocation (9 skills, ~1,464 chars saved)

| Skill | Chars | Rationale |
|:---|---:|:---|
| learnings:consolidate | 259 | Always explicit `/learnings:consolidate`. Auto-invocation would be disruptive — it's a long-running multi-sweep process. |
| parallel-plan:execute | 251 | Always explicit. Auto-executing a parallel plan without user intent would be dangerous. |
| parallel-plan:make | 247 | Always explicit. User says "parallelize this plan" but the system prompt already maps this to the skill. |
| learnings:curate | 185 | Always explicit. Maintenance task, never contextually triggered. |
| learnings:distribute | 136 | Always explicit. One-off setup task. |
| quantum-tunnel-claudes | 120 | Always explicit. Sync operation, never contextually relevant. |
| ralph:compare | 100 | Always explicit. Only used within ralph research loops. |
| ralph:init | 84 | Always explicit. Specialized research loop initialization. |
| set-persona | 82 | Always explicit. Session configuration, not task execution. |

**Note on parallel-plan:make and parallel-plan:execute:** These have the longest descriptions (247, 251 chars) and include trigger phrases like "Use when the user says 'parallelize this plan'". But the system prompt's skill listing already handles this routing — the description trigger phrases are redundant with the system-reminder. Disabling auto-invocation and relying on `/parallel-plan:make` is safe.

### KEEP auto-invocable (13 skills, ~1,349 chars)

| Skill | Chars | Rationale |
|:---|---:|:---|
| git:split-pr | 110 | "This PR is too big" → natural trigger |
| explore-repo | 107 | "What does this repo do?" → natural trigger |
| learnings:compound | 107 | Designed for contextual auto-invocation after tasks |
| git:repoint-branch | 102 | "Extract these changes into a separate PR" → natural trigger |
| git:create-pr | 95 | "Create a PR" → natural trigger |
| git:monitor-pr-comments | 94 | "Watch this PR" → natural trigger |
| git:cascade-rebase | 87 | "Rebase my stacked branches" → natural trigger |
| git:explore-pr | 80 | "Look at PR #123" → natural trigger |
| git:address-pr-review | 78 | "Address the review comments" → natural trigger |
| git:prune-merged | 75 | "Clean up merged branches" → natural trigger |
| do-security-audit | 74 | "Run a security audit" → natural trigger |
| do-refactor-code | 71 | "Refactor this code" → natural trigger |
| git:resolve-conflicts | 59 | "Resolve conflicts" → natural trigger |

### Edge cases worth discussing

**`learnings:compound`** — This is the strongest auto-invocation candidate. Ralph specs and other skills explicitly say "Run /learnings:compound". If disabled, these cross-skill references would silently fail. **Must remain auto-invocable.**

**`git:prune-merged`** — Could go either way. "Clean up branches" is natural language but also a pretty specific request. Keeping auto for now since it's only 75 chars.

---

## Budget Impact Summary

| Scenario | Description chars | % of budget |
|:---|---:|---:|
| Current (all 22 auto) | 2,813 | 17.6% |
| After disabling 9 | 1,349 | 8.4% |
| **Savings** | **1,464** | **9.2%** |

### Is this worth doing?

**Yes, but not for budget reasons.** The real benefits are:

1. **Noise reduction** — 9 fewer skills in Claude's decision space means fewer false-positive invocations. When Claude sees "consolidate" in user text, it won't incorrectly trigger `learnings:consolidate`.

2. **Safety** — Skills like `parallel-plan:execute` and `learnings:consolidate` are heavyweight operations. Preventing accidental auto-invocation avoids surprise multi-agent spawning.

3. **Signal quality** — The 13 remaining auto-invocable skills are all genuinely contextual triggers. The signal-to-noise ratio improves.

4. **Future-proofing** — As skills are added, the budget becomes tighter. Starting the discipline now prevents future truncation issues.

**Not for:**
- Raw context savings (1,464 chars is trivial)
- Response speed (no measurable impact)
- Budget truncation prevention (we're at 17.6%, nowhere near the limit)

---

## Implementation

Adding `disable-model-invocation: true` to the 9 identified skills requires a one-line frontmatter addition to each SKILL.md. No other changes needed.

Example diff for `ralph:init`:
```yaml
---
name: ralph:init
description: Initialize an iterative research project with spec and progress tracking.
+disable-model-invocation: true
---
```

### Caveats

- **Bug #19729**: Disabled skills must be invoked at message start. Users already do this (e.g., `/ralph:init`), so low impact.
- **Bug #24042**: Autocomplete will show disabled skills but error on selection. Low impact — users type the full command anyway.
- Test each skill after adding the flag to confirm it still invokes correctly via `/name`.

---

## Sources

- [Extend Claude with skills — Official Docs](https://code.claude.com/docs/en/skills)
- [Issue #23406 — Budget scales with context](https://github.com/anthropics/claude-code/issues/23406)
- [Issue #14549 — Many skills exceed budget](https://github.com/anthropics/claude-code/issues/14549)
- [Issue #19729 — Mid-message invocation bug](https://github.com/anthropics/claude-code/issues/19729)
- [Issue #24042 — Autocomplete shows disabled skills](https://github.com/anthropics/claude-code/issues/24042)
- [Issue #20816 — Session resume bug](https://github.com/anthropics/claude-code/issues/20816)
- [DevelopersIO testing article](https://dev.classmethod.jp/en/articles/disable-model-invocation-claude-code/)
- [Claude Skills Deep Dive](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/)
