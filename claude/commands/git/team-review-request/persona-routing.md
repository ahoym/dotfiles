# Persona Routing

Reference file for the orchestrator's persona selection (step 5) and finding merge (step 10).

## Domain Term Derivation

Derive domain keywords from `CHANGED_FILES` paths using judgment — consider file extensions, directory names, content signals, and naming conventions. The goal is to produce terms that match against persona descriptions and learnings filenames.

Examples of the kind of reasoning expected (not an exhaustive table):
- `src/ledger/balance.java` → ledger, fintech, java, backend
- `src/components/Dashboard.tsx` → frontend, react, typescript
- `.github/workflows/deploy.yml` → ci-cd, devops
- `main.sh`, `.bash_profile` → shell, bash, scripting, devops
- `.claude/learnings/foo.md` → claude-config
- `Dockerfile`, `terraform/main.tf` → infrastructure, devops

When a file suggests multiple domains, include all of them. The more terms a persona matches, the stronger the signal.

## Matching Heuristic

For each persona file, read the first 5-10 lines (name + description + `## Domain priorities` heading). Match derived domain terms against:
1. The persona name itself (e.g., `java-fintech` matches "java" and "fintech")
2. Keywords in the description line
3. Terms in the `## Domain priorities` list

Score each persona by the number of matching terms. Select the top personas up to the max constraint.

## Constraints

- **Min 1** reviewer always. If no domain persona matches, use `reviewer` alone.
- **Utility-based cap, not a fixed number.** Each additional reviewer must bring a distinct lens not covered by the others. Ask "would this persona see something the current set won't?" — if yes, include it regardless of count. If no, stop. For most PRs this lands at 2-3; for cross-cutting changes (service + deployment + API contract) it may be 4-5.
- **Diminishing returns are real but not a gate.** Token cost scales linearly with reviewer count; review quality does not. The 4th reviewer is only worth it if their lens genuinely adds coverage. Don't pad the team for thoroughness theater.
- When multiple personas tie on score, prefer more specialized over more general (e.g., `java-fintech` over `java-backend` when both match).

## Exclusions

Skip personas that are not domain reviewers:
- `claude-config-author` — authoring lens, not review
- `claude-config-expert` — knowledge base, not review lens
- `team-lead` — coordination persona, used by the orchestrator directly (not a subagent)
- `reviewer` — base review persona, used by the orchestrator directly (not a subagent)

**Exception:** If `CHANGED_FILES` include `.claude/` paths, include `claude-config-reviewer`.

## Extends Chain Awareness

Many domain personas extend a base (e.g., `java-fintech` extends `fintech-ledger-engineer, java-backend`). When front-loading persona content (step 6), the orchestrator reads the full extends chain. This means selecting `java-fintech` implicitly covers the `java-backend` and `fintech-ledger-engineer` domains — don't select both a child and its parent.

## Explicit Routing Rules

Precedence over heuristic matching. Forced personas count toward the max-3 cap; heuristic fills remaining slots.

### Integration/Adapter → architecture-reviewer

**Match:** `**/adapter*/**`, `**/integration/**`, filenames containing `Adapter|Bridge|Gateway|Connector|Client` (case-insensitive), or gRPC/proto files.

**Force:** `architecture-reviewer` — catches coupling, contract assumptions, constructor design, and forward-compatibility that domain personas miss in plumbing-heavy code.

### Deployment dependency → java-devops or platform-engineer

**Match:** MR description contains "deployment dependency", "requires corresponding deployment", "deploy before/after", or changed files include `*Properties*`, `*Config*`, `application*.yml`, `application*.properties`, Vault/secrets references.

**Force:** `java-devops` (or `platform-engineer` if no Java context). Catches deploy ordering risks, config-driven silent failures, missing startup validation, and Vault path correctness that domain personas miss. These concerns are invisible at the code level — a config-dependent code change that deploys before its config silently degrades.

### External service calls → correctness defensive-coding directive

**Match:** Changed classes call gRPC stubs, HTTP clients, or SDK wrappers AND `correctness-reviewer` is selected.

**Inject into correctness prompt:** "Focus on boundary validation (UUID parsing, enum mapping), null guards on SDK returns, exception cause-chain nullability, and silent pagination truncation."

---

## Merge Algorithm

Used by the orchestrator at step 10 to combine findings from all reviewer subagents.

### Phase 1: Index

For each finding from each persona, create a composite key: `(file, line_range, category)`. Two findings have overlapping line ranges if they share any lines OR are within 3 lines of each other in the same file.

### Phase 2: Group

Group findings that share a composite key. These are "about the same thing."

### Phase 3: Classify

- **Agreement** — 2+ personas, same severity tier (within one level), compatible recommendations (same direction, possibly different specifics). Merge into one finding. Tag with all persona names: `[persona-1, persona-2]`. Use the most detailed reasoning. Produce one inline comment with combined attribution.

- **Unique** — Only 1 persona flagged this. Pass through with single-persona attribution: `[persona-1]`.

- **Disagreement** — 2+ personas, AND one of: (a) severity differs by 2+ levels, (b) recommendations are contradictory (one says change, one says keep), (c) one persona's positive signal contradicts another's finding. Flag as `DISSENT_CANDIDATE` for deliberation (step 11).

  **Not a disagreement:** Both personas agree on the problem but suggest different fixes. That's an agreement with complementary recommendations — merge and include both suggestions.

### Phase 4: Deduplicate inline comments

When multiple personas flagged the same line range, produce ONE inline comment with combined attribution and the merged reasoning. Never post duplicate comments on the same line.
