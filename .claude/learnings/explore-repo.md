# explore-repo Learnings

## Synthesis Phase Context Budget

The synthesis phase reads all 7 domain scan files + existing docs into a single context window. For freac-server (~100 source files), the scan files alone consumed ~15k tokens — manageable but substantial. For larger repos (500+ source files), the domain files could easily exceed 50k tokens, leaving insufficient budget for the synthesis writing itself.

**Mitigation options for large repos:**
- Run synthesis as a Task subagent with its own context budget
- Summarize domain files before loading (trade-off: loses detail for cross-referencing)
- Split synthesis into sub-phases (e.g., SYSTEM_OVERVIEW separate from cross-references and CLAUDE.md updates)

## Subdirectory CLAUDE.md Decision Heuristic

The skill's checklist for subdirectory CLAUDE.md candidates (complex state machines, legacy coexistence, etc.) is useful but the sharper decision criterion is: **"Would an agent entering this directory without context make a mistake that produces silently wrong output?"**

Prioritize directories where mistakes produce **silently incorrect results** over directories where mistakes produce **visible errors** (exceptions, connection failures, deserialization errors).

Example from freac-server `pricing/`:
- Reciprocal currency inversion (`1/stableOffer × fiatBid` vs `fiatBid × stableOffer`) — wrong choice produces plausible but incorrect prices
- Forward points subtract not add — "fixing" to addition silently breaks all tenor prices
- Two divergent code paths for Monex vs Refinitiv — changing one without knowing the other exists

Directories skipped (mistakes are visible):
- WebSocket clients → connection/deserialization errors surface immediately
- Data classes → type mismatches caught at compile time
- HTTP publishers → failed requests produce HTTP error codes

## Cross-Domain Finding Deduplication

When 7 agents scan independently, cross-cutting findings (e.g., security issues, naming conventions) get repeated in multiple domain files. In ledger-service-server, the `permitAll()` security finding appeared in 5 of 7 files.

**Rule for agents:** When a finding spans multiple domains, report the full analysis in the most relevant domain file. In other domains, mention it briefly with a cross-reference: *"Security configuration permits all endpoints — see `config-ops.md` § Security for full analysis."*

## Diff-Based Staleness Detection

Scan tools that commit their own artifacts always trigger a false "stale" signal on the next freshness check, because the commit that adds the docs differs from the commit recorded in scan metadata.

**Fix:** Replace naive `scan_commit != HEAD` with a source diff check:
```bash
git diff --name-only <scan-commit>..HEAD -- ':!<artifact-path>/' ':!**/CLAUDE.md'
```
Empty diff = current (only scan output changed). Non-empty diff = genuinely stale.

This pattern applies to any tool that: (1) records a source commit in metadata, (2) generates output that gets committed to the same repo.

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

## Single-Pass CLAUDE.md Creation From Domain Files

When no CLAUDE.md exists, the 7 domain scan files provide enough structured input to write a comprehensive CLAUDE.md in a single pass — no iterative refinement needed. The domain decomposition does the heavy lifting: structure.md provides the architecture, api-surface.md provides the endpoint inventory, config-ops.md provides the commands and env vars, etc. The synthesis just cross-references and condenses.

## Greenfield CLAUDE.md Deserves Prominent Summary Treatment

When synthesis creates a CLAUDE.md where none existed, this is the single highest-impact output. The synthesis summary should call it out beyond a one-liner — e.g., "Created CLAUDE.md (new — no previous project guide existed)" with a 2-3 line synopsis of what it covers (architecture, commands, patterns, gotchas). Distinguishes it from a routine update.

## Auto-Fix Strategy for Doc-vs-Code Inconsistencies

For doc-vs-code inconsistencies found during scanning:
- **Critical** (actively misleading): Always auto-fix. Example: wrong package version.
- **Medium** (partially wrong): Auto-fix. Example: missing commands, incomplete module lists.
- **Low** (minor): Auto-fix if simple text replacement; skip if requires judgment. Example: cosmetic version pinning.
- **Judgment calls**: Mark as `[UNFIXED]` with reason. Example: README may intentionally show a simplified view.

## Cross-Reference Sections Create a Documentation Graph

Adding `## Cross-references` sections to domain scan files creates a navigable documentation graph. Only add genuine relationships — don't cross-reference everything to everything. Place the section before `## Scan Limitations`.
