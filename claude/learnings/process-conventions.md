Patterns for how engineering work is organized, scoped, and tracked — PR splitting, MR scoping, phased delivery, and preparatory refactoring.
- **Keywords:** PR splitting, MR scoping, cherry-pick, preparatory refactoring, scope creep, staged renames, plan-first PR, PR description, git history, safeguards, plan retirement, plan lifecycle, acceptance criteria, issue closure, tracking issue maintenance
- **Related:** ~/.claude/learnings/review-conventions.md, ~/.claude/learnings/code-quality-instincts.md

---

### Three-source config drift in deploy PRs

When a PR adds or modifies a service in `docker-compose.yaml`, the same config keys often appear in `README.md` and a runbook (e.g., `deploy.md`). All three drift independently. Before merging, grep all doc sources for the keys touched:

```bash
rg -l "TRADING_WINDOW|TS_TOKEN_PATH" docs/ scripts/ README.md
```

The compose value is usually the source of truth (executable); docs need to follow. Catching this at PR time is cheaper than producing a fourth contradictory source post-merge.

### Cross-reference comments in executables for multi-source docs

When a config value or convention lives in N doc locations *and* an executable script, add a one-line comment in the executable pointing to the canonical doc:

```bash
# Mount source: schwab.env → see docs/per-broker-env-rollout.md
docker run -v "$PWD/config/schwab.env:/workspace/config/.env:ro" ...
```

Makes `grep schwab.env` surface all N+1 locations atomically — the executable joins the three-source-drift check above instead of hiding from it.

### Defer large cross-cutting refactors to tracked issues

When code review surfaces a systemic improvement (e.g., float-to-Decimal conversion), file an issue rather than scope-creeping the current PR. The PR stays focused; the improvement gets tracked. Even for straightforward rename/reorganization tasks, creating an issue first establishes traceability and makes the "why" discoverable later (`Fixes #N` for clean linking).

### Surface skipped review findings as follow-up issues

When `/simplify` or a multi-agent review surfaces findings you decline to apply (out of scope, debate over premise, marginal value), file them as issues rather than dropping silently — the operator decides priority later, signal isn't lost. Before filing, `gh issue list` to position the new issue against existing tracked work (cross-reference: `distinct from #N which tracks…`). Split issues by scope — feature-specific cleanup vs project-wide style — even when the user asks for "an issue" (singular). Bundling unrelated scopes muddies the issue's focus and makes "close as wontfix" harder per-item.

### Plan-first PRs as exploration pattern

PRs that include a plan document alongside implementation code serve as design artifacts. Even when the PR is ultimately closed, the planning work feeds into the decision — the analysis itself is the value. However, plan PRs scoped too narrowly get superseded — when planning refactors that touch data types flowing across module boundaries, scope the plan to the full data flow path, not just the module where symptoms are most visible.

### Closing PRs cleanly with cherry-pick intent

