---
description: Deep-scan a repository to understand its structure, functionality, and documentation gaps
---

# Explore Repository

Deep-scan a repository using parallel exploration agents to produce comprehensive documentation, identify documentation gaps, and flag inconsistencies between code and existing docs.

Operates in two modes based on file state — **scan mode** writes domain-specific docs, **synthesis mode** reads them to produce cross-domain outputs. Each invocation runs one mode only.

## Usage

- `/explore-repo` - Auto-detect mode based on file state
- `/explore-repo <focus-areas>` - Scan specific dimensions only (comma-separated: structure, api, data-model, integrations, flows, config, testing)

## Reference Files

- @agent-prompts.md - Detailed prompts and mandates for each exploration agent

## Instructions

### Phase 1: Mode Detection

Determine what work needs to be done by checking existing output files.

1. **Check for domain scan files and synthesis files** (run in parallel):
   - Glob for `docs/learnings/structure.md`
   - Glob for `docs/learnings/api-surface.md`
   - Glob for `docs/learnings/data-model.md`
   - Glob for `docs/learnings/integrations.md`
   - Glob for `docs/learnings/processing-flows.md`
   - Glob for `docs/learnings/config-ops.md`
   - Glob for `docs/learnings/testing.md`
   - Glob for `docs/learnings/SYSTEM_OVERVIEW.md`
   - Glob for `docs/learnings/inconsistencies.md`

2. **Determine which files exist and check staleness:**
   - Run `git rev-parse --short HEAD` and `git branch --show-current`
   - For each existing scan file, read the first 10 lines and extract the `commit` from the scan metadata header
   - A scan file is **stale** if its commit hash differs from current HEAD
   - A scan file is **missing** if it doesn't exist at all

