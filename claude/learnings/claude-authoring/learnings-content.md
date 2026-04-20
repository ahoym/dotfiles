Craft patterns for writing learnings content — genericization, scope classification, header format, persona boundary tests, and provenance hygiene.
- **Keywords:** genericize, project-specific, scope classification, persona-learning boundary, provenance, header format, standardized header, sniff window
- **Related:** none

---

## Genericize Project-Specific Content in Global Learnings

Global learnings (in `~/.claude/learnings/`) should use domain-neutral examples. When curating, replace project-specific references with portable equivalents.

**What to replace:**

| Project-Specific | Generic Replacement |
|---|---|
| `acme_client`, `api_client` | `api_client`, `service_client` |
| `AssetMovementResult`, `PaymentResult` | `ResponseModel`, `OperationResult` |
| `TypeMatcher(str)` (custom test helper) | "custom matcher objects" (generic framing) |
| `customerReference` (domain field) | `referenceId`, `trackingId` |
| Project-specific class/method names in examples | Domain-neutral names that illustrate the same concept |

**What to keep:**
- Language/framework names (`Pydantic`, `FastAPI`, `Spring Boot`)
- Standard library types and patterns
- The underlying insight — only the example wrapping changes

**When to apply:** During `/learnings:curate`, check each "Standalone reference" pattern for project-specific content. If the examples use names from a specific codebase, genericize them while preserving the pattern's teaching value.

**Exception — concrete examples that outweigh genericization:** When a project-specific example IS the teaching material — making a gotcha vivid and memorable in a way a generic replacement can't — keep it. The genericization rule exists to prevent learnings from being useless outside the project. If the pattern is already useful regardless of the specific example (the lesson is universal even though the illustration is domain-specific), the example's concreteness wins.

**Provenance vs structural content:** Distinguish between provenance notes ("discovered while building X") and structural examples (a domain-specific regex that makes a collision visible). Provenance is always safe to remove — it adds no teaching value. Structural examples need case-by-case judgment: would a generic replacement teach the same lesson as effectively?

**Create project-specific instances when genericizing.** When removing domain-specific content from a global learning, check if the originating project has a learnings directory (e.g., `docs/claude-learnings/`). If so, add the project-specific instance there. The global file teaches the generic pattern; the project file preserves the concrete gotcha where it's most useful.

## Persona-Learning Boundary Test

When curating, use the **"what mistake could I still make?"** test to evaluate whether a learning adds value beyond its persona rule. Personas carry one-liner gotchas; learnings carry recipes, code examples, and deeper context. If a persona rule fully prevents the mistake, the learning is redundant. If the learning prevents a mistake the persona rule alone wouldn't catch, it earns its keep.

## Scope Classification Needs Language-Awareness

Extraction subagents classify learnings as "general" when the underlying principle feels universal, even when the examples and syntax are language-specific. Python patterns like `# noqa` suppression, `__all__` exports, and sentinel `None` defaults were classified as general scope because the concepts (fix root causes, define public APIs) are universal — but the actual content is only useful in Python contexts. Writers should cross-check: if a learning references language-specific syntax, tooling, or idioms, route it to the language-specific file regardless of how universal the principle feels.

## Grep Before Creating New Files

When creating a new learnings file, first grep `~/.claude/learnings/` for existing files matching the domain. Without this check, near-duplicate files accumulate (e.g., `parallel-planning.md` and `parallel-plans.md` about the same topic). Similarly, check if the insight already exists in a more authoritative location before creating a domain-specific copy — platform behavior patterns compounded from a parallel-plan session may already be covered in `claude-code.md`.

Additionally, when creating a new learnings file, check personas in `~/.claude/commands/set-persona/` for `Cross-Refs` sections that cover the same domain — a new file won't be discoverable through persona activation unless it's wired in. Suggest adding a reference link to matching personas.

## Avoid Naming Learnings After Repos or Ambient Context Terms

Filenames are the search protocol's primary index. If a file is named after a repo (e.g., `dotfiles-workflow.md` in the dotfiles repo), the session-start gate matches it on every session — branch names, CWD paths, and git status all contain the repo name. The file gets loaded regardless of relevance, wasting context budget.

**Fix:** Name learnings after the *pattern*, not the *source*. `worktree-pr-hygiene.md` > `dotfiles-workflow.md`. If the content is repo-specific and actionable, it belongs in that repo's `CLAUDE.md` instead.

## Deep Coverage Analysis for Deleted Content

When consolidation removes sections, verify concepts have new homes — not just that keywords appear elsewhere. Check both git history (original content) and current corpus (where concepts landed). Categorize each deleted section as: COVERED (concepts exist elsewhere), PARTIALLY COVERED (some missing), or GAP (unique content dropped). For partial coverage, add the missing pieces to existing files rather than re-creating the deleted section.

