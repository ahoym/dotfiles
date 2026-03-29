# Federated Learnings Directory

## Problem

The `~/.claude/learnings/` directory is flat with 57 files and a single `CLAUDE.md` index (~97 lines). Both will continue growing. At 100+ files:

- The index approaches the 200-line truncation ceiling in memory/context systems
- Flat directory becomes hard for operators to browse
- Agent filename matching gets noisier (more candidates per search term)
- The single index does double duty as both routing table and file catalog

## Target State

```
learnings/
├── CLAUDE.md                        ← routing table (~25 lines)
│
├── claude-authoring/
│   ├── CLAUDE.md                    ← domain index (7+ entries)
│   ├── skills.md
│   ├── guidelines.md
│   ├── learnings.md
│   ├── claude-md.md
│   ├── content-types.md
│   ├── personas.md
│   └── polling-review-skills.md
│
├── claude-infra/
│   ├── CLAUDE.md
│   ├── claude-code.md
│   ├── hooks.md
│   ├── platform-portability.md
│   ├── multi-agent.md
│   ├── parallel-plans.md
│   ├── ralph-loop.md
│   ├── explore-repo.md
│   └── cross-repo-sync.md
│
├── xrpl/
│   ├── CLAUDE.md
│   ├── patterns.md
│   ├── gotchas.md
│   ├── amm.md
│   ├── cross-currency-payments.md
│   ├── dex-data.md
│   └── permissioned-domains.md
│
├── java/
│   ├── CLAUDE.md
│   ├── spring-boot.md
│   ├── spring-boot-gotchas.md
│   ├── observability.md
│   ├── observability-gotchas.md
│   ├── infosec-gotchas.md
│   └── quarkus-kotlin.md
│
├── frontend/
│   ├── CLAUDE.md
│   ├── react-patterns.md
│   ├── react-gotchas.md
│   ├── nextjs.md
│   ├── ui-patterns.md
│   ├── accessibility.md
│   ├── typescript.md
│   └── typescript-ci-gotchas.md
│
├── aws/
│   ├── CLAUDE.md
│   ├── patterns.md
│   ├── messaging.md
│   └── vercel-deployment.md
│
├── cicd/
│   ├── CLAUDE.md
│   ├── patterns.md
│   ├── gotchas.md
│   └── gitlab.md
│
├── database/
│   ├── CLAUDE.md
│   ├── postgresql-query-patterns.md
│   └── local-dev-seeding.md
│
├── financial/
│   ├── CLAUDE.md
│   ├── applications.md
│   ├── bignumber-arithmetic.md
│   └── order-book-pricing.md
│
├── api-design.md                    ← domain-general files stay at root
├── code-quality-instincts.md
├── refactoring-patterns.md
├── testing-patterns.md
├── playwright-patterns.md
├── newman-postman.md
├── git-patterns.md
├── bash-patterns.md
├── python-specific.md
├── resilience-patterns.md
├── reactive-data-patterns.md
├── web-session-sync.md
└── process-conventions.md
```

## Naming Convention

Domain prefixes drop from filenames — the directory carries that signal now.

| Before (flat) | After (federated) |
|---|---|
| `xrpl-patterns.md` | `xrpl/patterns.md` |
| `claude-authoring-skills.md` | `claude-authoring/skills.md` |
| `spring-boot-gotchas.md` | `java/spring-boot-gotchas.md` |
| `react-frontend-gotchas.md` | `frontend/react-gotchas.md` |
| `bignumber-financial-arithmetic.md` | `financial/bignumber-arithmetic.md` |

Exception: filenames where the prefix is part of the identity, not just a category tag, keep it. `spring-boot.md` stays `spring-boot.md` inside `java/` because "Spring Boot" is the subject, not a namespace. Same for `react-patterns.md` — "React" is the topic.

## Top-Level Routing Table

The root `CLAUDE.md` becomes a lightweight routing table. One entry per domain with a description and keyword hints:

```markdown
# Learnings Index

Read this file first. Identify relevant domains, then read their `CLAUDE.md` indexes.

If `~/.claude/learnings-private/CLAUDE.md` exists, read it too.
If `docs/learnings/CLAUDE.md` exists in the current project, read it for repo-local learnings.

---

| Domain | Dir | Covers |
|--------|-----|--------|
| Claude Authoring | `claude-authoring/` | CLAUDE.md files, skills, guidelines, personas, content types, learnings curation |
| Claude Infrastructure | `claude-infra/` | Claude Code tool, hooks, multi-agent, parallel plans, platform portability, ralph loop |
| XRPL | `xrpl/` | XRPL patterns, AMM, cross-currency payments, DEX data, permissioned domains |
| Java / Spring Boot | `java/` | Spring Boot, Quarkus/Kotlin, observability/Micrometer, infosec |
| Frontend / React | `frontend/` | React 19, Next.js, TypeScript, UI/CSS, accessibility, Playwright, CI gotchas |
| AWS / Infrastructure | `aws/` | EventBridge, SQS/SNS, IAM, Lambda, Vercel deployment |
| CI/CD | `cicd/` | GitHub Actions, GitLab CI, Docker pipelines, CI gotchas |
| Database | `database/` | PostgreSQL queries, migrations, local dev seeding |
| Financial | `financial/` | Monetary safety, BigNumber.js, order book pricing |
```

