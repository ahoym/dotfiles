Patterns for the `/explore-repo` skill — parallel multi-agent scanning, domain file structure, synthesis output, staleness detection, and CLAUDE.md generation.
- **Keywords:** explore-repo, multi-agent scan, domain files, synthesis, SYSTEM_OVERVIEW, inconsistencies, CLAUDE.md generation, staleness detection, cross-domain dedup, greenfield
- **Related:** multi-agent-patterns.md, claude-authoring-skills.md

---

## Parallel Multi-Agent Exploration for Unfamiliar Repos

When mapping an unfamiliar codebase, launch 5 specialized Explore agents in parallel across orthogonal dimensions:

1. **API surface** — controllers, endpoints, request/response types, error handling
2. **Data model** — entities, enums, DTOs, schema/migrations
3. **Core workflow** — business logic orchestration, state machines, event routing
4. **External integrations** — clients, protocols, auth mechanisms, config properties
5. **Dependencies & infrastructure** — build config, Docker, CI/CD, profiles

Each agent searches broadly within its dimension (glob + grep across multiple naming conventions). Results synthesize into a complete picture in ~2 minutes wall clock. Key: agents must search *broadly* — don't assume standard package names. Search for annotations (`@Entity`, `@RestController`), base classes, and interface patterns, not just package paths.

## Structuring Repo Learnings for Agent Consumption

When capturing repo knowledge for agents, split into orthogonal files that can be loaded independently:

| File | Covers | When to load |
|------|--------|-------------|
| `api-surface.md` | Controllers, endpoints, request/response contracts | Working on API changes, debugging HTTP issues |
| `data-model.md` | Entities, enums, relationships, migrations | Schema changes, new entities, query work |
| `settlement-workflow.md` (or domain equivalent) | Core business logic flow, state machines | Feature work touching orchestration |
| `external-integrations.md` | Clients, protocols, auth, config prefixes | Integration work, debugging external calls |
| `dependencies-and-infrastructure.md` | Build, Docker, CI/CD, profiles | Build issues, dependency upgrades, deployment |

Place under `docs/learnings/` with a `README.md` index. Each file should be self-contained — an agent reading just one file gets a complete picture of that dimension without needing the others. Use tables over prose for reference-heavy content. Include file paths to key classes so agents can jump directly to source.

## Synthesis Phase Context Budget

The synthesis phase reads all 7 domain scan files + existing docs into a single context window. For a medium-sized server (~100 source files), the scan files alone consumed ~15k tokens — manageable but substantial. For larger repos (500+ source files), the domain files could easily exceed 50k tokens, leaving insufficient budget for the synthesis writing itself.

**Mitigation options for large repos:**
- Run synthesis as a Task subagent with its own context budget
- Summarize domain files before loading (trade-off: loses detail for cross-referencing)
- Split synthesis into sub-phases (e.g., SYSTEM_OVERVIEW separate from cross-references and CLAUDE.md updates)

## Subdirectory CLAUDE.md Decision Heuristic

The skill's checklist for subdirectory CLAUDE.md candidates (complex state machines, legacy coexistence, etc.) is useful but the sharper decision criterion is: **"Would an agent entering this directory without context make a mistake that produces silently wrong output?"**

Prioritize directories where mistakes produce **silently incorrect results** over directories where mistakes produce **visible errors** (exceptions, connection failures, deserialization errors).

Example from a financial calculations directory:
- Reciprocal currency inversion (`1/stableOffer × fiatBid` vs `fiatBid × stableOffer`) — wrong choice produces plausible but incorrect prices
- Forward points subtract not add — "fixing" to addition silently breaks all tenor prices
- Two divergent code paths for different upstream data providers — changing one without knowing the other exists

Directories skipped (mistakes are visible):
- WebSocket clients → connection/deserialization errors surface immediately
- Data classes → type mismatches caught at compile time
- HTTP publishers → failed requests produce HTTP error codes

## Cross-Domain Finding Deduplication

When 7 agents scan independently, cross-cutting findings (e.g., security issues, naming conventions) get repeated in multiple domain files. In one project, the `permitAll()` security finding appeared in 5 of 7 files.

**Rule for agents:** When a finding spans multiple domains, report the full analysis in the most relevant domain file. In other domains, mention it briefly with a cross-reference: *"Security configuration permits all endpoints — see `config-ops.md` § Security for full analysis."*

## Diff-Based Staleness Detection

Scan tools that commit their own artifacts always trigger a false "stale" signal on the next freshness check, because the commit that adds the docs differs from the commit recorded in scan metadata.

**Fix:** Exclude known output files from the diff using git pathspec exclusions:
```bash
git diff --stat <scan-commit>..HEAD \
  ':!docs/learnings/structure.md' \
  ':!docs/learnings/api-surface.md' \
  # ... all 9 known output files
```

**Use explicit file lists, not directory globs.** `':!docs/learnings/'` would also hide user-authored files in that directory (e.g., `project-history.md`). The skill knows exactly which files it writes — enumerate them.

**CLAUDE.md/README.md special case:** Keep the "mark all domains for re-scan" rule for these files. Synthesis modifies them, which creates some false positives, but genuine user edits to project-level docs are meaningful context for all agents. The tradeoff is worth it — occasional unnecessary re-scans are cheap, missing a real context change is expensive.

This pattern applies to any tool that: (1) records a source commit in metadata, (2) generates output that gets committed to the same repo.

## Cross-Agent Scan Inconsistencies

Independent scan agents can report contradictory findings about the same code. Example: the data-model agent reported a token expiry bug as active, while the integrations agent (which checked git history) correctly identified it as fixed. Neither agent cross-references the other's output.