## Provenance Tracking in Retros

When reviewing learnings load effectiveness (e.g., in `/session-retro`), tag each loaded file with its provenance: hard gate (session-start, plan-mode, implementation-start), soft gate (confidence-level, friction-triggered, keyword-triggered), persona proactive, skill reference, operator-prompted, self-directed, or cross-ref. This surfaces whether the search protocol is doing its job or whether useful files are only reached through persona coverage or manual reads. Missed soft gates are the highest-value finding — they reveal where the protocol should fire but doesn't.

## Standardized Header Format for Learnings Files

Every learnings file must use this header format for structured sniffing (`Read(file_path, limit=3)`):

```markdown
Description sentence (one or two sentences, what domain this covers).
- **Keywords:** searchable terms from content, not just title restated
- **Related:** sibling-file.md, other-file.md

---
```

No `# Title` — the filename serves as the title. This keeps all three signal lines within `limit=3`.

**Line roles in the sniff window:**
- Line 1: description — relevance check against derived search terms
- Line 2: keywords — term matching (technology names, pattern names, specific concepts)
- Line 3: related — graph edges for cross-ref traversal without full file load

**Guidelines:**
- Keywords should include terms a searcher would use that aren't obvious from the filename (e.g., `resilience-patterns.md` should include "circuit breaker", "retry")
- Related filenames come from the `## Cross-Refs` footer (just filenames, not full paths)
- Files with no cross-refs use `**Related:** none`
- The `---` divider separates the header from content — purely for readability
- When delegating learnings creation to subagents, specify the no-title format in the prompt — agents default to `# Title` headers from training, which shifts line positions and breaks `limit=3` sniffing

**Why it works:** The sniff step (read 5 lines to check relevance) exists because filenames alone are weak signals. Descriptions make sniffing unnecessary. The pipeline was compensating for missing structure.


## File Naming Drift: Name for the Domain, Not the Tool

When a file accumulates content over time, its name can drift from its actual scope. `gitlab-ci-cd.md` accumulated GitLab API and `glab` CLI content because `glab` was the common thread — but MR endpoint gotchas and inline comment GraphQL requirements have nothing to do with CI/CD pipelines. Someone working on review automation wouldn't look in a CI/CD file.

**Detection:** When adding content to an existing file, ask: "would someone searching for this topic expect to find it under this filename?" If the answer is no, the file needs splitting or the content needs a different home.

**Prevention:** Name files after the *domain boundary*, not the *tool* or *entry point*. `gitlab-api-and-cli.md` (API surface + CLI tool) vs `gitlab-ci-cd.md` (pipeline configuration) — clear domains that don't drift into each other.

## Check Overlap Before Creating New Learnings Files

When extracting knowledge from skills into learnings, content often splits across multiple existing homes rather than forming a new standalone file. Before creating a new file, check existing learnings for partial coverage — the new content may be an enhancement to 2-3 existing files rather than a standalone topic. A new file that's 60% overlap with existing content adds maintenance burden without proportional discovery value.

## Porting a Skill Reference to Team Learnings

"Port X as a learning to learnings-team" means:
1. Copy content to `~/.claude/learnings-team/learnings/<filename>.md`
2. Add an entry to `~/.claude/learnings-team/learnings/CLAUDE.md` index
3. Leave the original file untouched
4. Don't update references in the source repo

The original serves as the authoritative source for skill files that reference it; the learnings-team copy makes it discoverable across sessions without requiring a skill load.

## Check Both Header and Footer Cross-Refs When Deleting Files

Learnings files carry references in two locations: the `**Related:**` header (line 3, for sniff-time discovery) and the `## Cross-Refs` footer (for loaded-file follow-up). When deleting or renaming a file, grep for both patterns — fixing only the header leaves dangling refs in the footer that cause stale cross-ref warnings.

## Implementation Patterns Are Equal Signal to Discussion Notes

When extracting learnings from code reviews, discussion notes are the easiest anchor but not the only signal. A 30-file, 0-note MR introducing a new adapter has more implementation signal than a 1-file, 5-note MR where all notes are bot approval + SonarQube. Triage extractors on the *work* (description keywords, file count, module introduction), not just the *discussion count*. Validated by spot-checking 5 low-discussion MRs: original extraction captured ~30-40% of implementation patterns; re-extraction with implementation focus recovered the remaining 60-70%.

## Self-Contained Descriptions Over Metadata Lines

Learnings entries should be self-contained paragraphs with actionable guidance baked into the description. Avoid separate **Source**, **Frequency**, or **Takeaway** bullet lines — they add token cost without proportional value when the description is well-written. A good description already conveys what to do, when it applies, and why it matters. Splitting the actionable bit into a Takeaway line often just restates the title. Applied across 11 files in a batch extraction session, this reduced total size by 47% with no information loss.

