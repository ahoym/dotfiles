# Deep Research: `context: fork` Candidates

## What `context: fork` Does

When a skill has `context: fork` in its frontmatter, it runs in an isolated subagent instead of the main conversation. Key behaviors:

| Aspect | Inline (default) | Forked (`context: fork`) |
|:-------|:-----------------|:-------------------------|
| Conversation history | Full access | **None** — skill content is the only prompt |
| CLAUDE.md | Loaded | Loaded |
| Skill content | Injected as user message | Becomes the subagent's task |
| Tool access | Session's full tools | Determined by `agent` type |
| Subagent spawning | Can use Task tool | **Cannot** — subagents cannot spawn subagents |
| `!`command`` preprocessing | Runs before injection | Runs before fork — subagent sees resolved output |
| User interaction | AskUserQuestion works | Works in foreground; **fails silently** in background |
| Context budget impact | Consumed from main window | Isolated — no main context cost |

### The `agent` Field

| Agent Type | Model | Tools | Best For |
|:-----------|:------|:------|:---------|
| `Explore` | Haiku (fast) | Read-only (no Write/Edit) | Searching, analysis, read-only research |
| `Plan` | Inherits | Read-only (no Write/Edit) | Codebase research for planning |
| `general-purpose` | Inherits | All tools | Multi-step tasks needing writes |
| Custom (from `.claude/agents/`) | Configurable | Configurable | Domain-specific workflows |

If `agent` is omitted, defaults to `general-purpose`.

---

## Critical Constraint: No Nested Subagents