Rather than silently abandoning a PR, explicitly note that unique content will be cherry-picked into a follow-up. Makes the closed PR a discoverable record of what was tried and what content is still pending. Tactical approach: when a "lite" version gets merged first, close the redundant PR, create a new branch from main, manually add only the unique content (don't cherry-pick commits if files diverged), and open a focused PR.

### Scope MRs tightly — one concern per merge request

Breaking changes bundled with new features make review, rollback, and changelog tracking harder. Ship separately. Large exploratory MRs (47+ files) get closed. Cross-cutting refactors with zero pre-alignment face high closure risk. Small, focused MRs (4 files, single purpose) get same-day turnaround. Tangential changes (e.g., CLAUDE.md update in a feature PR) get their own PR, even if small.

### Ship integration client separately from orchestration wiring

Ship the client (HTTP wrapper, DTOs, auth) as a standalone MR before the orchestration. Reduces review complexity and isolates failure domains.

### Self-documenting MR descriptions

For larger MRs, state which files contain the important business logic. Guides reviewers to spend time where it matters.

### Migration conflict resolution should be documented

State the original version and new version in the MR description. Makes it easy for reviewers to verify without digging through diffs.

### Large renames should be staged

Prioritize internal renames to unblock dependent MRs, deferring deployment-visible changes (Docker image paths, pipeline configs).

### Preparatory refactoring deserves its own MR

"Make the change easy, then make the easy change." Separating refactoring from feature work keeps both MRs focused. The refactoring MR establishes the new structure; the feature MR builds on it.

### READMEs should lead with prerequisites

Users need to know what to install before following setup steps. Structure: prerequisites first, then setup, then usage.

### Sensitive data audit checklist for shared dotfiles

Audit for: internal project/repo names, MR/PR numbers, absolute paths with usernames, internal tool names, team names, org-specific identifiers. Focus effort on tracked files; `settings.local.json` is gitignored.

### Portability check before promoting tmp/ scripts to checked-in paths

Scripts that lived in gitignored `tmp/` often carry environment assumptions (hardcoded `REPO_ROOT`, `cd /Users/<me>/...`). Before staging the copy, `grep /Users/<username>` (and `$HOME`-style absolutes) over the new files; replace with self-derivation (see `~/.claude/learnings/bash-patterns.md` → "Symlink-aware self-location"). Apply to any script promotion from personal/tmp into shared/committed locations.

### Sensitive-data scan: two-pass + baseline-vs-new triage

`git diff HEAD` covers modified-file additions only — untracked files need a separate `grep`/`Read` pass since `diff` skips them entirely. For each finding, distinguish HEAD-baseline (already committed, operator-accepted) from new-in-diff before flagging — sanitization should scope to actual new exposure, not re-litigate accepted content. Present a triage table tagged by severity + new-vs-baseline so the operator decides once.

### PR splitting strategy for large PRs

When splitting a large PR, separate refactors and structural changes first (independent, merge to main), features last (dependent, merge after structure). Structure → tests → feature is the natural dependency order.

### Relocate decision frameworks to the moment of use

When a decision framework (e.g., "separating universal from specific") lives in a general guideline but is only needed at one specific moment (e.g., capturing learnings), move it to the skill where it's actually used. Location should match the moment of use.

### Verify safeguards survive fixes

When fixing one problem, verify the original problem's safeguards are preserved or replaced. Pattern: when removing a workaround, ask "what was this protecting against?" before deleting. After the fix, test that the original safeguard still works — not just that the symptom is gone.

Example: removing `?per_page=100` from URLs to fix quoting issues silently reverted to the 30-result default, hiding comments beyond page 1. The fix (`--paginate`) replaced the safeguard — but verification ("command runs without permission prompt" ✅ but "command still returns all results" ❌) would have caught the regression immediately.

### Fix the source, not just the behavior

When a correction traces back to a template or reference file, fix the file — not just your current behavior. Otherwise the next session reads the same bad template and repeats the mistake. If you're corrected on a command format and the command came from a template, update the template immediately.

### Update PR Description When Scope Drifts During Review

When mid-review work significantly expands a PR's scope beyond its original intent (e.g., an extraction PR gains cron infrastructure, permission patterns, and new learnings sections), update the PR title and description before shipping. Future readers use the description to set expectations — a mismatch between title and content makes the PR harder to review and reference.

## Verify PR Description Claims Against Git History

Before editing a PR description to say "adds X" or "removes Y", verify with `git log <base>..<branch> -- <file>`. Don't rely on `git diff <base>` — a file that appears "deleted" in the diff may have been added to base *after* the branch was cut, meaning the branch never touched it. `git log` is authoritative; `git diff` can mislead when branches diverge.

```bash
# Confirm a file was actually touched by this branch
git log main..HEAD -- path/to/file.md
# Empty output = branch never touched it (don't claim it in the PR description)
```

### Calibrate Flag-Worthy Observations to Operator-Cession Tier

Surfacing every discovery erodes trust in flags as much as missing real ones. Apply the same tier system as decision-making:

- **Routine observations** (small inconsistencies, transient state, things that resolve themselves) → log silently to memory, follow-up doc, or just hold. Don't surface inline.
- **Substantive observations** (things that change the operator's plan, real bugs, broken contracts, unexpected behavior with downstream impact) → flag inline.

Failure mode: over-flagging tiny discoveries creates noise that the operator has to filter, training them to ignore flags — including the substantive ones. This is the same shape as the decide-silently / decide-with-report / escalate framework: routine work doesn't need surfacing.

Concrete examples of routine (silent log): a transient `last_comment_id: none` in one cycle's status that recovers next cycle; a runner state file that looks stale but resolves on completion notification; a one-off naming inconsistency in a generated artifact. Concrete examples of substantive (flag inline): a stale-ref class of bug that affects multiple files; a permission pattern gap blocking work; intent drift between PR description and delivered diff.

### Check git history for prior art before designing new protocol features

When adding features to a protocol or system, check git history for previously removed versions of the same concept. Prior art often contains design decisions, failure modes, and refinements that save reinvention. The removed version may need only a targeted fix rather than a from-scratch redesign.

### Check open issues/PRs before laying out a design spectrum

For any "how should we approach X?" question, search the project's open issues, PRs, and `docs/plans/` first — `gh issue list --search <topic>`, `gh pr list`, `ls docs/plans/`. The architectural decision may already be scoped with tradeoffs documented and an implementation in flight. Re-deriving the spectrum from scratch wastes effort and risks landing on a different answer than the team chose.

### Match design ambition to framing

When the request uses architectural language ("dependency injection," "cleaner boundaries," "decoupling"), lead with the architecturally clean proposal. Don't default to "simplest thing that works" when the ask is "right thing." Read the register: "can we make this work?" → simple path fine. "Can we make this clean?" → lead with clean architecture, present the simple path as the fallback.

### Challenge plan docs before executing them

When asked to execute a plan (create issues, implement PRs), read it critically first — not just for understanding but for architectural soundness. Plans written in one session may embed assumptions worth revisiting: first-implementation-shaped abstractions (Schwab-shaped dicts as a "broker-agnostic" protocol), overloaded PRs (four concerns in one), or test ergonomics gaps (env gates that break test imports). Surface questions before creating artifacts — a 10-minute planning discussion that splits a PR or introduces typed models saves days of rework downstream.

### Clarify deliverable structure before writing research/planning docs

For research and planning tasks, ask about doc format and location **alongside** the scoping questions — before the first write. How many docs? What's each one's purpose? Where do they live? A research doc that gets restructured three times (one file → two → three, plus a directory move) costs more cumulative edits than asking the structure question upfront.

## Stacking PRs: Check Unchanged Code for Dependencies on Removed Code

The diff shows what changed — the bug is in what *didn't* change. When a PR removes a setup step (e.g., platform detection that sets variables), check all unchanged steps that referenced those variables. Partial migrations of individual files leave undefined variables that the diff won't flag. Review stacking PRs by reading unchanged sections for dependencies on removed code, not just the changed hunks.

## Dev-as-Test-Bed Reorders Hardening Rollouts

When introducing risky infra changes (KMS rollout, secret-fetch systemd ordering, OIDC trust policies), apply to a non-prod env first, observe ~1 week, then prod. Each downstream PR's risk profile improves — alarm thresholds tune against dev traffic; cutover dry-runs surface format mismatches before prod ever sees them.

Sequencing implication: if an MVP plan reads "set up dev after hardening lands," reorder. Dev-env PR slots **second** (after the foundational IaC PR), before each hardening PR. Pattern: dev-env → hardening N in dev → ~1-week observation → hardening N in prod → next hardening PR.

Catch: ephemeral dev (apply/destroy on demand) doesn't accumulate observation time. Use long-lived sim-mode dev for rollouts where the value is the burn-in window (alarm tuning, integration regressions). Use ephemeral dev for the apply/destroy iteration cycle itself.

## Cross-Refs

- `~/.claude/learnings/review-conventions.md` — code review patterns (complementary: workflow vs review)
- `~/.claude/learnings/code-quality-instincts.md` — code-level quality patterns (complementary: code vs process)

### Remove TODOs before merging to main
TODOs in production code are deferred decisions that accumulate silently. Resolve them before merge or convert to tracked tickets with context. A TODO without a ticket reference is a promise nobody is tracking.

### Dependency-aware parallel work item processing

When issues declare dependencies (`Blocked by: #N, #M`), an orchestrator can auto-detect which items are ready by resolving each blocker's state:

| Blocker state | Item eligible? | Base branch |
|---|---|---|
| Issue closed or PR merged | Yes | default branch |
| Open PR exists | Yes | blocker's PR branch (stacked) |
| Open, no PR | **No — skip** | — |
| Multiple blockers on different open PRs | Yes, but ⚠️ diamond dependency | default branch (can't merge two bases) |

This eliminates manual wave planning — run the orchestrator on all issues, it picks up what's ready. Re-run after merges to peel off the next wave. Parse `Blocked by:` lines + `## Dependencies` sections; search PRs by both branch name convention (`sweep/<N>-*`) and body references (`Relates to #N`, `Fixes #N`) to avoid missing manually-created PRs. Batch blocker state lookups to avoid redundant API calls when multiple issues share blockers.

### Surface all plan-mode design decisions in one message

Surface all open design decisions (naming, output format, file organization, scope boundaries) in one message before requesting plan approval. Drip-feeding decisions via repeated exit-and-revise cycles adds round trips without adding clarity.

### Surface cross-issue scope shifts when batch-answering

When answering questions across linked issues in one pass, an answer on issue A often narrows or expands issue B's scope (e.g., "bake the safety check into A's implementation" → B becomes config-only). Flag these explicitly in the summary report — `Issue A → Issue B: <scope change>`. Without the flag, downstream readers treat each issue's scope as last-stated; the implicit dependency goes unrecorded and resurfaces during implementation as confusion.

### Manual pre-merge gates for live-system parity

Some ACs unit tests can't verify — adapter migrations, contract changes against external APIs, behavioral parity between old and new code paths against real traffic. Surface these as PR-body checkboxes the merger ticks off after manual verification, not as buried notes in commit messages or design docs.

Examples worth a checkbox: *"Run branch end-to-end against real API with `DRY_RUN=1` for one trading window"* · *"Diff orders placed against pre-migration baseline"*. Pre-merge checklist + a labeled "manual verification" status check are how the gate stays visible during review.

### Three-pronged scope-narrowing as a deferral path

When a review surfaces a finding that requires architectural scope (cross-process locking, async variant, retry policy) the right deferral isn't "file an issue" alone — three things move together:

1. **Update the PR description / class docstring** to drop any over-promised claim (e.g., "supports concurrent processes" → "single-process only"). The shipping artifact must not lie about what it does.
2. **File the follow-up issue** capturing scope, motivation, and acceptance criteria. Bundle related deferrals by *shared lifecycle/scope* — cross-process lock + async variant + connection reuse all touch the same locking/lifecycle plumbing → one issue, not three.
3. **Add an inline `.. note::` / runtime-visible callout** at the constraint site. The docstring callout makes the limitation operator-visible at the API surface, not buried in an issue tracker.

Reviewers explicitly accept this pattern when all three prongs land — narrowing scope alone reads as evasion, narrowing + tracking + runtime-visible callout reads as discipline. Apply when the fix requires meaningful new infrastructure (locks, daemons, parallel class hierarchy), the current deployment doesn't exercise the gap, and a future consumer will trip it. Skip the runtime callout only when the gap genuinely doesn't manifest in the current consumer surface.

### Pre-implementation diff check before starting a planned PR

When executing a multi-PR plan (E1 → E6 etc.), `git diff main feat/<predecessor>` before starting PR N. Earlier PR authors sometimes absorb the next PR's diff naturally — splitting them would have left awkward intermediate test states, so the natural commit boundary covers both. If the diff already includes PR N's planned change, mark PR N as obsolete and skip it. Pattern surfaces when plans were drafted before authoring; what looks like a separate PR on paper is often two lines that ride along with the previous one.

### Pre-PR grep dictates scope: narrow + named follow-up PR

When pre-PR grep surfaces an unanticipated live consumer of supposed-dead code (e.g., `backtesting/utils.py` importing `oracle.get_daily_data` during a "delete dead `plz/data.py`" PR), don't silently expand scope to absorb the refactor. Ship the cleanly-doable subset (delete the genuinely-dead module) and file a **named follow-up PR** for the deferred work — e.g., `E4` → `E4 narrow` + `E4b`. Distinct from the three-pronged review-deferral pattern: that's an issue + runtime callout for review-surfaced architectural scope; this is a peer PR for plan-execution scope discovered via pre-flight grep. Both PRs reference each other in their bodies so the deferral is discoverable.

### Doc-sweep PR over piecemeal doc updates across feature PRs

When a feature PR series deletes/renames files that learnings/architecture docs reference, fixing piecemeal in each feature PR creates doc-thrash and scope creep. Each feature PR notes the carry-over in its body ("`docs/learnings/integrations.md` still references deleted paths — separate doc-sweep PR pending"); the consolidated sweep ships once the feature series stabilizes. Feature PRs stay focused on code; the sweep PR is a single low-risk diff a reviewer can validate against a grep.

### Multi-PR plan → parent index issue + sub-issues with one per-initiative label

When a plan decomposes into N PRs, scaffold tracking as **one parent issue + N sub-issues**, all carrying a single per-initiative label (`mnq-myapp`, `IaC MVP`). Parent issue body: brief goal, locked architecture decisions, and a task-list of sub-issues using `- [ ] #N — title` syntax (GitHub auto-tracks completion as sub-issues close). Sub-issue bodies: `## Scope` (with "What's in PR N" / "What's NOT in PR N"), `## Acceptance criteria` (checkbox list), `## Risks`, `## Suggested lens` (which review persona is primary/secondary), `## Cross-references`. Plan.md remains the canonical living doc — issues reference it and don't duplicate decisions; updating decisions happens in the doc, not by editing N issues.

Workflow: read 1–2 existing issues to learn the repo's body shape, propose a sample, get operator OK on the template before bulk-creating. Bulk-create sub-issues first (parallel `gh issue create` calls), capture their numbers from stdout, then create the parent referencing the captured numbers in the task list. GitHub-relative paths in issue bodies resolve from repo root — use `[text](docs/plans/foo/plan.md)`, not `[text](../blob/main/docs/plans/foo/plan.md)`.

### Retire plan.md once issues absorb its decisions

Companion to "Multi-PR plan → parent index issue" above. Plan.md is canonical *during* issue scaffolding; once sub-issues hold scope/criteria, README holds operational steps, and durable rationale has moved to learnings, plan.md drifts behind the real source of truth. Lingering stale plans confuse future readers about which document is authoritative.

Audit-and-retire pass:

| Plan content | Destination |
|---|---|
| Goal / Decisions / Action items duplicated in sub-issues | drop with the plan |
| Deferred non-blockers (e.g., AWS Config, alternate-region dev) | tracking issue's "Future / not yet scoped" section |
| Post-cutover cleanup (e.g., delete legacy bootstrap script) | new sub-issue with the initiative label |
| Rejected design alternatives + verified platform constraints | learnings file |
| Operational color (cost / timing estimates) | drop |

Then delete the plan file. Heuristic for "is it time?": if the plan's "Decisions" section reads like a transcript of the sub-issue bodies, the plan has retired.

### Issue closure tracks acceptance criteria, not PR merge

When an issue's acceptance criteria mix code-shippable items (modules, scripts, README updates) with operator-side action (cutover, decommission, observation period, postmortem), merging the implementing PR doesn't close the issue. The issue stays open as a tracking artifact for the operator-side work, with the merged PR linked.

Auditing migration progress: distinguish "PR landed, issue intentionally still open because cutover hasn't run" from "issue forgotten." A glance at the criteria checklist tells you which. Don't auto-close on merge for cutover-bearing issues.

## Confluence MCP Publishing

### Markdown content format eliminates manual conversion

`createConfluencePage` and `updateConfluencePage` accept `contentFormat: "markdown"` — Confluence auto-converts to XHTML storage format. Code blocks get language-specific `<ac:structured-macro>` macros automatically. No need to hand-build storage format XML.

### cloudId accepts site URL; spaceId requires lookup

`cloudId` accepts the site URL directly (e.g., `<your-org>.atlassian.net`), not just UUID. But `createConfluencePage` requires numeric `spaceId` — get it via `getConfluenceSpaces` with `keys` filter. Page operations (`getConfluencePage`, `updateConfluencePage`) only need `cloudId` + `pageId`.

### Page tree publishing: parent first, children parallel

Update the parent page first to confirm the page ID, then create all child pages concurrently with `parentId`. Siblings have no ordering dependency — batch all `createConfluencePage` calls in one message for parallel execution.