**Root cause:** Each agent operates in isolation with no shared state. If a finding spans domains (e.g., a bug in a utility used by integrations but modeled in data-model), the agent that happens to check git blame gets it right while the other relies on stale code comments.

**Mitigation:** The synthesis phase should cross-check gotchas across domain files. When two files make contradictory claims about the same code, flag it and resolve using the evidence (git history, actual code state). This is cheaper than wiring inter-agent communication.

## Domain Mapping Table Is Language-Specific

The path-to-domain mapping table in the skill uses Java/Spring patterns (`*Controller*`, `*Entity*`, `*Repository*`, `application*.properties`). For Python/FastAPI projects, none of these match — the actual patterns are `router*.py`, `models.py`, `adapters/`, `clients/`, `env_vars.py`.

**Options (increasing complexity):**
1. Add Python/FastAPI patterns alongside Java patterns in the table (works for most projects)
2. Allow a `.domain-mapping.yml` override in the project for custom mappings
3. Auto-detect project type and select the appropriate pattern set

Option 1 is sufficient for now — most repos are single-language.

## CLAUDE.md Should Not `@`-Include Scan Artifacts

Use plain path references (`` `docs/learnings/structure.md` ``) instead of `@` includes for scan artifacts in CLAUDE.md. `@` auto-loads all referenced files into every session's context — for a full 7-domain scan, that's ~30k+ tokens consumed before the session even starts, regardless of whether the task needs them.

Plain paths preserve discoverability (agent knows where to `Read` on demand). `/explore-repo:brief` provides structured on-demand loading when full context is needed.

## Tailor PROJECT_CONTEXT Hints Per Agent Domain

When constructing the PROJECT_CONTEXT for each domain agent, add short contextual hints that steer the agent away from fruitless searches. Example: for a stateless Python/FastAPI service with no database, adding *"Note: This project appears to be stateless (no database) — focus on Pydantic models used for API contracts and inter-service communication"* to the data model agent's context prevents it from hunting for ORMs, migrations, and repositories that don't exist.

**Pattern:** After the orchestrator's project detection phase, identify characteristics that would confuse specific agents and inject 1-2 sentence hints. Common cases:
- No database → data model agent
- No CI pipeline → structure agent
- No test infrastructure → testing agent
- Monorepo vs single-app → all agents (scope boundaries)

## Inconsistencies.md Is Thin Without Existing CLAUDE.md

When synthesizing a repo that has no CLAUDE.md (only README.md), the inconsistencies analysis yields few findings — README.md is typically a setup guide with limited technical claims to contradict. The highest-value discrepancies (e.g., stale `.env.template` vs actual `env_vars.py`) are caught by domain scans (config-ops), not by the synthesis-phase README comparison.

**Implication for skill design:** Consider extending the inconsistency analysis to also diff configuration templates against canonical code references (e.g., `.env.template` vs `env_vars.py`, CI config vs actual commands). These "code vs code" comparisons find more actionable issues than "doc vs code" when docs are sparse.

## Single-Pass Synthesis From Domain Files

The 7 domain scan files provide enough structured input to produce the full synthesis output set in a single pass — no iterative refinement needed. This applies to both greenfield (no CLAUDE.md) and update scenarios. The domain decomposition does the heavy lifting; synthesis just cross-references and condenses.

**Full synthesis output set** (all writable in one pass):
1. `SYSTEM_OVERVIEW.md` — cross-domain overview, resilience assessment, coverage gaps
2. `inconsistencies.md` — doc-vs-code + config artifact drift
3. Cross-reference sections appended to each domain file
4. CLAUDE.md updates (auto-fixes + new sections like Critical Business Rules, Context-Specific Guides)
5. Subdirectory CLAUDE.md files (where silently-wrong-output risk exists)
6. README.md fixes (if applicable)

## Greenfield CLAUDE.md Deserves Prominent Summary Treatment

When synthesis creates a CLAUDE.md where none existed, this is the single highest-impact output. The synthesis summary should call it out beyond a one-liner — e.g., "Created CLAUDE.md (new — no previous project guide existed)" with a 2-3 line synopsis of what it covers (architecture, commands, patterns, gotchas). Distinguishes it from a routine update.

## Auto-Fix Strategy for Doc-vs-Code Inconsistencies

For doc-vs-code inconsistencies found during scanning:
- **Critical** (actively misleading): Always auto-fix. Example: wrong package version.
- **Medium** (partially wrong): Auto-fix. Example: missing commands, incomplete module lists.
- **Low** (minor): Auto-fix if simple text replacement; skip if requires judgment. Example: cosmetic version pinning.
- **Judgment calls**: Mark as `[UNFIXED]` with reason. Example: README may intentionally show a simplified view.

**README.md fixes require holistic treatment.** Unlike CLAUDE.md (where individual section fixes are safe), README inconsistencies often cluster — a quick-start section with a wrong script name, wrong infrastructure references, and outdated version links should be fixed together or not at all. Partial fixes risk introducing new inconsistencies (e.g., fixing the DB reference but leaving the wrong setup script). Mark README issues as `[UNFIXED]` with "requires holistic review" when 3+ issues cluster in one section.

## Cross-Reference Sections Create a Documentation Graph

Adding `## Cross-references` sections to domain scan files creates a navigable documentation graph. Only add genuine relationships — don't cross-reference everything to everything. Place the section before `## Scan Limitations`.

## Cross-Refs

- `multi-agent-patterns.md` — synthesis architecture and subagent coordination
- `claude-authoring-skills.md` — stateful mode detection patterns
