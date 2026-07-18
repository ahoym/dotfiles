---
name: explore-repo
description: "Deep-scan a repository to understand its structure, functionality, and documentation gaps."
argument-hint: "[repo-path]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Task
  - WebFetch
  - AskUserQuestion
---

## Context
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`
- Current branch: !`git branch --show-current 2>/dev/null`
- HEAD: !`git rev-parse --short HEAD 2>/dev/null`
- Upstream default: !`git rev-parse --abbrev-ref origin/HEAD 2>/dev/null`
- Upstream default SHA: !`git rev-parse --short origin/HEAD 2>/dev/null`

# Explore Repository

Deep-scan a repository using parallel exploration agents to produce comprehensive documentation, identify documentation gaps, and flag inconsistencies between code and existing docs.

Operates in two modes based on file state — **scan mode** writes domain-specific docs, **synthesis mode** reads them to produce cross-domain outputs. Each invocation runs one mode only.

## Usage

- `/explore-repo` - Auto-detect mode based on file state
- `/explore-repo <focus-areas>` - Scan specific dimensions only (comma-separated: structure, api, data-model, integrations, flows, config, testing)

## Eager-load at bootstrap

*(skill-launched sessions suppress the learnings gate.)* Read these before starting:

- **`~/.claude/learnings/claude-code/explore-repo.md`** — scan-target selection, mode detection, and synthesis patterns this skill implements.
- **`~/.claude/learnings/claude-code/multi-agent/orchestration.md`** — parallel Agent-fan-out patterns for the Phase 3 exploration agents.

## Reference Files

- @agent-prompts.md - Detailed prompts and mandates for each exploration agent
- `~/.claude/skill-references/subagent-patterns.md` — Universal patterns for launching and orchestrating subagents

## Instructions

### Phase 0: Scan Target Selection

The skill scans the working tree as-is. Default expectation is the canonical baseline (latest upstream default branch) so the docs match what new readers see in `main`; pick the operator's current branch only when scanning in-flight work that isn't merged yet.

1. **Refresh remote refs:** `git fetch origin --prune` (silent on success). If it fails (offline / no origin), skip step 2–3 and use the current branch as `SCAN_REF`.
2. **Resolve upstream default:** `git rev-parse --abbrev-ref origin/HEAD` — typically `origin/main`. If unset, try `origin/main`, then `origin/master`. If none exist, fall back to the current branch as `SCAN_REF`.
3. **Skip the prompt — silent fast paths.** No prompt needed in either case below; proceed using `<DEFAULT_REF>` as the metadata stamp.
   - **Case A: HEAD == `<DEFAULT_REF>`.** Working tree is the baseline. Proceed in place.
   - **Case B: HEAD is 1–5 commits ahead of `<DEFAULT_REF>` with doc-only changes.** This is the common case where a dev runs `/explore-repo` repeatedly on a branch off main and accumulates artifact commits. Detect it like this:
     - Distance: `git rev-list --count <DEFAULT_REF>..HEAD`. If 0 → Case A. If >5 → fall through to step 4.
     - Reachability: `git merge-base --is-ancestor <DEFAULT_REF> HEAD` (must succeed; otherwise fall through — HEAD diverged).
     - Doc-only diff: `git diff --name-only <DEFAULT_REF>..HEAD`. Every changed path must match the doc-artifact allowlist:
       - `docs/**` (any docs subdirectory, including `docs/explore-repo/`, `docs/learnings/`, `docs/features/`, etc.)
       - `CLAUDE.md`, `**/CLAUDE.md` (root and subdirectory CLAUDE.md files — these are the skill's own outputs)
       - `README.md`
       - `.claude/**` (skill/settings tooling)
     - If every path matches → silently take the fast path. Source code is identical to baseline; the docs are the only delta and will be regenerated.
     - Announce: `📚 HEAD is N commit(s) ahead of <DEFAULT_REF> with doc-only changes — scanning at baseline (<DEFAULT_REF> @ <sha>)`.
4. **Prompt the operator** (use `AskUserQuestion` if available; otherwise output the question and stop for input). Reached only when neither fast path in step 3 applied — HEAD diverged from the baseline by source-code changes, or by more than 5 commits, or it isn't a descendant of `<DEFAULT_REF>` at all:
   - Question: `Scan target?`
   - Option 1 (DEFAULT): `<DEFAULT_REF> @ <short-sha>` — "Latest upstream — recommended."
   - Option 2: `<current-branch> @ <short-sha>` — "Current working-tree HEAD."
5. **Verify working tree matches the chosen target.** (Step 3's fast paths already guarantee this; this step only applies when step 4 ran.)
   - If the chosen ref equals current HEAD: proceed.
   - Otherwise: stop the skill and tell the operator to check it out themselves, then re-run. Output:
     ```
     The chosen scan target (<DEFAULT_REF> @ <sha>) doesn't match working-tree HEAD (<current-branch> @ <sha>).
     Check it out and re-run:
         git fetch origin && git checkout <DEFAULT_REF>
         /explore-repo
     ```
     Do NOT auto-checkout, stash, or create a worktree — leave it to the operator.
6. **Set scan metadata** for downstream phases:
   - `SCAN_REF` = the chosen branch ref (in fast paths, this is `<DEFAULT_REF>`).
   - `SCAN_COMMIT` = the short SHA at that ref. In Case A this equals current HEAD; in Case B this is the SHA of `<DEFAULT_REF>`, even though working-tree HEAD is a few commits ahead — source code is identical, so the stamp reflects the baseline readers will see.
   - Both flow into the metadata header (`commit:` and `branch:`) of every domain file and synthesis output. **All references to "current HEAD" in the rest of this file mean `SCAN_COMMIT`.**
7. **Announce** in one line: `📚 Scan target: <SCAN_REF> @ <SCAN_COMMIT>`.

### Phase 1: Mode Detection

Determine what work needs to be done by checking existing output files.

1. **Check for domain scan files and synthesis files** (run in parallel):
   - Glob for `docs/explore-repo/structure.md`
   - Glob for `docs/explore-repo/api-surface.md`
   - Glob for `docs/explore-repo/data-model.md`
   - Glob for `docs/explore-repo/integrations.md`
   - Glob for `docs/explore-repo/processing-flows.md`
   - Glob for `docs/explore-repo/config-ops.md`
   - Glob for `docs/explore-repo/testing.md`
   - Glob for `docs/explore-repo/SYSTEM_OVERVIEW.md`
   - Glob for `docs/explore-repo/inconsistencies.md`

2. **Determine which files exist and check staleness:**
   - Use `SCAN_COMMIT` and `SCAN_REF` from Phase 0 (already resolved).
   - For each existing scan file, read the first 10 lines and extract the `commit` from the scan metadata header.
   - A scan file is **stale** if its commit hash differs from `SCAN_COMMIT`.
   - A scan file is **missing** if it doesn't exist at all.

3. **Smart staleness — identify affected domains:**
   - If any scan files are stale, run `git diff --stat <stale-commit>..<SCAN_COMMIT>` to see which files changed, **excluding the skill's own output files** from the diff using git pathspec exclusions:
     ```
     git diff --stat <stale-commit>..<SCAN_COMMIT> \
       ':!docs/explore-repo/structure.md' \
       ':!docs/explore-repo/api-surface.md' \
       ':!docs/explore-repo/data-model.md' \
       ':!docs/explore-repo/integrations.md' \
       ':!docs/explore-repo/processing-flows.md' \
       ':!docs/explore-repo/config-ops.md' \
       ':!docs/explore-repo/testing.md' \
       ':!docs/explore-repo/SYSTEM_OVERVIEW.md' \
       ':!docs/explore-repo/inconsistencies.md' \
       ':!.claude/'
     ```
     This prevents the synthesis phase's own writes and `.claude/` tooling changes (skill files, settings) from triggering re-scans.

   - **Check branch topology before mapping domains.** Run `git log --oneline <stale-commit>..<SCAN_COMMIT>` to understand what the commits are. If the diff is entirely from branch switches or `.claude/` tooling work (no source code changes), skip re-scanning entirely — just stamp-update the metadata headers to `SCAN_COMMIT`. Only proceed with domain mapping if the log shows commits that touched actual source code.

   - Map changed file paths to affected domains using this table:

     | Changed path pattern | Affected domain(s) |
     |---------------------|---------------------|
     | `pom.xml`, `build.gradle`, `Makefile`, `Dockerfile`, `docker-compose*`, `.gitlab-ci.yml`, `*.sh` (root/scripts) | Structure |
     | `**/openapi*.yml`, `**/*Controller*`, `**/*Filter*`, `**/*Interceptor*`, `**/middleware/**` | API Surface |
     | `**/*Entity*`, `**/*Repository*`, `**/migration/**`, `**/schema*`, `**/*Converter*` | Data Model |
     | `**/integration/**`, `**/integrations/**`, `**/*Client*`, `**/*client/**` | Integrations |
     | `**/*Service*` (non-client), `**/*Activity*`, `**/*Processor*`, `**/*Handler*` (non-controller), `**/*Workflow*` | Processing Flows |
     | `**/application*.properties`, `**/application*.yml`, `**/*Config*`, `**/*Properties*`, `**/logback*` | Config & Ops |
     | `**/test/**`, `**/tests/**`, `**/*Test*`, `**/*IT*`, `**/testdata/**`, `**/fixtures/**` | Testing |

   - Only re-scan domains whose files were **materially** affected by the changes. Apply judgment: a 2-line property addition won't change a 350-line config scan, and adding test cases to an existing test file won't change the testing infrastructure scan. Re-scan when the changes would meaningfully alter the domain file's content (new integrations, new entities, new test patterns), not when they're incremental additions to existing patterns. When in doubt, stamp-update rather than re-scan.
   - If the diff is too large (100+ files changed) or the mapping is ambiguous, fall back to re-scanning all stale domains
   - **If `<stale-commit>` is unreachable** (e.g., scan was run on a deleted feature branch like `claude/create-feature-branch-*`), `git diff` and `git log` against it will fail. Detect via `git rev-parse <stale-commit>` returning non-zero, then fall back to re-scanning all stale domains. Don't try to find a nearest-ancestor — it's not worth the heuristic complexity.
   - **`CLAUDE.md` and `README.md` changes do not by themselves trigger a re-scan.** Agents glob/grep the working tree directly; PROJECT_CONTEXT is orientation, not source of truth. Let the path-pattern table above decide which domains are affected by actual source changes. Note that synthesis (Phase 5) writes to `CLAUDE.md` and subdirectory `CLAUDE.md` files — treating them as a re-scan trigger would create a write-loop where every synthesis run forces the next scan to redo everything.

4. **Clean up stale synthesis files:**
   - If entering **scan mode** (any domain files missing or stale), delete any existing `inconsistencies.md` — it will be regenerated in a subsequent synthesis run.
   - **Do NOT delete `SYSTEM_OVERVIEW.md`** during scan mode. Synthesis will surgically update it and needs the old version as a reference. Exception: if the stale-commit is unreachable (Phase 1 Step 3 fallback triggered), delete it — a full rewrite is necessary anyway since the diff base is gone.
   - Announce what was cleaned up.

5. **Determine mode:**

   | Condition | Mode | Action |
   |-----------|------|--------|
   | Any scan files missing (not all 7 present) | **Scan** | Scan missing domains |
   | All 7 present, stale (commit differs from `SCAN_COMMIT`) | **Scan** | Re-scan only domains affected by changes (from step 3) |
   | All 7 present, current, no SYSTEM_OVERVIEW.md | **Synthesize** | Produce synthesized outputs |
   | All 7 present, current, SYSTEM_OVERVIEW.md exists but stale | **Synthesize** | Re-synthesize |
   | All 7 present, current, SYSTEM_OVERVIEW.md current | **Up-to-date** | Nothing to do |

   **`$ARGUMENTS` override:** If focus areas are specified, always scan those domains regardless of file state.

6. **Announce mode:**
   - Print which mode was detected and why
   - If scan mode: list which domains will be scanned and why (missing vs. stale vs. affected by changes)
   - If smart staleness narrowed the re-scan scope, mention which domains were skipped and why
   - If stale synthesis files were cleaned up, mention it
   - If up-to-date: inform the operator and stop

---

### Phase 2: Project Detection (Scan Mode Only)

Before launching exploration agents, gather essential project context.

1. **Read existing documentation** (run in parallel):
   - Read CLAUDE.md at the repo root (if it exists)
   - Read README.md at the repo root (if it exists)
   - Run a broad `Glob` for top-level files to understand the repo layout

2. **If no CLAUDE.md or README.md exists**, detect the project type:
   - Look for build files: `pom.xml`, `build.gradle`, `package.json`, `Cargo.toml`, `go.mod`, `requirements.txt`, `pyproject.toml`, `Makefile`, `CMakeLists.txt`
   - Look for framework markers: `application.properties` (Spring Boot), `next.config.js` (Next.js), `angular.json`, etc.
   - Identify: primary language, framework, build system, module structure

3. **Assemble PROJECT_CONTEXT** — a concise summary containing:
   - Project name and type
   - Primary language and framework
   - Build system
   - Module structure (if multi-module)
   - Key technologies mentioned in existing docs
   - Any conventions or patterns already documented
   - Current commit hash and branch (from Phase 1)

   This context will be injected into every agent prompt.

---

### Phase 3: Parallel Exploration (Scan Mode Only)

Launch exploration agents in parallel using the Task tool. Use `subagent_type: "general-purpose"` for all agents — this allows them to spawn sub-agents if they encounter too many files.

For each agent:
1. Read the corresponding section from @agent-prompts.md
2. Construct the prompt by injecting `PROJECT_CONTEXT`, file metadata (`COMMIT_HASH`, `BRANCH_NAME`, `DATE`), and — **for stale domains only** — `CHANGED_FILES`: the domain-filtered list of changed source paths from Phase 1 Step 3, newline-separated. Omit `CHANGED_FILES` for missing domains (fresh scan, nothing to preserve).
3. Launch via Task tool

**The 7 agents:**

| # | Agent | Domain | Output File |
|---|-------|--------|-------------|
| 1 | Structure | Module layout, build system, dependencies, CI/CD | `docs/explore-repo/structure.md` |
| 2 | API Surface | REST/gRPC/CLI endpoints, request/response shapes | `docs/explore-repo/api-surface.md` |
| 3 | Data Model | Entities, schema, relationships, migrations, state machines | `docs/explore-repo/data-model.md` |
| 4 | Integrations | External services, clients, authentication, error handling | `docs/explore-repo/integrations.md` |
| 5 | Processing Flows | Core business logic, workflows, scheduled tasks, events | `docs/explore-repo/processing-flows.md` |
| 6 | Config & Ops | Configuration, profiles, monitoring, secrets, deployment | `docs/explore-repo/config-ops.md` |
| 7 | Testing | Test structure, patterns, utilities, how to run tests | `docs/explore-repo/testing.md` |

**Only launch agents for domains that need scanning** (missing or stale files, or explicitly requested via `$ARGUMENTS`).

**If `$ARGUMENTS` specifies focus areas**, only launch agents for those dimensions. Map argument names to agents:
- `structure` → Agent 1
- `api` → Agent 2
- `data-model` → Agent 3
- `integrations` → Agent 4
- `flows` → Agent 5
- `config` → Agent 6
- `testing` → Agent 7

**Launch all selected agents in a single message** to maximize parallelism.

Each agent will:
- Write its full findings to its output file (with scan metadata header)
- Return a short summary (2-3 sentences) as its task result

Wait for all agents to complete. If any agent fails, note the failure — the missing file will be picked up on the next run.

**Post-scan validation:** After all agents complete, read the first 6 lines of each output file and verify:
- The metadata header is multi-line format (not collapsed to a single line)
- The `commit` field matches `SCAN_COMMIT` and the `branch` field matches `SCAN_REF`
- If any file has a malformed header, fix it in place

---

### Phase 4: Scan Summary (Scan Mode Only)

After all agents complete, print a brief summary:

```
Scan Complete

Target: <SCAN_REF> @ <SCAN_COMMIT>

Domains scanned: [list]
Domains skipped: [list, if any — already current]
Domains failed: [list, if any]

Output files:
- docs/explore-repo/structure.md
- docs/explore-repo/api-surface.md
- ...

Run /explore-repo again to synthesize into SYSTEM_OVERVIEW.md
```

**Stop here.** Do not proceed to synthesis in the same invocation.

---

### Phase 5: Synthesis (Synthesis Mode Only)

This phase runs in a fresh invocation with a clean context. Read domain files from disk — do NOT rely on any cached or in-memory results.

1. **Read all 7 domain files** from `docs/explore-repo/`:
   - `structure.md`, `api-surface.md`, `data-model.md`, `integrations.md`, `processing-flows.md`, `config-ops.md`, `testing.md`
   - Also read the existing `docs/explore-repo/SYSTEM_OVERVIEW.md` (if it exists). Extract its `commit` stamp from the scan metadata header — call this `OVERVIEW_STALE_COMMIT`. If absent or `git rev-parse <OVERVIEW_STALE_COMMIT>` fails, plan a **full rewrite**; otherwise plan a **surgical update**.

2. **Read existing documentation** for comparison:
   - Read CLAUDE.md at the repo root (if it exists)
   - Read README.md at the repo root (if it exists)

3. **Cross-check domain files for contradictions:**

   Before synthesizing, scan all 7 domain files' `## Gotchas` sections for claims about the same code or behavior. Independent agents can report contradictory findings (e.g., one says a bug exists, another says it was fixed). When two files make conflicting claims:
   - Determine the correct state from evidence (git history, actual code)
   - Fix the incorrect domain file in place
   - Note the correction in the Phase 6 summary and commit message (and in `inconsistencies.md` only if the underlying drift is not auto-fixed — see step 5)

   **Also verify synthesized (emergent) claims absent from all domain files.** When the overview introduces a severity rating, causal chain, or failure mode that no single scan stated (e.g. escalating a scan's "KeyError when X is *unset*" into "X=bad-value → KeyError, Critical"), read the actual code path before publishing it. The contradiction check above won't catch an unsourced escalation — there is nothing to contradict.

4. **Synthesize SYSTEM_OVERVIEW.md:**

   Write a **cross-domain overview** — this is the unique value that individual domain files cannot provide on their own. Do NOT simply concatenate the domain files.

   **SURGICAL UPDATE (applies when `OVERVIEW_STALE_COMMIT` is set and reachable):**
   - Reconstruct CHANGED_FILES: `git diff --name-only <OVERVIEW_STALE_COMMIT>..<SCAN_COMMIT>` (same exclusions as Phase 1 Step 3).
   - Map CHANGED_FILES to affected sections using this table. The buckets are stack-agnostic — the examples lean Java/Spring, but match React/Python/TS equivalents to the same row — and the final catch-all row guarantees any unmatched change still refreshes the core sections:
     | Changed source path pattern | Affected SYSTEM_OVERVIEW sections |
     |-----------------------------|-----------------------------------|
     | `pom.xml`, `build.gradle`, `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `.gitlab-ci.yml`, `Dockerfile*`, `**/*.sh` | Architecture Overview, Module Dependency Graph |
     | `**/*Controller*`, `**/*Dto*`, `**/dto/**`, `**/routes/**`, `**/handlers/**`, `**/api/**` | Key Workflows (creation-side steps), Critical Path |
     | `**/*Entity*`, `**/*Repository*`, `**/migration/**`, `**/models/**`, `**/repositories/**`, `**/schema*` | Key Workflows (data-layer steps), Documentation Gaps |
     | `**/adapter/**`, `**/spi/**`, `**/*Client*` | Cross-Cutting Patterns, Key Workflows, Resilience Assessment |
     | `**/*Service*` (non-client), `**/*Scheduler*`, `**/*Poller*` | Key Workflows (add/update/remove workflow), Architecture Overview diagram |
     | `**/application*.yml`, `**/*Config*`, `**/*Properties*`, `**/*.config.*`, `**/settings*`, `.env*` | Cross-Cutting Patterns, Documentation Gaps |
     | `**/test/**`, `**/*Test*`, `**/*IT*` | Test Coverage Gaps |
     | Any changed path not matched above (catch-all) | Architecture Overview, Module Dependency Graph, and the core data / handler / config summaries (Key Workflows, Cross-Cutting Patterns) |
   - **Only rewrite sections** that map to changed paths. Copy all other sections verbatim from the existing file — exact characters, no reformatting.
   - **Always rewrite:** scan metadata header.
   - **Rewrite Project Summary and Architecture Overview** only when the module structure or core invariant changed (new `@Scheduled` job, new module, new top-level workflow added or removed).
   - **When in doubt, preserve verbatim.** Wrong preservation is recoverable; unnecessary diagram rewrites compound across runs and drift the established diagram style — exactly the problem this rule prevents.

   **Full spec (first synthesis, or unreachable stale-commit — from-scratch write):**

   **Concision mandate (same standard as the domain agents):**
   - Target length: 250–400 lines including diagrams.
   - Default to tables for parallel data and ASCII diagrams for flows / relationships; prose only when neither fits.
   - Cap section intros at 3 sentences; omit a section if its tables/diagrams already convey it.
   - One-line bullets. ≤2-sentence paragraphs. No prose summaries of what a table just showed.
   - All diagrams are ASCII box-and-arrow — no Mermaid, no rendered formats. Output must read in a plain terminal.

   Structure:
   - **Scan metadata** as HTML comment at the top (commit, branch, date, dimensions)
   - **Project Summary** (≤3 sentences) of what the system does. Follow with a one-line bullet list of architectural decisions and technology choices.
   - **Architecture Overview** (≤3 sentences) introducing the diagram below.
   - **Module Dependency Graph**: ASCII art showing how the major modules/packages depend on each other. Use box-drawing characters and show data flow direction. Example:
     ```
     ┌─────────────┐     ┌──────────────┐
     │  API Layer  │────▶│ Service Layer│
     └─────────────┘     └──────┬───────┘
                                │
                    ┌───────────┼───────────┐
                    ▼           ▼           ▼
             ┌──────────┐ ┌─────────┐ ┌──────────┐
             │ Adapters │ │   DB    │ │  Events  │
             └──────────┘ └─────────┘ └──────────┘
     ```
   - **Cross-Cutting Patterns** — table:
     | Pattern | Domains | Mechanism | Notes |
     |---------|---------|-----------|-------|
     (auth, error handling, naming conventions, transactions, retries, etc.)
   - **Key Workflows End-to-End** — for each top workflow (≤3):
     - ASCII flow / sequence diagram (API → service → data → integrations → events)
     - Step table: `| # | Step | Layer | File:line | Notes |`
     - One-line "Trigger / Outcome / See `processing-flows.md`" — no prose narration of the steps
   - **Critical Path to Productivity** — 5–8 files in reading order, table:
     | Order | File | What it teaches |
     |-------|------|------------------|
     Answers "If I only have 30 minutes, what should I read?"
   - **Resilience Assessment** — table per integration:
     | Service | Retry | Timeout | Circuit breaker | Idempotency |
     |---------|-------|---------|-----------------|-------------|
     Cells show mechanism if present, blank if absent. Below the table: one-line overall posture (e.g., "0 of 7 integrations have retry logic") and call out outliers. Don't repeat the per-service detail in prose.
   - **Test Coverage Gaps** — table, sorted by risk:
     | Module | Test file? | Risk | Notes |
     |--------|------------|------|-------|
     Structural coverage only (test file exists), not line-level. One bullet beneath summarizing posture.
   - **Documentation Gaps** — table:
     | Severity | What's missing | Where it should go | Suggested content |
     |----------|----------------|---------------------|--------------------|
     Severities: **Critical** (blocks productivity) · **Medium** (inferable from code) · **Low** (nice-to-have).

5. **Synthesize inconsistencies.md:**

   Compare existing CLAUDE.md and README.md against what the scan actually found. Only write this file if existing docs were found AND at least one UNFIXED item remains after step 7 — if there are no docs, or every inconsistency was auto-fixed, skip writing the file entirely (or delete an existing one). Same format rules as SYSTEM_OVERVIEW.md: tables-first, prose only when needed.

   **Doc-vs-code inconsistencies** — table (UNFIXED items only):
   | Severity | Doc source (file § section) | Claim | Reality (file:line) | Suggested fix | Why unfixed |
   |----------|------------------------------|-------|---------------------|----------------|-------------|

   Severities:
   - **Critical** — actively misleading (wrong commands, incorrect architecture)
   - **Medium** — partially wrong (incomplete flows, outdated patterns)
   - **Low** — minor inaccuracies (stale versions, outdated links)

   **FIXED items are NOT persisted in this file.** Once the fix is applied to CLAUDE.md / README.md / etc., the inconsistency is gone from the codebase — keeping a `[FIXED]` row in inconsistencies.md only adds historical noise the next synthesis run will have to delete and rebuild. Report the FIXED count + a one-line each in the Phase 6 summary (and in the commit message) so the operator can audit the auto-fixes, but do not commit them to a tracked artifact.

   **Config artifact drift** — separate table with the same columns. Cross-reference configuration templates and declarations against their canonical code sources:
   - `.env.template` / `.env.example` vs canonical env var definitions in code (e.g., `env_vars.py`, `config.ts`, `application.properties`) — flag variables present in template but absent in code (dead), and variables in code but missing from template (undocumented)
   - CI pipeline commands vs actual build system commands (e.g., CI runs `npm test` but `package.json` defines `yarn test`)
   - Dockerfile base image versions vs project-level version declarations (e.g., `python:3.11` in Dockerfile vs `3.12` in `pyproject.toml`)

   Skip silently if no templates or CI config exist.

6. **Add cross-references between domain files:**

   After synthesizing, go back and add a `## Cross-references` section at the bottom of each domain file (before `## Scan Limitations`) with links to related content in other domain files. The goal is to make each domain file navigable to its neighbors. Example:
   ```
   ## Cross-references
   - Entity details: `docs/explore-repo/data-model.md` (full entity field listings)
   - Integration clients: `docs/explore-repo/integrations.md` (HTTP client configuration)
   - Workflow orchestration: `docs/explore-repo/processing-flows.md` (step function activities)
   ```
   Only add cross-references where there's a genuine relationship — don't cross-reference everything to everything.

7. **Auto-fix outdated documentation:**

   Using the inconsistencies found in step 5, automatically apply fixes to CLAUDE.md and README.md:
   - For **Critical** inconsistencies: apply the fix directly — these are actively misleading
   - For **Medium** inconsistencies: apply the fix directly — partial accuracy is still harmful
   - For **Low** inconsistencies: apply the fix if it's a simple text replacement; skip if it requires judgment calls
   - Track FIXED vs UNFIXED in working memory; emit FIXED items in the Phase 6 summary and commit message (transient — visible to operator, not persisted). Only UNFIXED items get written to `inconsistencies.md` per step 5.

8. **Update CLAUDE.md files:**

   Based on the synthesized understanding, update documentation for better agent traversal:

   - **Root CLAUDE.md**: Be opinionated. Don't just add new sections — actively improve existing content based on what the scan revealed. If the scan found that a section is misleading, incomplete, or poorly organized, fix it. Add counts, correct inaccuracies, add missing cross-references. Don't clobber the operator's structure, but do make it more accurate and useful.

   - **Subdirectory CLAUDE.md files** — Evaluate candidates and create where valuable:

     **Checklist — you MUST explicitly evaluate each candidate and report which you created vs. skipped (with reasons).**

     Scan the codebase for directories that meet one or more of these criteria:
     - Complex state machines (e.g., order lifecycle, approval flow) where status transitions need explanation
     - Legacy/new system coexistence controlled by feature flags
     - Test infrastructure with non-obvious patterns (e.g., context-sharing constraints, mock centralization)
     - Standalone modules with their own build/run conventions (e.g., migration runners, webhook listeners)
     - Integration layers with many external services and shared frameworks
     - Any directory where an agent entering without context would make common mistakes

     For each candidate, create a focused CLAUDE.md that covers:
     - Architecture diagram (ASCII) showing key components and their relationships
     - State machines or flow descriptions where applicable
     - Configuration properties table
     - Key gotchas and non-obvious patterns
     - Cross-references to related domain files in `docs/explore-repo/`

     **Root CLAUDE.md cross-references:** Add a "Context-Specific Guides" section to root CLAUDE.md with conditional `@` references pointing to subdirectory CLAUDE.md files. This enables agent discovery from root context while keeping token cost low. Format:
     ```
     @path/to/CLAUDE.md - Brief description of what context it provides
     ```

   - Keep CLAUDE.md content concise and navigational — deep detail belongs in the domain files under `docs/explore-repo/`.

9. **Write output files:**
   ```bash
   mkdir -p docs/explore-repo
   ```
   - Write `docs/explore-repo/SYSTEM_OVERVIEW.md`
   - Write `docs/explore-repo/inconsistencies.md` ONLY if at least one UNFIXED item remains; if every inconsistency was auto-fixed (or there were no existing docs), delete an existing file or skip the write. FIXED items live in the Phase 6 summary + commit message, not in the tracked artifact.
   - Update root CLAUDE.md (including auto-fixes from step 7)
   - Update README.md (if auto-fixes from step 7 apply)
   - Create subdirectory CLAUDE.md files as needed
   - Update domain files with cross-references (from step 6)

---

### Phase 6: Validation & Summary

After writing files, validate and then print a summary.

**Validation — verify counts from structured sections:**

Before printing the summary, scan the domain files and SYSTEM_OVERVIEW.md to extract actual counts from their structured sections:
- Count modules listed under `## Modules` in structure.md
- Count endpoints listed in API tables in api-surface.md
- Count entities listed under `## Core Entities` in data-model.md
- Count external services listed under `## External Services` in integrations.md
- Count workflows listed under `## Core Workflows` in processing-flows.md
- Count resilience coverage from the Resilience Assessment table in SYSTEM_OVERVIEW.md (e.g., "3/7 integrations have retries")
- Count untested modules from Test Coverage Gaps in SYSTEM_OVERVIEW.md
- Count documentation gaps listed in SYSTEM_OVERVIEW.md
- Count UNFIXED inconsistencies persisted in inconsistencies.md (doc-vs-code + config artifact drift separately); if file was skipped because everything was fixed, both counts are 0
- Count auto-fixes applied vs. unfixed (from working memory of the synthesis run, not from the persisted file)

Use these actual counts in the summary below — do not estimate or approximate. If the SYSTEM_OVERVIEW.md says "15+ partner adapters" but structure.md lists 21 modules, flag the mismatch and fix it.

**Summary:**

```
Synthesis Complete

Project: [name] ([language/framework])
Scan: <SCAN_REF> @ <SCAN_COMMIT> at [date]


Codebase:
- [N] modules | [N] REST endpoints | [N] entities | [N] external integrations | [N] core workflows

Key Findings:
- [1-2 sentence architectural summary]
- [N] cross-cutting patterns identified
- [N] end-to-end workflows traced

Resilience: [N]/[N] integrations with retries | [N]/[N] with timeouts | [N]/[N] with circuit breakers
Test Coverage: [N] source modules without test files ([list high-risk ones])

Documentation Health:
- [N] critical / [N] medium / [N] low gaps
- [N] doc inconsistencies surfaced ([N] auto-fixed, [N] persisted as UNFIXED in inconsistencies.md)
- [N] config artifact drift items

Auto-fixes applied (transient — not persisted):
- <one-line each FIXED item, file:section → what changed, severity>

Output:
- docs/explore-repo/SYSTEM_OVERVIEW.md
- docs/explore-repo/inconsistencies.md (only if UNFIXED items remain; otherwise omit / delete)
- CLAUDE.md ([NEW — created from scratch] or [updated]). If new, add a 1-2 line synopsis: "Covers: [what sections were included, e.g., architecture, commands, patterns, gotchas, API surface]"
- [list any subdirectory CLAUDE.md files created]
- [list any auto-fixed files: CLAUDE.md, README.md]

Domain docs (for deeper context):
- docs/explore-repo/structure.md
- docs/explore-repo/api-surface.md
- docs/explore-repo/data-model.md
- docs/explore-repo/integrations.md
- docs/explore-repo/processing-flows.md
- docs/explore-repo/config-ops.md
- docs/explore-repo/testing.md
```

---

## Important Notes

- **NEVER** include contents of sensitive files (.env, credentials, private keys, secrets, API keys) in any output. Note their existence if relevant, but never their contents.
- **Scan and synthesis are always separate invocations.** This ensures synthesis gets a clean context window with full budget for cross-referencing.
- **Domain files are first-class documentation.** They're useful standalone — a developer can read `data-model.md` directly without needing the overview.
- **Domain files are git-tracked.** They persist across sessions and inform future scans via staleness checks.
- The scan metadata commit hash enables staleness detection. On future runs, only stale or missing domains get re-scanned.
- The skill blocks **once** in Phase 0 to confirm scan target (default: latest upstream). After that, all ambiguities and unresolved questions go in the output, not as blocking questions — the rest of the skill runs autonomously.
- When suggesting documentation locations, prefer conditional `@` references in CLAUDE.md over dumping everything inline — optimize for token efficiency.
- Graceful degradation: if an agent fails, note the gap. The missing file will be picked up on the next scan run.