Root-level files (domain-general) are listed inline in the routing table:

## Root Files (domain-general)

- `api-design.md` — API design: consistent response shapes, versioning, error contracts
- `code-quality-instincts.md` — Fundamental code quality practices across all languages
- `refactoring-patterns.md` — Refactoring guidelines: survey before acting, scope discipline
- `testing-patterns.md` — Testing patterns: Vitest + React Testing Library, test structure, mocking
- `playwright-patterns.md` — Playwright E2E testing: patterns, gotchas, best practices
- `newman-postman.md` — Newman/Postman: skipRequest synchronous constraint, collection patterns
- `git-patterns.md` — Git patterns: commit-message-based identification, rebase, branch management
- `bash-patterns.md` — Bash patterns: shell env default ordering, quoting gotchas
- `python-specific.md` — Python patterns: Pydantic v2 optional fields, serialization
- `resilience-patterns.md` — Resilience patterns: idempotent processing, reprocessing loop prevention
- `reactive-data-patterns.md` — Reactive data patterns for real-time UIs
- `web-session-sync.md` — Web session sync: when sync is needed vs not
- `process-conventions.md` — Engineering process conventions: scoping, tracking, work organization
```

This keeps the routing table self-contained — one read gives both the domain routing and the root file catalog. When root files cluster into a new theme (3+ files), promote them to a domain directory.

~35 lines total. Still well under any truncation ceiling and stable at scale.

## Domain Index Format

Each domain's `CLAUDE.md` mirrors today's format but scoped to its domain:

```markdown
# XRPL Learnings

