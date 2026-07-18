Capturing a long design session into durable docs: separate the spec from the reasoning, and preserve the complete citation set. Also: auditing existing docs for newcomer onboarding by walking the path.
- **Keywords:** design doc, research doc, plan, spec, ADR, decision record, citations, sources, design session capture, reasoning vs spec, re-litigation, handoff doc, roadmap status table, shipped verification, squash revert, re-prove, re-proved tables, doc drift, frozen doc sync, evergreen citations, pointer vs hardcoded number, stale rationale, verdict survives evidence flip, newcomer onboarding audit, walk the path not inventory, README friction, doc gap evaluation, false prerequisite, jargon glossary gap, run-before-setup ordering, verify subagent file:line claim, surface buried content over new docs
- **Related:** ~/.claude/learnings/claude-authoring/learnings-organization.md

---

## Separate the spec (plan) from the reasoning (research) as cross-linked artifacts

A long design conversation produces two distinct things — keep them in separate, cross-linked docs:
- **Plan** (`docs/plans/...`) — the *spec*: what to build, contracts, phases, effort. Lean and executable.
- **Research** (`docs/research/...`) — the *why*: options considered + rejected, industry grounding, cited evidence, the decisive tests.

Conflating them bloats the spec and buries the reasoning; the research doc is what stops a future session re-litigating settled decisions.

## Capture the COMPLETE citation set, not a curated subset

When saving research, include **every substantive source** — mark `[★]` for used-inline vs. corroborating/secondary. "Save everything" means the full set; a curated subset forces the partner to come back with "did the other sources get captured?" Exclude only genuine noise (book-store listings, off-topic results, duplicate index pages for the same paper) — and say so explicitly when you do.

## Converge a design via completeness sweeps, then explicitly freeze

Iterate a design doc with repeated "what else is missing?" sweeps until one returns nothing load-bearing, then **declare it frozen**. Resist manufacturing more ideas to seem thorough (the partner asked, didn't beg) — name the remaining unknowns and defer them to build-time (YAGNI; over-specifying bakes in one example's accidents). The explicit freeze is the signal that design is done and building can start.

## Re-verify a handoff/roadmap status table against the tree before re-publishing

Confirm each "✅ shipped" row by checking the artifact exists on the merge target (`ls <file>` / `git grep <symbol> <branch>`) — not the PR's commit list or the table itself. A squash merge folds a feature commit **and its later revert** into one net-zero commit, so a tracking doc can claim "shipped" for a file that doesn't exist on `main` (worked case: an extracted-then-reverted shared skeleton). Same pass: a merged refactor reshapes files, so re-grep symbols and fix stale `file:line` refs rather than trusting the doc's numbers.

## Re-sync a frozen spec against a re-proved source: find the freeze, diff the source

A spec/plan doc that cites figures from a periodically re-proved research source drifts silently when the source is re-run. Detect it: `git log -1 -- <doc>` for its freeze commit, then `git diff <freeze>..HEAD -- <source-dir>` and compare every cited figure against the current source. Prevent recurrence: **evergreen the citations as pointers** ("see `findings.md` § X") instead of hardcoded numbers, keeping only the one or two values that drive a decision — the literal numbers then live in one authoritative place and never re-stale the spec.

## A verdict can survive a re-prove while its supporting evidence flips

After a clean recompute/re-prove (no bug — just fresher data or a behavior change), a doc's headline conclusion may still hold but on *different evidence*. Verify each supporting sub-claim independently, not just the verdict: a rejection that rested on "cuts return without cutting drawdown" + "monotone toward no-tilt" can have both invert (drawdown now drops; sweep no longer monotone) while the conclusion stands on a new metric (highest final equity). Tests pass and the headline reads correct — the stale *rationale* is the silent defect.

## Audit onboarding docs by walking the newcomer's path, not inventorying files

To judge whether docs onboard someone new, *follow the path they take* — land on the README, run the first command, attempt setup — and log where the trail goes cold: undefined jargon, run-before-setup ordering, a "prerequisite" that isn't one (e.g. a backtest that needs no broker creds but is gated behind broker setup). A file-by-file inventory misses these — friction only shows in sequence. Fan out parallel readers for breadth, but verify each subagent's `file:line` claim against the source before asserting (agents cite lines that don't exist), and prefer surfacing buried content (promote a diagram, link an index) over authoring new docs.
