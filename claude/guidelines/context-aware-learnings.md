# Learnings Search Protocol

## Directories

Read `~/.claude/learnings-providers.json` to discover search directories. For each entry in `providers[]`, use its `localPath` as a search directory (when the directory exists). Additionally, search the `projectLocal.path` (resolved relative to project root) when it exists.

Each has a `CLAUDE.md` index — read it at every gate for index-based matching alongside the pipeline. Learnings are organized into cluster subdirectories (e.g., `xrpl/`, `frontend/`), which may contain sub-clusters (e.g., `claude-code/multi-agent/`). Each cluster and sub-cluster has its own `CLAUDE.md` routing table. Read cluster `CLAUDE.md` files when the cluster is relevant to derived terms; follow sub-cluster pointers when the sub-cluster's domain matches.

## Gates

All gates are mandatory when their trigger fires. No exceptions.

| Gate | Trigger | Search scope | Persona check |
|------|---------|-------------|---------------|
| **Session start** | Before FIRST tool call | Glob filenames → ambient context + user message | No |
| **Plan mode entry** | Before `EnterPlanMode` | Glob filenames + grep content → broad task terms | Yes — set one if none active |
| **Implementation start** | Before executing approved plan | Glob persona dirs → tech stack | Yes — activate match |
| **Review entry** | Invoking a review/audit skill that doesn't self-load learnings (e.g., native `/simplify`, `/security-review`) BEFORE launching review subagents. Skip if the skill's instructions already include a "load learnings" step (`git:code-review-request`, `git:team-review-request`, `git:address-request-comments` all handle this internally) | Glob filenames + grep content → quality, testing, security, perf, language-specific gotchas relevant to the diff | No |
| **Keyword** *(hook-owned)* | Domain keyword or quoted term in user message | Handled by `learnings-suggest` `UserPromptSubmit` hook — see below | No |
| **Domain shift** *(hook-owned)* | User message introduces new domain | Same hook | No |
| **Pre-edit check** *(hook-owned, iteration 2)* | First Edit/Write in unloaded tech domain | Today: agent-owned. Iteration 2: `PreToolUse` hook on Edit/Write | No |
| **Skill-task start** | Before executing a complex/long-running skill (sweeps, multi-agent, refactors) | Glob filenames → skill's domain terms (e.g., `sweep`, `director`, `compound`, `worktree`, `multi-agent`) | No |

**Skill-task gate rationale:** Other gates fire on the user's domain, not the skill's operational domain. Multi-agent / sweep / refactor skills have their own learnings clusters that go unloaded when the user message doesn't name them. Load operational learnings before the skill's first substantive action.

**Dedup**: don't re-load files already read this session. When context compression makes history uncertain, err toward re-checking.

## Hook-suggested learnings

The `learnings-suggest` hook fires on `UserPromptSubmit`, matches the prompt
against the federated keyword index, and may inject a `<learnings-suggestions>`
block. Treat it as advisory, not directive.

**Format injected:**

```
<learnings-suggestions>
  [strong] ~/.claude/learnings/python-specific.md:142-187 — pydantic, model_dump | ## Section header
  [strong] ~/.claude/learnings/java/spring-boot.md — jpa, flyway | <file-level description>
  [weak]   ~/.claude/learnings/refactoring-patterns.md — refactoring | <description>
</learnings-suggestions>
```

**Path forms:**
- `path:start-end` → section-level hint. Read with `offset=start, limit=(end-start+1)`. Section content is precise; `[weak]` section hints are usually worth loading.
- `path` (no range) → file-level hint. Use either when the file is short or when the section index can't address the content precisely (dense atomic files, drifted sections). Default to a normal Read; consider `offset+limit` only after sniffing if the file is large.

**Tier interpretation:**
- `[strong]` (≥3 keyword hits) → load unless dedup says it's already in this session
- `[weak]` (2 hits) → load only if the description / header suggests genuine relevance
- Clearly irrelevant → ignore silently; no acknowledgement needed
- Quoted terms in the prompt (`"noqa"`) force inclusion even below the strong threshold

**Staleness:** if a hint shows a path without a range that you'd expect to be sectioned, the section index is older than the file's last edit — the hook downgraded the hit to file-level rather than risk a stale line range. The `/learnings:curate` pass rebuilds the index.

The hook handles the **keyword** and **domain-shift** gates automatically. The
remaining agent-owned gates (session-start, plan-mode entry, implementation
start, review entry) still require the full pipeline below.

## Search Pipeline

Every gate search follows these steps:

**1. Glob filenames.** `**/*.md` across all directories (recursive — catches cluster subdirectories). Don't embed search terms in glob patterns (`*spring*` misses `spring-boot-gotchas.md`). Cluster `CLAUDE.md` files appear in glob results — treat them as indexes (read for routing), not as sniff targets.

**2. Derive terms.** Session start: ambient context (branch, CWD, git status, CLAUDE.md) + user message. Plan mode: broad task scope — topics, technologies, adjacent domains. Keyword: domain terms from user message. Soft gates: new domain keywords from message or target file.

**3. Rank and load.** Read cluster `CLAUDE.md` indexes — each has `- filename.md — description` entries. Rank candidates against derived terms from these descriptions. **Load fully the top 3.** Rest stay noted, available on demand if a finding needs them. For files not in any index, sniff individually (`Read(file_path, limit=3)`: line 1 = description, line 2 = `**Keywords:**`, line 3 = `**Related:**`). Plan mode: also grep content; same top-3 cap.

**4. Follow cross-refs** while keywords match derived terms. Check `## Cross-Refs` in loaded files; check `**Related:**` in sniffed headers. Cross-cluster refs use full paths; intra-cluster discovery uses the cluster `CLAUDE.md`. Announce at 3+ hops. Plan mode: also announce skipped refs.

## Observability

Always announce searches and results. No-match announcements are mandatory.

**Gate tags** (which trigger fired): `session-start` · `plan-mode` · `implementation` · `keyword` · `domain-shift` · `pre-edit`

**Source tags** (how the file was found): `via index` · `via pipeline` · `via both` · `via content grep` · `via cross-ref`

**Format**: `📚 [gate] loaded X (source, reason)` · `📚 [gate] "term" — no matches` · `📚 [gate] skipped X (domain mismatch: reason)`

Plan mode uses block format with per-file matched/skipped lines and explicit no-match terms.

**Persona**: `🎭 No persona active — recommending X. Set it?` · `🎭 Persona active: X — proceeding` · `🎭 No persona — none relevant, proceeding without`

## Personas

Personas = lens (priorities, tradeoffs). Learnings = knowledge (gotchas, patterns). Both operate independently.

**Subagent propagation**: include persona filename in subagent prompts for domain work. Skip for utility tasks.

**Review subagent propagation**: when a review-entry gate fired and you're delegating review to subagents (e.g., `/simplify`'s parallel reuse/quality/efficiency agents), include the loaded learnings as "known patterns to check against" in each agent's prompt. Subagents do their own searches, but seeding them with the patterns you already loaded prevents independent rediscovery and tightens findings against your documented conventions. Native skills (those defined in Claude Code itself, not under `~/.claude/`) can't be modified — but you control what goes into the subagent prompts they tell you to write, so the propagation happens at prompt-construction time.
