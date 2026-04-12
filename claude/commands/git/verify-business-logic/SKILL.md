---
name: verify-business-logic
description: "Post-convergence verification — checks discipline rules and intent alignment on a PR after review/address cycles complete. Standalone or director-called."
argument-hint: "<pr-number> [--intent-file <path> --session-dir <path>]"
---

## Context

- Project root: !`git rev-parse --show-toplevel 2>/dev/null`
- Current branch: !`git branch --show-current 2>/dev/null`

# Verify Business Logic

Post-convergence check that verifies review/address discipline and intent delivery on a PR. Produces a top-level PR comment with findings.

Two modes:
- **Standalone**: `/verify-business-logic 42` — self-captures intent from PR metadata, asks operator to confirm
- **Director-called**: `/verify-business-logic 42 --intent-file <path> --session-dir <path>` — reads locked intent file, skips capture

## Usage

- `/verify-business-logic <pr-number>` — standalone verification
- `/verify-business-logic <pr-number> --intent-file <path> --session-dir <path>` — director mode

## Prerequisites

```
gh auth status
```

For prompt-free execution, add these patterns to `~/.claude/settings.local.json`:
```
"Bash(gh api *)",
"Bash(gh pr diff *)",
"Bash(gh pr view *)",
"Read(~/.claude/commands/git/verify-business-logic/**)",
"Read(~/.claude/skill-references/request-interaction-base.md)"
```

## Reference Files (always loaded)

@./discipline-rules.md
@./prompt-template.md

## Reference Files (conditional)

- `director-mode.md` — **Read only when** `--intent-file` and `--session-dir` are present in `$ARGUMENTS`. Covers CLARIFY protocol, intent file schema, session dir output convention.
- `~/.claude/skill-references/request-interaction-base.md` — **Read for** platform detection, footnote format, comment identity patterns.

## Steps

### Step 0: Set Persona

Activate the convergence-verifier persona before any other step:
```
Skill tool: skill="set-persona", args="convergence-verifier"
```

### Step 1: Parse Arguments and Detect Mode

Parse `$ARGUMENTS`:
- Extract `<pr-number>` (required)
- Check for `--intent-file <path>` and `--session-dir <path>`
- If both present: `MODE=director`, read `director-mode.md`
- If neither present: `MODE=standalone`
- If only one present: **halt with error.** Emit: "Error: director mode requires both `--intent-file` and `--session-dir`. Got only `<flag-present>`. Halting — no PR data fetched, no output produced." Do not fall through to standalone mode. Return no output that could be parsed as a successful result.

### Step 2: Resolve Intent

Resolve intent **before** fetching PR data. This enables early CLARIFY in director mode without wasting API calls, and ensures discipline checks and intent alignment run on a single consistent PR snapshot.

**Director mode** (`MODE=director`):
1. Read the intent file at the path from `--intent-file`
2. **Validate the intent file** — halt with a descriptive error on any of these:
   - File does not exist: "Error: intent file not found at `<path>`. Halting — no PR data fetched."
   - File exists but has no `Source` field: "Error: intent file missing required `Source` field. Halting."
   - `Source` value is not one of `director-negotiated`, `agent-prompt`, `inferred-from-pr-description`: "Error: unrecognized intent Source `<value>`. Expected one of: director-negotiated, agent-prompt, inferred-from-pr-description. Halting."
   On any error: produce no output the director could parse as success.
3. Extract `Source` field and set `INTENT_SOURCE` to the value from the file
4. **Check intent vagueness**: if the intent is too vague to evaluate scope drift or acceptance, output `CLARIFY: <specific question>` and stop immediately. The director routes it. Maximum one CLARIFY per run. This avoids fetching PR data on an intent that can't be evaluated.
5. No operator interaction — intent is pre-negotiated