> "Subagents cannot spawn other subagents."
> — [Subagents docs](https://code.claude.com/docs/en/sub-agents)

This is the single most important constraint for evaluating candidates. **Any skill that internally uses the Task tool to launch subagents is incompatible with `context: fork`.**

This eliminates the two skills most commonly cited as fork candidates.

---

## Evaluation of All 22 Skills

### Eliminated: Spawns Subagents Internally

These skills use the Task tool to launch parallel subagents. Forking them would break their core architecture.

| Skill | Why Eliminated |
|:------|:---------------|
| **explore-repo** | Launches 7 parallel Task agents for domain scanning. Core pattern is orchestrate-then-synthesize. |
| **do-security-audit** | Launches parallel Explore subagents per project for checklist items. |
| **parallel-plan:execute** | Entire purpose is launching parallel Task agents from a DAG schedule. |

**This invalidates Assumption A4** from assumptions-and-questions.md, which identified explore-repo and do-security-audit as the primary candidates.

### Eliminated: Requires Conversation History

These skills need the main conversation's context to function.

| Skill | Why Eliminated |
|:------|:---------------|
| **learnings:compound** | Reviews the *current conversation* for patterns. Without history, has nothing to review. |
| **set-persona** | Sets focus for the *current session*. Forking defeats the purpose — the persona would only apply inside the discarded subagent. |

### Eliminated: Requires User Interaction Mid-Task

These skills need back-and-forth with the user during execution.

| Skill | Why Eliminated |
|:------|:---------------|
| **do-refactor-code** | Presents findings, waits for user selection, then applies. The analyze → confirm → apply loop requires the main context. |
| **git:create-pr** | Has pre-PR checklist, may need user to confirm PR details. Also needs write access to push. |
| **git:address-pr-review** | May need user decisions on how to handle specific comments. Also writes code. |

### Eliminated: Performs Write Operations That Need Main Context

These skills modify files, branches, or external state in ways that benefit from main conversation continuity.

| Skill | Why Eliminated |
|:------|:---------------|
| **git:resolve-conflicts** | Resolves merge conflicts — needs write access + conversation context about what the user wants preserved. |
| **git:cascade-rebase** | Rebases stacked branches — destructive git operations that need user oversight. |
| **git:repoint-branch** | Creates new branches and PRs — write operations + user confirmation. |
| **git:prune-merged** | Deletes local branches — destructive, needs user confirmation. |
| **git:monitor-pr-comments** | Already runs as background polling loop with shell scripts — has its own isolation mechanism. |
| **ralph:init** | Creates directory structure and files for a new research project. |
| **quantum-tunnel-claudes** | Syncs files between repos — heavy write operations. |
| **learnings:consolidate** | Multi-sweep curation that reads and modifies learning files. |
| **learnings:curate** | Single-pass curation that modifies learning files. |
| **learnings:distribute** | Copies files between directories. |
| **parallel-plan:make** | Analyzes a plan file (read) then writes a parallel plan file (write). |

### Viable Candidates

Only **3 skills** survive elimination:

#### 1. `ralph:compare` — GOOD Candidate

| Factor | Assessment |
|:-------|:-----------|
| Task-based? | Yes — compare directories and produce recommendation |
| Self-contained? | Yes — reads files, builds comparison, outputs result |
| Needs conversation history? | No — operates on directory paths from $ARGUMENTS |
| User interaction mid-task? | No — produces final recommendation in one pass |
| Spawns subagents? | No |
| Write operations? | No — pure analysis |
| Recommended agent | `Explore` (read-only, haiku for speed) |
| Value of forking | **Medium** — saves main context from verbose file comparisons. But this skill is rare (manual-only, used ad hoc). Already recommended for `disable-model-invocation: true`. |

**Configuration:**
```yaml
context: fork
agent: Explore
```

#### 2. `git:explore-pr` — MARGINAL Candidate

| Factor | Assessment |
|:-------|:-----------|
| Task-based? | Yes — fetch PR data, display summary |
| Self-contained? | Partially — fetch + display is self-contained, but enters Q&A mode |
| Needs conversation history? | Possibly — user may have been discussing the PR before exploring it |
| User interaction mid-task? | Yes — step 5 asks "checkout?", step 6 enters Q&A mode |
| Spawns subagents? | No |
| Write operations? | Optional checkout (git operations) |
| Recommended agent | N/A — not recommended |
| Value of forking | **Low** — the Q&A mode (the skill's primary value) happens AFTER data gathering and needs conversational context. Forking isolates the useful output. |

**Verdict: Don't fork.** The interactive Q&A mode is the skill's main value proposition, and it requires the main conversation context. Forking would make the skill a one-shot data dump instead of an exploration tool.

#### 3. `git:split-pr` — MARGINAL Candidate

| Factor | Assessment |
|:-------|:-----------|
| Task-based? | Yes — analyze PR and propose split |
| Self-contained? | Partially — analysis is self-contained, but asks for user confirmation |
| Needs conversation history? | No — operates on PR number from $ARGUMENTS |
| User interaction mid-task? | Yes — step 5 asks for confirmation before proceeding |
| Spawns subagents? | No |
| Write operations? | Yes — creates branches after confirmation |
| Recommended agent | N/A — not recommended |
| Value of forking | **Low** — the analysis-then-confirm-then-act pattern doesn't work well forked. The subagent would complete analysis, but the user couldn't confirm/modify the plan before branch creation. |

**Verdict: Don't fork.** Same issue as explore-pr — the skill's value comes from the interactive workflow.

---

## Summary

### `context: fork` is Not a Good Fit for This Repo's Skills

The evaluation reveals a mismatch between `context: fork`'s strengths and how skills in this repo are designed:

**`context: fork` is best for:**
- Self-contained, one-shot tasks with no user interaction
- Read-only research that produces a summary
- Skills where context isolation prevents main window pollution
- Skills with heavy output that the main conversation doesn't need verbatim

**This repo's skills are designed for:**
- Interactive workflows with user confirmation steps
- Multi-agent orchestration (explore-repo, do-security-audit, parallel-plan:execute)
- Context-dependent operations (learnings:compound, set-persona)
- Write-heavy operations (git:*, ralph:init, quantum-tunnel-claudes)

**Only `ralph:compare` is a clean fork candidate**, and it's a low-frequency manual-only skill. The cost-benefit of adding `context: fork` for one rarely-used skill is minimal.

### Recommendation

**Deprioritize `context: fork` adoption.** The effort is better spent on:
1. `disable-model-invocation: true` on 9 manual-only skills (already validated, high impact)
2. `allowed-tools` on 5 read-only auto-invocable skills (for documentation/future-proofing)
3. Optionally: add `context: fork` + `agent: Explore` to `ralph:compare` as a low-risk experiment

### When `context: fork` Would Become Valuable

Fork would become relevant if:
- New skills are created that are purely analytical (e.g., a "codebase metrics" skill that counts lines/complexity)
- The nesting limitation is lifted (allowing forked skills to spawn subagents) — this would unlock explore-repo and do-security-audit
- Skills are redesigned to separate analysis from action (e.g., git:split-pr split into split-pr:analyze + split-pr:apply)

---

## Impact on Implementation Plan

- `context: fork` should NOT be a phase in the implementation plan
- The one viable candidate (`ralph:compare`) can be bundled with other `ralph:compare` improvements (like `disable-model-invocation: true`)
- Remove "Performance — context: fork on heavy read-only skills" from the priority list
- Update Assumption A4 as **invalidated**

---

## Sources

- [Skills documentation — Run skills in a subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)
- [Subagents documentation](https://code.claude.com/docs/en/sub-agents) — "Subagents cannot spawn other subagents"
- Skill source files in `~/.claude/commands/` (all 22 skills evaluated)