3. **Smart staleness — identify affected domains:**
   - If any scan files are stale, run `git diff --stat <stale-commit>..HEAD` to see which files changed
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

   - Only re-scan domains whose files were actually affected by the changes
   - If the diff is too large (100+ files changed) or the mapping is ambiguous, fall back to re-scanning all stale domains
   - **Important:** If `CLAUDE.md` or `README.md` changed, mark ALL domains for re-scan (project-level docs affect all agents' context)

4. **Clean up stale synthesis files:**
   - If entering **scan mode** (any domain files missing or stale), delete any existing `SYSTEM_OVERVIEW.md` and `inconsistencies.md` — they were produced from older scan data and will be regenerated in a subsequent synthesis run
   - Announce what was cleaned up (e.g., "Deleted stale SYSTEM_OVERVIEW.md and inconsistencies.md from previous scan")

5. **Determine mode:**

   | Condition | Mode | Action |
   |-----------|------|--------|
   | Any scan files missing (not all 7 present) | **Scan** | Scan missing domains |
   | All 7 present, stale (commit differs from HEAD) | **Scan** | Re-scan only domains affected by changes (from step 3) |
   | All 7 present, current, no SYSTEM_OVERVIEW.md | **Synthesize** | Produce synthesized outputs |
   | All 7 present, current, SYSTEM_OVERVIEW.md exists but stale | **Synthesize** | Re-synthesize |
   | All 7 present, current, SYSTEM_OVERVIEW.md current | **Up-to-date** | Nothing to do |

   **`$ARGUMENTS` override:** If focus areas are specified, always scan those domains regardless of file state.

6. **Announce mode:**
   - Print which mode was detected and why
   - If scan mode: list which domains will be scanned and why (missing vs. stale vs. affected by changes)
   - If smart staleness narrowed the re-scan scope, mention which domains were skipped and why
   - If stale synthesis files were cleaned up, mention it
   - If up-to-date: inform the user and stop

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
2. Construct the prompt by injecting PROJECT_CONTEXT and file metadata (commit hash, branch, date) where indicated
3. Launch via Task tool

**The 7 agents:**

| # | Agent | Domain | Output File |
|---|-------|--------|-------------|
| 1 | Structure | Module layout, build system, dependencies, CI/CD | `docs/learnings/structure.md` |
| 2 | API Surface | REST/gRPC/CLI endpoints, request/response shapes | `docs/learnings/api-surface.md` |
| 3 | Data Model | Entities, schema, relationships, migrations, state machines | `docs/learnings/data-model.md` |
| 4 | Integrations | External services, clients, authentication, error handling | `docs/learnings/integrations.md` |
| 5 | Processing Flows | Core business logic, workflows, scheduled tasks, events | `docs/learnings/processing-flows.md` |
| 6 | Config & Ops | Configuration, profiles, monitoring, secrets, deployment | `docs/learnings/config-ops.md` |
| 7 | Testing | Test structure, patterns, utilities, how to run tests | `docs/learnings/testing.md` |

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
- The `commit` field matches the current HEAD
- If any file has a malformed header, fix it in place

---

### Phase 4: Scan Summary (Scan Mode Only)

After all agents complete, print a brief summary:

```
Scan Complete

Domains scanned: [list]
Domains skipped: [list, if any — already current]
Domains failed: [list, if any]

Output files:
- docs/learnings/structure.md
- docs/learnings/api-surface.md
- ...

Run /explore-repo again to synthesize into SYSTEM_OVERVIEW.md
```

**Stop here.** Do not proceed to synthesis in the same invocation.

---

### Phase 5: Synthesis (Synthesis Mode Only)

This phase runs in a fresh invocation with a clean context. Read domain files from disk — do NOT rely on any cached or in-memory results.

1. **Read all 7 domain files** from `docs/learnings/`:
   - `structure.md`, `api-surface.md`, `data-model.md`, `integrations.md`, `processing-flows.md`, `config-ops.md`, `testing.md`

2. **Read existing documentation** for comparison:
   - Read CLAUDE.md at the repo root (if it exists)
   - Read README.md at the repo root (if it exists)

3. **Synthesize SYSTEM_OVERVIEW.md:**

   Write a **cross-domain overview** — this is the unique value that individual domain files cannot provide on their own. Do NOT simply concatenate the domain files.

   Structure:
   - **Scan metadata** as HTML comment at the top (commit, branch, date, dimensions)
   - **Project Summary** (2-3 paragraphs): What the system does, key architectural decisions, technology choices. Synthesize insights from ALL domain files.
   - **Architecture Overview**: How the major components connect. Cross-reference structure, data model, integrations, and processing flows.
   - **Module Dependency Graph**: ASCII art showing how the major modules/packages depend on each other. Use box-drawing characters. Show the data flow direction. Example format:
     ```
     ┌─────────────┐     ┌──────────────┐
     │  API Layer   │────▶│ Service Layer │
     └─────────────┘     └──────┬───────┘
                                │
                    ┌───────────┼───────────┐
                    ▼           ▼           ▼
             ┌──────────┐ ┌─────────┐ ┌──────────┐
             │ Adapters  │ │   DB    │ │  Events  │
             └──────────┘ └─────────┘ └──────────┘
     ```
   - **Cross-Cutting Patterns**: Shared patterns that span multiple domains — authentication, error handling, naming conventions, transaction management, retry strategies.
   - **Key Workflows End-to-End**: Trace the most important business flows through the full stack (API → service → data → integrations → events). Reference specific domain files for deeper detail.
   - **Critical Path to Productivity**: A recommended reading order for a developer new to the codebase. List 5-8 files/docs in priority order, with a one-line explanation of what each teaches you. Start with the highest-leverage context (e.g., "1. CLAUDE.md — project overview and essential commands") and end with deep-dives. This section answers: "If I only have 30 minutes, what should I read?"
   - **Documentation Gaps**: What's missing from existing docs, categorized by severity:
     - **Critical** — Missing documentation that blocks productivity
     - **Medium** — Missing but inferable from code
     - **Low** — Nice-to-have improvements
   - For each gap: what's missing, where it should be documented, suggested content

4. **Synthesize inconsistencies.md:**

   Compare existing CLAUDE.md and README.md against what the scan actually found. Only write this file if existing docs were found — if there are no docs, skip it.

   - Find specific discrepancies: the doc says X but the code does Y
   - Categorize by severity:
     - **Critical** — Actively misleading (wrong commands, incorrect architecture)
     - **Medium** — Partially wrong (incomplete flows, outdated patterns)
     - **Low** — Minor inaccuracies (stale versions, outdated links)
   - For each inconsistency, include:
     - **Doc source:** file path and section name
     - **What it claims:** the incorrect content
     - **What the code actually does:** the correct behavior with evidence (file path, line)
     - **Suggested fix:** the exact replacement text or edit needed to correct the documentation

5. **Add cross-references between domain files:**

   After synthesizing, go back and add a `## Cross-references` section at the bottom of each domain file (before `## Scan Limitations`) with links to related content in other domain files. The goal is to make each domain file navigable to its neighbors. Example:
   ```
   ## Cross-references
   - Entity details: `docs/learnings/data-model.md` (full entity field listings)
   - Integration clients: `docs/learnings/integrations.md` (HTTP client configuration)
   - Workflow orchestration: `docs/learnings/processing-flows.md` (step function activities)
   ```
   Only add cross-references where there's a genuine relationship — don't cross-reference everything to everything.

6. **Auto-fix outdated documentation:**

   Using the inconsistencies found in step 4, automatically apply fixes to CLAUDE.md and README.md:
   - For **Critical** inconsistencies: apply the fix directly — these are actively misleading
   - For **Medium** inconsistencies: apply the fix directly — partial accuracy is still harmful
   - For **Low** inconsistencies: apply the fix if it's a simple text replacement; skip if it requires judgment calls
   - Record what was fixed in the inconsistencies.md file (mark each as `[FIXED]` or `[UNFIXED]` with reason)

7. **Update CLAUDE.md files:**

   Based on the synthesized understanding, update documentation for better agent traversal:

   - **Root CLAUDE.md**: Be opinionated. Don't just add new sections — actively improve existing content based on what the scan revealed. If the scan found that a section is misleading, incomplete, or poorly organized, fix it. Add counts, correct inaccuracies, add missing cross-references. Don't clobber the user's structure, but do make it more accurate and useful.

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
     - Cross-references to related domain files in `docs/learnings/`

     **Root CLAUDE.md cross-references:** Add a "Context-Specific Guides" section to root CLAUDE.md with conditional `@` references pointing to subdirectory CLAUDE.md files. This enables agent discovery from root context while keeping token cost low. Format:
     ```
     @path/to/CLAUDE.md - Brief description of what context it provides
     ```

   - Keep CLAUDE.md content concise and navigational — deep detail belongs in the domain files under `docs/learnings/`.

8. **Write output files:**
   ```bash
   mkdir -p docs/learnings
   ```
   - Write `docs/learnings/SYSTEM_OVERVIEW.md`
   - Write `docs/learnings/inconsistencies.md` (skip if no existing docs)
   - Update root CLAUDE.md (including auto-fixes from step 6)
   - Update README.md (if auto-fixes from step 6 apply)
   - Create subdirectory CLAUDE.md files as needed
   - Update domain files with cross-references (from step 5)

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
- Count documentation gaps listed in SYSTEM_OVERVIEW.md
- Count inconsistencies listed in inconsistencies.md
- Count auto-fixes applied vs. unfixed

Use these actual counts in the summary below — do not estimate or approximate. If the SYSTEM_OVERVIEW.md says "15+ partner adapters" but structure.md lists 21 modules, flag the mismatch and fix it.

**Summary:**

```
Synthesis Complete

Project: [name] ([language/framework])
Scan: [commit hash] on [branch] at [date]

Codebase:
- [N] modules | [N] REST endpoints | [N] entities | [N] external integrations | [N] core workflows

Key Findings:
- [1-2 sentence architectural summary]
- [N] cross-cutting patterns identified
- [N] end-to-end workflows traced

Documentation Health:
- [N] critical / [N] medium / [N] low gaps
- [N] inconsistencies ([N] auto-fixed, [N] unfixed)

Output:
- docs/learnings/SYSTEM_OVERVIEW.md
- docs/learnings/inconsistencies.md
- CLAUDE.md (updated)
- [list any subdirectory CLAUDE.md files created]
- [list any auto-fixed files: CLAUDE.md, README.md]

Domain docs (for deeper context):
- docs/learnings/structure.md
- docs/learnings/api-surface.md
- docs/learnings/data-model.md
- docs/learnings/integrations.md
- docs/learnings/processing-flows.md
- docs/learnings/config-ops.md
- docs/learnings/testing.md
```

---

## Important Notes

- **NEVER** include contents of sensitive files (.env, credentials, private keys, secrets, API keys) in any output. Note their existence if relevant, but never their contents.
- **Scan and synthesis are always separate invocations.** This ensures synthesis gets a clean context window with full budget for cross-referencing.
- **Domain files are first-class documentation.** They're useful standalone — a developer can read `data-model.md` directly without needing the overview.
- **Domain files are git-tracked.** They persist across sessions and inform future scans via staleness checks.
- The scan metadata commit hash enables staleness detection. On future runs, only stale or missing domains get re-scanned.
- All ambiguities and unresolved questions go in the output, not as blocking questions during execution. The skill runs fully autonomously.
- When suggesting documentation locations, prefer conditional `@` references in CLAUDE.md over dumping everything inline — optimize for token efficiency.
- Graceful degradation: if an agent fails, note the gap. The missing file will be picked up on the next scan run.