## Generalizing Project Learnings to Shared Team Learnings

When extracting project-local learnings into shared team learnings, strip project-specific entity names (adapter names, class names, MR/PR numbers, service names) but preserve the structural pattern and its rationale. The goal is a learning that helps any team member working on a similar problem, not just someone working in the originating codebase.

**What to strip:** Specific class names (`VendorConfig`, `ExchangeAdapter`), MR/PR references (`!1234`), internal service names, specific table/column names.

**What to keep:** The pattern shape, the failure mode it prevents, framework/language specifics (Spring, PostgreSQL, gRPC), and the rationale for why the pattern exists. Code examples are fine if they illustrate the pattern generically.

**Scope is broader than gotchas:** Include validated architectural practices, good engineering conventions, and patterns that help teams make better decisions — not only things that caused incidents or surprised someone.

## Prune Learnings After Operationalization

When discoveries from a learnings file get promoted into reference docs or skills (e.g., a watermark pattern becomes a section in `sweep-scaffold.md`), prune the original learnings file to retain only unique gotchas not covered by the authoritative source. Unpruned learnings files become noise — they duplicate reference docs at lower fidelity, confuse agents about which source is authoritative, and inflate context when both get loaded. The learnings file's role shifts from "discovery log" to "gotchas supplement."

**Detection:** If a learnings section restates what a reference doc already says (convergence rules, directory structure, watermark logic), it's stale. If it captures a platform gotcha or operational decision not in any reference doc, it stays.

## Batch Import Sanitization Can Overwrite Established Files

Batch import scripts that `cp` staging files to final locations overwrite without merging — no distinction between "new content to merge" and "established file to preserve." Diff staging against existing files and flag overwrites when the existing file is larger.

## Platform-Specific CLI References Leak Through Sanitization

Sanitization strips project names but misses platform CLI tools (`glab` in a GitHub repo, `gh` in a GitLab repo). Check for platform CLI mismatches when sanitizing extracted content.

## Verify Cross-Ref Destinations Exist Before Updating Refs

When refactoring learnings structure (renaming files, moving into subdirs), update cross-refs only after the destination file actually exists at the target provider path. Speculative updates for a reorg that never ran leave broken refs across every consuming file. Before writing `provider:<name>/new-path/file.md`, resolve the provider's `localPath` and confirm the file is there. Batch imports from other repos are the common culprit — they encode the authoring agent's target structure, not the current structure.

## Dangling Refs After Consolidation

Lifting prose from one file into another can leave **contextual dangling refs**: phrases like `"the existing computeIfAbsent pattern"` that were valid in the source (where surrounding text supplied the context) but become opaque after the lift. Distinct from stale path refs — the path is fine, the *language* assumes deleted context. Grep can't catch these. Detection: read each lifted paragraph standalone and ask "does this sentence reference something not in this file?"

## Intra-Target Dedup Gap in Fold Operations

Fold dedup verification typically compares source vs target — does the new content already exist in the target? It misses **verbatim duplicates within the target** that result from merging two source files into the same destination. Both sources contributed identical sections; the target now has the section twice. Add a self-grep on the target after each fold: `grep -c '^## <heading>' <target>` should return 1.

## Ceremonial Sentences Cluster at Paragraph Ends

Concrete heuristic for conciseness review: **if removing the last sentence of a bullet or paragraph doesn't change the meaning, it's ceremony.** Authors instinctively add a closing sentence to "land" a point — restating the section title, summarizing what was just said, or noting "this pattern is useful for X."

## Meta-Self-Application Check for Writing-Quality Learnings

Learnings that describe writing patterns (ceremonial sentences, conciseness heuristics, hedging) should be validated against their own content. The pattern author instinctively violates the pattern they're documenting — the "ceremonial sentences" section had a ceremonial close by its own heuristic. When reviewing or writing such learnings, apply the described rule to the learning itself as a final check.

## Proposal Sections Resist the "Proposed" Label

**Keywords:** epistemic label, implementation plan, proposal framing

Authors writing about a design they've mentally committed to produce confident prose that doesn't reflect the epistemic state "this has not been validated." If a learnings section references an open PR/issue as the "next step," the section documents a proposal, not a validated pattern — even if the content reads like established guidance. The fix is a label (`[Proposed — pending #N]`), not removal. The insight is often valuable; the framing should match the confidence level.

**Reviewer heuristic:** When a learning section contains "implementation plan" or links to an open PR as the source of truth, flag the missing epistemic label.

## Cross-Refs

No cross-cluster references.
