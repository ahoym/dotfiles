# Learnings Search Protocol

## Directories

All searches target these directories (when they exist):
- `~/.claude/learnings/` (global)
- `~/.claude/learnings-private/` (private)
- `docs/learnings/` (project-local)

Each may have a `CLAUDE.md` index — read it at every gate for index-based matching alongside the pipeline.

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

**1. Glob filenames.** `*.md` across all directories. Don't embed search terms in glob patterns (`*spring*` misses `spring-boot-gotchas.md`).

**2. Derive terms.** Session start: ambient context (branch, CWD, git status, CLAUDE.md) + user message. Plan mode: broad task scope — topics, technologies, adjacent domains. Keyword: domain terms from user message. Soft gates: new domain keywords from message or target file.

**3. Match and sniff.** For each filename match, `Read(file_path, limit=5)`. Load fully only if relevant. Plan mode: also grep file content.

**4. Follow cross-refs** (up to 2 levels). Check `## Cross-Refs` in loaded files. Plan mode: also announce skipped cross-refs.

## Observability

Always announce searches and results. No-match announcements are mandatory.

**Source tags**: `(via index)` · `(via pipeline)` · `(via both)` · `(via content grep)` · `(via cross-ref)` · `(via keyword)` · `(via domain shift)` · `(via pre-edit check)`

**Formats**: `📚 Session start — loaded X (via tag, reason)` · `📚 "keyword" → loaded X (via tag)` · `📚 Searched for "X" — no matches` · `📚 Skipped <file> (domain mismatch: <reason>)` · `📚 Cross-ref from X → loaded Y (via cross-ref, reason)`

Plan mode uses block format with per-file matched/skipped lines and explicit no-match terms.

**Persona**: `🎭 No persona active — recommending X. Set it?` · `🎭 Persona active: X — proceeding` · `🎭 No persona — none relevant, proceeding without`

## Personas

Personas = lens (priorities, tradeoffs). Learnings = knowledge (gotchas, patterns). Both operate independently.

**Subagent propagation**: include persona filename in subagent prompts for domain work. Skip for utility tasks.
