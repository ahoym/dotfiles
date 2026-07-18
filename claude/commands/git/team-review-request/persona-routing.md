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

**Repo-level domain ≠ diff-level domain.** A financial-services repo doesn't make every diff a fintech-persona match — check whether the changed code touches the domain's core invariants (money movement, balance, double-entry) or is an adjacent read-only/browse surface. A search/list endpoint over existing records doesn't warrant `java-fintech`/`financial-reviewer` just because the repo is a ledger service; route by what the code does, not what the repo is.

## Matching Heuristic

For each persona file, issue a parallel `Read(file, limit=10)` (all personas in one tool block — not `bash for-loop + head`, which prompts on quoted echo headers). Ten lines covers name + description + `## Domain priorities` heading. Match derived domain terms against:
1. The persona name itself (e.g., `java-fintech` matches "java" and "fintech")
2. Keywords in the description line
3. Terms in the `## Domain priorities` list

Score each persona by the number of matching terms. Select the top personas up to the max constraint.

## Constraints

- **Min 1** reviewer always. If no domain persona matches, use `reviewer` alone.
- **Utility-based cap, not a fixed number.** Each additional reviewer must bring a distinct lens not covered by the others. Ask "would this persona see something the current set won't?" — if yes, include it regardless of count. If no, stop. For most PRs this lands at 2-3; for cross-cutting changes (service + deployment + API contract) it may be 4-5.
- **Diminishing returns are real but not a gate.** Token cost scales linearly with reviewer count; review quality does not. The 4th reviewer is only worth it if their lens genuinely adds coverage. Don't pad the team for thoroughness theater.
- When multiple personas tie on score, prefer more specialized over more general (e.g., `java-fintech` over `java-backend` when both match).
- **Stack coverage requirement.** If domain term derivation produced any language/framework signal (java, react, typescript, xrpl, frontend, backend, kotlin, python, go), the selected team MUST include ≥1 language/framework-specific persona (`java-*`, `react-*`, `typescript-*`, `xrpl-*`, or domain experts like `fintech-ledger-engineer`). If the heuristic top-N misses one, force-include the highest-scoring stack persona — even if it pushes the cap by 1. Stack reviewers catch idiom-level gotchas (CGLIB-final, `as` casts, RxJava backpressure, JPA flush ordering) that stack-agnostic lens reviewers don't see. Lens-only teams are valid only when no stack signal is present (e.g., pure docs or config PR).

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

Precedence over heuristic matching. Forced personas count toward the utility-based cap; heuristic fills any remaining capacity, subject to the same "distinct lens" test.

### Integration/Adapter → architecture-reviewer

**Match:** `**/adapter*/**`, `**/integration/**`, filenames containing `Adapter|Bridge|Gateway|Connector|Client` (case-insensitive), or gRPC/proto files.

**Force:** `architecture-reviewer` — catches coupling, contract assumptions, constructor design, and forward-compatibility that domain personas miss in plumbing-heavy code.

### Deployment dependency → java-devops or platform-engineer

**Match:** MR description contains "deployment dependency", "requires corresponding deployment", "deploy before/after", or changed files include `*Properties*`, `*Config*`, `application*.yml`, `application*.properties`, Vault/secrets references.

**Force:** `java-devops` (or `platform-engineer` if no Java context). Catches deploy ordering risks, config-driven silent failures, missing startup validation, and Vault path correctness that domain personas miss. These concerns are invisible at the code level — a config-dependent code change that deploys before its config silently degrades.

### External service calls → correctness defensive-coding directive

**Match:** Changed classes call gRPC stubs, HTTP clients, or SDK wrappers AND `correctness-reviewer` is selected.

**Inject into correctness prompt:** "Focus on boundary validation (UUID parsing, enum mapping), null guards on SDK returns, exception cause-chain nullability, and silent pagination truncation."

### Non-trivial size or thin-wrapper density → architecture-reviewer

**Match:** PR adds 500+ new lines OR introduces 5+ new internal helper functions OR module docstrings exceeding ~30 lines.

**Force:** `architecture-reviewer` — adds the readability-first lens. The defect-oriented personas (financial, correctness, claude-config) don't flag verbose code, near-duplicate helpers, or over-documented internals — those pass defect review and fail architecture review. If the cap excludes architecture-reviewer, recommend a follow-up `/simplify` pass.

---

## Merge Algorithm