- `patterns.md` — XRPL patterns: getOrderbook vs raw book_offers, xrpl.js v4 specifics
- `gotchas.md` — Condensed XRPL integration tripwires (companion to patterns.md)
- `amm.md` — XRPL AMM: constant-product formulas with fee, LP token mechanics
- `cross-currency-payments.md` — Cross-currency payments: delivered_amount, path finding, slippage
- `dex-data.md` — XRPL DEX external APIs: OnTheDEX token data, market data sources
- `permissioned-domains.md` — Permissioned domains and credentials (feature status, setup)
```

## Protocol Delta

### What changes

**Step 1 (glob) → two-hop lookup + root scan:**

```
# Before
Glob: ~/.claude/learnings/*.md → full file list

# After
Read: ~/.claude/learnings/CLAUDE.md → routing table (domains) + root file list
Match domains against search terms → read matched domain CLAUDE.md indexes
Match root filenames against search terms (same as today, smaller set)
```

**Step 3 (sniff) → likely unnecessary:**

Domain indexes carry descriptions. The sniff step (read 5 lines to check relevance) existed because filenames alone were weak signals. With descriptions in the domain index, sniffing is redundant for files listed in the index. Reserve sniffing only for files not yet indexed (e.g., just created, index not updated).

**Cross-ref paths gain a directory component:**

```markdown
## Cross-Refs

~/.claude/learnings/java/spring-boot-gotchas.md — Spring Boot instrumentation pitfalls
~/.claude/learnings/database/postgresql-query-patterns.md — migration patterns
```

**Soft gates match on domain directories, not just filenames:**

Domain-shift detection becomes more precise — match the domain directory first, then scan its index. A user pivoting to "Fargate" matches `aws/` → read `aws/CLAUDE.md` → load relevant files.

### What stays the same

- Hard gate triggers (session start, plan mode, implementation start)
- Cross-ref convention (`## Cross-Refs` as last section, semantic refs only)
- Source attribution tags in announcements
- Observability format (announce loads, no-matches, skips)
- `learnings-private/` and `docs/learnings/` as additional search locations
- Content grep in plan mode (now scoped to matched domain directories)
- Dedup rule for soft gates

### Session-start protocol (rewritten)

```
1. Read ~/.claude/learnings/CLAUDE.md (routing table + root file list)
2. Derive search terms from ambient context + user message
3. Match terms against:
   a. Domain names and keyword hints → read matched domain CLAUDE.md indexes
   b. Root-level filenames + descriptions (domain-general files)
4. For each matched domain:
   a. Read ~/.claude/learnings/<domain>/CLAUDE.md (domain index)
   b. Match filenames + descriptions against search terms
   c. Load matched files
   d. Follow cross-refs (up to two levels)
5. Load matched root-level files
6. Announce results (including no-matches at both domain and file level)
```

### Plan-mode protocol (rewritten)

```
1. Read routing table (if not already in context)
2. Derive search terms from current task scope (cast wider net)
3. Match terms against ALL domain names — plan mode errs toward inclusion
4. For each matched domain:
   a. Read domain index
   b. Match filenames + descriptions against search terms
   c. Content grep within matched domain directories for buried terms
   d. Load matched files
   e. Follow cross-refs, announce skips
5. Enhanced announcement format (unchanged, paths gain directory component)
```

### Observability delta

Domain-level matching adds a new announcement layer:

```
📚 Session start — domains matched: [java, database] from terms ["spring boot", "migration"]
📚 java/ — loaded spring-boot-gotchas.md (via index, migration patterns)
📚 java/ — loaded spring-boot.md (via index, general Spring Boot)
📚 database/ — loaded postgresql-query-patterns.md (via cross-ref from spring-boot-gotchas)
📚 Domains skipped: [xrpl, frontend, ...] (no term match)
```

## Migration Plan

### Phase 1: Prepare (before trigger point)

1. **Finalize domain groupings.** Review the proposed structure above — some files straddle domains (e.g., `vercel-deployment.md` in `aws/` vs a potential `deployment/` domain). Resolve edge cases.
2. **Audit cross-refs.** Catalog all existing `## Cross-Refs` sections and map old paths to new paths.
3. **Audit persona cross-refs.** Personas in `~/.claude/commands/set-persona/` reference learnings paths — catalog those too.

### Phase 2: Restructure (the migration)

4. **Create domain directories** and move files, renaming where the prefix drops.
5. **Write domain `CLAUDE.md` indexes** — one per domain, descriptions carried from the current flat index.
6. **Rewrite root `CLAUDE.md`** as routing table.
7. **Update all cross-ref paths** in learnings files (old → new paths).
8. **Update persona cross-refs** to new paths.
9. **Update symlink setup** if `setup-claude.sh` does per-file linking (vs directory linking).

### Phase 3: Protocol update

10. **Update `context-aware-learnings.md`** guideline with federated protocol.
11. **Update `claude-authoring-learnings.md`** with federated index maintenance rules.
12. **Update any skills** that reference learnings paths directly (e.g., `/learnings:compound`, `/learnings:curate`).

### Phase 4: Validate

13. **Test session-start gate** — verify routing table → domain index → file loading works.
14. **Test plan-mode gate** — verify broader search with content grep scoped to domain dirs.
15. **Test soft gates** — verify domain-shift detection routes through domain indexes.
16. **Spot-check cross-refs** — verify paths resolve after migration.

## Trigger Point

Pull the trigger at **~75-80 files**. This gives headroom before the index hits truncation and means the migration happens while the file count is still manageable. At current growth rate, estimate this based on how frequently `/learnings:compound` adds new files.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Domain boundary disputes (file fits two domains) | Primary domain owns the file; cross-ref from secondary domain's index. Don't duplicate files. |
| Root accumulates too many files | Review root files during curation passes. If 3+ files share a sub-theme, promote to a new domain directory. Root should stay under ~15-20 files. |
| Two-hop adds latency at session start | Routing table is ~20 lines (trivial read). Domain indexes are 5-15 lines each. Total cost is comparable to today's single 100+ line read, just distributed. |
| Stale domain indexes | Same maintenance cadence as today — add entry when adding a file. Domain-scoped indexes are easier to keep current because changes are local. |
| Skills/personas with hardcoded paths break | Phase 2 step 8 catches these. Run a grep for `learnings/` paths across the full config before declaring migration complete. |
| `learnings-private/` and `docs/learnings/` inconsistency | These can stay flat longer (likely smaller). Federate them independently when they hit their own scaling point. |

## Non-Goals

- **Nesting deeper than one level.** `learnings/java/spring-boot/` is over-engineering. One level of domain grouping is the sweet spot.
- **Automating the migration.** The file count is small enough that manual migration with grep validation is safer and faster than writing a script.
- **Changing the cross-ref convention.** Semantic cross-refs work the same way — only the paths change.
- **Restructuring `learnings-private/` or `docs/learnings/` simultaneously.** Scope this to the global learnings directory. Other locations federate independently if/when needed.
