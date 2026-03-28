# Persona Routing

Reference file for the orchestrator's persona selection (step 5) and finding merge (step 10).

## Domain Term Derivation

Derive domain keywords from `CHANGED_FILES` paths. Use the most specific match:

| Path pattern | Domain terms |
|---|---|
| `src/ledger/`, `**/accounting/`, `**/balance/` | ledger, fintech, accounting |
| `src/api/`, `**/controller/`, `**/service/` | backend, api |
| `src/components/`, `src/pages/`, `src/app/`, `**/*.tsx`, `**/*.jsx` | frontend, react |
| `.github/workflows/`, `.gitlab-ci*`, `**/ci/`, `**/deploy/` | ci-cd, devops |
| `**/security/`, `**/auth/`, `**/oauth/` | security, infosec |
| `.claude/`, `**/personas/`, `**/learnings/`, `**/skills/` | claude-config |
| `**/xrpl/`, `**/ripple/` | xrpl |
| `tests/`, `**/*test*`, `**/*spec*` | testing |
| `*.java`, `**/spring/`, `pom.xml`, `build.gradle*` | java |
| `*.ts`, `*.tsx`, `tsconfig*`, `package.json` | typescript |
| `*.py`, `pyproject.toml`, `requirements*.txt` | python |
| `infra/`, `terraform/`, `*.tf`, `docker*`, `k8s/` | infrastructure, devops |

When a file matches multiple patterns, include all derived terms. The more terms a persona matches, the stronger the signal.

## Matching Heuristic

For each persona file, read the first 5-10 lines (name + description + `## Domain priorities` heading). Match derived domain terms against:
1. The persona name itself (e.g., `java-fintech` matches "java" and "fintech")
2. Keywords in the description line
3. Terms in the `## Domain priorities` list

Score each persona by the number of matching terms. Select the top personas up to the max constraint.

## Constraints

- **Min 1** reviewer always. If no domain persona matches, use `reviewer` alone.
- **Max 3** reviewers per PR. Beyond 3, diminishing returns outweigh the token cost.
- When multiple personas tie on score, prefer more specialized over more general (e.g., `java-fintech` over `java-backend` when both match).

## Exclusions

Skip personas that are not review-appropriate:
- `claude-config-author` — authoring lens, not review
- `claude-config-expert` — knowledge base, not review lens

**Exception:** If `CHANGED_FILES` include `.claude/` paths, include `claude-config-reviewer`.

## Extends Chain Awareness

Many domain personas extend a base (e.g., `java-fintech` extends `fintech-ledger-engineer, java-backend`). When front-loading persona content (step 6), the orchestrator reads the full extends chain. This means selecting `java-fintech` implicitly covers the `java-backend` and `fintech-ledger-engineer` domains — don't select both a child and its parent.

## Future Hook

When explicit routing rules are added below, they take precedence over heuristic matching. Until then, the heuristic above is the sole selection mechanism.

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