Used by the orchestrator at step 10 to combine findings from all reviewer subagents.

### Phase 1: Index

For each finding from each persona, create a composite key: `(file, line_range, category)`. Two findings have overlapping line ranges if they share any lines OR are within 3 lines of each other in the same file.

### Phase 2: Group

Group findings that share a composite key. These are "about the same thing."

**Cross-file semantic dedup.** The Phase 1 composite key only catches same-file, line-adjacent duplicates. When personas anchor the same root cause on different files or non-adjacent lines (e.g., one flags a query's cost at its definition, another flags the same cost at the repository interface it's exposed through), matching `category` plus clearly-overlapping `reasoning`/`summary` text is an Agreement candidate too — don't let the mechanical key miss what the team-lead lens would catch by eye.

### Phase 3: Classify

- **Agreement** — 2+ personas, same severity tier (within one level), compatible recommendations (same direction, possibly different specifics). Merge into one finding. Tag with all persona names: `[persona-1, persona-2]`. Use the most detailed reasoning. Produce one inline comment with combined attribution.

- **Unique** — Only 1 persona flagged this. Pass through with single-persona attribution: `[persona-1]`.

- **Disagreement** — 2+ personas, AND one of: (a) severity differs by 2+ levels AND recommendations diverge in direction, (b) recommendations are contradictory (one says change, one says keep), (c) one persona's positive signal contradicts another's finding. Flag as `DISSENT_CANDIDATE` for deliberation (step 11).

  **Not a disagreement:** Both personas agree on the problem but suggest different fixes. That's an agreement with complementary recommendations — merge and include both suggestions.

  **Not a disagreement (severity-only):** Substance and recommendation align, only severity tier differs (e.g., LOW vs HIGH on the same drift-class concern with the same proposed fix). Synthesize as the median tier with a one-line attribution note in the finding body (e.g., "Severity range: java-fintech LOW, architecture-reviewer HIGH — team-lead synthesis MEDIUM"). Do NOT trigger deliberation — `SendMessage` rounds on calibration-only deltas waste tokens because neither subagent has new information that would flip their tier.

  **Not a disagreement (reconcilable positive-vs-finding):** When persona A lists a pattern as a positive signal (e.g., "loader correctly mirrors sibling — payment-routing safety consistent") and persona B flags a related concern at HIGH (e.g., "the mirror creates silent data loss when external system evolves faster than the enum — observability is grep-only"), check if both can coexist: A endorses the pattern's *existence*, B criticizes a specific *aspect* (observability, test coverage, policy explicitness). If both perspectives describe the same surface honestly, synthesize the finding at median severity with attribution noting both — do NOT trigger deliberation. Deliberation is for substantively conflicting recommendations (keep the pattern vs remove it). Aspect-criticism + pattern-endorsement is reconcilable: post B's concern at the median tier, retain A's positive in the summary.

### Phase 4: Deduplicate inline comments

When multiple personas flagged the same line range, produce ONE inline comment with combined attribution and the merged reasoning. Never post duplicate comments on the same line.

### Phase 5: Dedupe across authors (independent reviewers on the same MR)

Before posting, check existing inline notes from non–Team-Reviewer authors (no `Role: Team-Reviewer` footnote) for findings that overlap the team's. When an independent reviewer has already covered the same concern:

- **Drop** if their finding fully covers the team's angle — adding a parallel post is noise.
- **Reference, don't duplicate** if the team's finding lands at an adjacent layer (e.g., DTO vs. SPI record) or a different angle (correctness vs. consistency). Post the new finding with `(note <id>)` or markdown link to theirs and frame it as parallel — "same drift class @reviewer flagged on `<file>` …" — so resolving theirs naturally lands the team's at the same time.

**"Resolved" ≠ fixed.** A thread marked resolved doesn't mean the flagged code changed — bots can bulk-resolve their own previously-opened threads on a later pass, independent of whether the line was touched. Before dropping a finding as "already covered," verify the current file content still matches the old finding, not just the thread's resolved status. If the same issue has been flagged multiple times and is still unfixed, still drop it from the posted review (a third post is still noise) — but name the repeat-and-still-broken pattern in the conversational summary to the operator, since it signals the author is missing or ignoring prior feedback.

Cross-author dedup applies in both first-review and re-review modes. In re-review, also skip reacting to independent-reviewer threads — reactions are reserved for the team's own resolved/acknowledged threads.
