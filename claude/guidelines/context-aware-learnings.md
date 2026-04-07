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
| **Keyword** | Domain keyword or quoted term in user message | Glob filenames → unloaded matches. Quoted terms bypass dedup. | No |
| **Domain shift** | User message introduces new domain | Glob filenames → new domain keywords | No |
| **Pre-edit check** | First Edit/Write in unloaded tech domain | Glob filenames → file's tech domain | No |

**Dedup**: don't re-load files already read this session. When context compression makes history uncertain, err toward re-checking.

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