**Standalone mode** (`MODE=standalone`):
Intent capture requires PR metadata, so fetch basic PR info (title, description, linked issues) first, then:
1. Draft a quick intent summary following the format:
   ```
   ## Goal
   <one or two sentences>

   ## Acceptance criteria
   - [ ] <criterion — checkable>

   ## Out of scope
   - <inferred exclusions, if any>
   ```
2. Present to operator: "Here's what I think this PR is trying to do — confirm or revise?"
3. One revision round if operator adjusts
4. If still too vague after one round, produce report with "intent too vague to evaluate" section
5. Set `INTENT_SOURCE=operator-confirmed`

### Step 3: Fetch PR Data

Fetch in parallel:
- PR metadata: title, description, state, linked issues (skip if already fetched in Step 2 standalone mode)
- PR diff: full diff
- PR comments: all review comments, inline comments, and top-level comments
- PR reviews: all review submissions

If PR is merged or closed, note terminal state but proceed — verification of completed PRs is valid.

### Step 4: Run Discipline Checks

Discipline rules are eager-loaded via `@./discipline-rules.md`.

For each rule:
1. Evaluate the assertion against fetched PR data
2. Record pass/fail with evidence
3. Failed assertions: cite specific comment IDs, thread URLs, or content

Build the discipline checklist per the format in `discipline-rules.md`.

### Step 5: Run Intent Alignment Checks

Using the resolved intent and the PR diff/comments:

1. **Acceptance criteria**: For each criterion, search the diff and commits for evidence of delivery. Cite commit SHA + diff lines.
2. **Scope analysis**: Identify changes not covered by any acceptance criterion. Classify each as:
   - `intentional expansion` — visible justification in PR discussion
   - `unrelated drift` — no connection to intent
   - `missed cleanup` — intent item not delivered and not deferred
3. **Quality gate**: Scan diff for TODOs, placeholder text, half-implemented branches. Cite file + line.
4. **Side effects**: Surface changes outside the intent (ambient commits, config changes). Don't judge — just list.

Scale confidence framing per `INTENT_SOURCE` (see `prompt-template.md` for framing language).

### Step 6: Compose and Post Report

1. Build the report following the template in `prompt-template.md`
2. Append the footnote (per `request-interaction-base.md` format):
   ```
   ---
   - *Co-Authored with [Claude Code](https://claude.ai/code) (<model>)*
   - *Persona:* convergence-verifier
   - *Role:* Verifier
   ```
3. Post as a **top-level comment** on the PR using `gh api`

**Director mode additionally**: Write the report to `<session_dir>/verify-pr-<N>.md`.

### Step 7: Report Completion

Use a structured completion signal so the director can parse status without free-text matching:

```
VERIFIED:<status> PR #<NUMBER> — <summary>
<PR_URL>
```

Where `<status>` is one of:
- `pass` — all discipline checks passed, intent alignment satisfactory
- `fail` — one or more discipline failures or critical intent gaps
- `intent-unclear` — intent too vague to evaluate after CLARIFY limit reached (report has explicit "couldn't evaluate" sections)

The `intent-unclear` status is a **blocking signal** — the director must not converge the session on a PR with this status.

## Important Notes

- **Discipline checks are assertions, not opinions.** They pass or fail with cited evidence. Don't soften discipline findings.
- **Intent alignment is advisory.** Frame as "things to check," not verdicts. The operator decides what matters.
- **Don't repeat the diff.** The operator has the PR open. Cite specific locations, don't quote large blocks.
- **Footnote is mandatory.** The `Role: Verifier` tag distinguishes verification comments from review/address comments.
- **One CLARIFY max in director mode.** Checked at Step 2 before PR data is fetched. If still unclear after one round, produce the report with explicit "couldn't evaluate" sections and `VERIFIED:intent-unclear` status rather than looping.
- **Empty discipline sections are fine.** If all rules pass, report the clean checklist. Don't manufacture findings.
- **Timing matters for loop closure.** Missing responses might mean the address cycle hasn't completed, not that discipline failed. Check whether the address runner converged before flagging orphaned threads.
