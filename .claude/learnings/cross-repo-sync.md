# Cross-Repo Sync Patterns

## Quantum-tunnel-claudes path-mismatch gap

The inventory script compares files by relative path. Skills that exist in both repos under different names (e.g., `create-pr` ↔ `create-mr`, `address-pr-review` ↔ `address-mr-review`) won't be detected as common files — they show up as "only in source" / "only in target" instead. Content drift between these pairs requires either name-mapped equivalents in the inventory logic or a manual comparison pass after the automated sync.

## Platform-detection.md is intentionally dual-platform

`skill-references/platform-detection.md` contains a mapping table with both GitHub (`gh pr`) and GitLab (`glab mr`) commands side by side. This is by design — it's a reference for platform detection logic. Don't adapt its `gh` references when porting between GitHub- and GitLab-flavored repos.

## Example tables inside skills need adaptation too

When porting skills between GitHub/GitLab repos, it's not enough to adapt command references and skill name fields. Example tables embedded in skill instructions (like cluster examples showing `git:split-pr, git:create-pr, ...`) also contain skill names that need PR→MR adaptation. These are easy to miss because they look like illustrative content rather than functional references.

## Grep-Verify Terminology After Cross-Platform Sync

After merging files between GitHub- and GitLab-flavored repos, run a negative grep for the "wrong" platform's terminology across all modified files:

```bash
grep -rEi 'PR |gh pr|prUrl|pull request|GitHub' .claude/commands/ .claude/learnings/
```

Zero matches = clean adaptation. This catches leaks in prose, code examples, JSON field names (`prUrl` vs `mrUrl`), and CLI commands (`gh pr create` vs `glab mr create`). Run this as a final verification step after all merge agents complete.

## PR→MR Terminology Dominates BOTH_UNIQUE Diffs

When quantum-tunneling from a GitHub-convention source to a GitLab-adapted target, ~80% of BOTH_UNIQUE files have only PR→MR terminology differences. Scan the inventory diff output for `gh`, `PR`, `pull request` keywords to rapidly triage these as skip-redundant without reading both files in full. Saves significant analysis time on large inventories.

## Invoke Skill Scripts via ~/.claude/, Not Expanded Paths

Skill scripts referenced as `bash <TARGET>/.claude/commands/...` may fail when permission allow-patterns are configured for `~/.claude/` (the symlink path). Always invoke scripts through `~/.claude/commands/` to match permission patterns. The expanded repo path (e.g., `/Users/.../mahoy-claude-stuff/.claude/commands/...`) won't match `~/.claude/` allow rules.

## SUPERSET:target Needs Curation Review, Not Auto-Skip

When the source repo has done active curation (removing project-specific content, compressing patterns), SUPERSET:target files may contain stale project-specific content the source intentionally removed. Don't auto-skip these — inspect what the target has that the source doesn't. Common categories: project-specific examples (wallet apps, named components), domain-specific gotchas already covered by a more specialized file, and generic philosophy bullets that add little value. Follow the source's curation when the removed content is project-specific; keep target-unique content when it's genuinely generic and valuable (e.g., multi-agent orchestration patterns).

## Daily Sync Prevents Merge Debt

Frequent quantum tunneling (daily) between repos keeps diffs small and genericization clean. Each sync's merged output becomes the base for the next sync, so genericization compounds — project-specific examples removed today won't reappear tomorrow. Infrequent syncs accumulate large diffs where the same genericization work must be repeated across many files.

## Heading-Miss ≠ Content-Miss During Merges

A source section heading absent from the target doesn't mean the content is missing. Multiple smaller target sections can cover the same content under different names (e.g., source "Modal Execution Ownership" fully covered by target's "Lift Execution State" + "Modal as Form-Only" sections). During content-aware merging, compare content semantics — not just heading presence — before adding source sections.

## Execution-Phase Routing for Merge Scale

Route merge execution by divergence size: large diverged files (>15 source-unique lines) → background agents for parallel merges. Small diverged files (≤15 lines) → direct inline triage from inventory diff. Small-file triage frequently results in skips (target already ahead, terminology-only diffs), saving agent spawn overhead. This mirrors the analysis-phase threshold in the skill's step 2b.

## Background Merge Agents Need Pre-Registered Write Permissions

Background agents launched for parallel merges can't prompt for tool permissions — they silently fail when Write/Edit aren't pre-registered in `.claude/settings.local.json`. The agents complete their analysis correctly (reading both files, producing merge instructions) but can't apply the results.

**Coordinator fallback:** When an agent completes analysis but couldn't write, read its output for the merge instructions and apply edits directly from the main session. The analysis is the expensive part; applying it is mechanical.

**Prevention:** Before launching merge agents, verify that `Write(.claude/**)` and `Edit(.claude/**)` appear in the target repo's settings. The quantum-tunnel SKILL.md Prerequisites section documents the needed patterns, but the coordinator should verify at runtime — missing patterns cause silent failures that aren't discovered until agent completion.

## Context Continuation Can Produce Inaccurate File Paths

When a session is compacted and continued, the summary may record file paths inaccurately (e.g., `learnings/persona-design.md` instead of actual `commands/learnings/curate/persona-design.md`). The summary captures the *concept* of what was being worked on but may simplify or misremember the exact path.

**Fix:** At the start of a continuation session, re-verify paths with `Glob` or `find` before attempting reads. Don't trust summary paths verbatim — treat them as hints, not sources of truth.

## Large Inventory Output Handling

When inventory scripts produce 60KB+ output, both Bash and Read persist the output to files. Reading a persisted file can itself produce another persisted file (output still too large), creating an access loop. Pattern: (1) `grep -n '==='` on the persisted file to find section boundaries, (2) `sed -n 'start,endp'` to extract sections to `/tmp`, (3) Read with offset/limit on the extracted file. Alternatively, use Read with offset/limit directly on the persisted file if you know the line ranges.

## Bulk Sync: cp for Copies, Read+Edit for Merges

For quantum-tunnel syncs with 20+ items, use `bash cp` in batch commands for straightforward copies and superset:source overwrites (1-2 tool calls total). Reserve Read+Edit/Write only for BOTH_UNIQUE files needing content-aware merges. The skill's Read+Write instruction ensures correctness; `cp` achieves the same with dramatically fewer tool calls.

## Style Divergence: Keep Target's Evolved Phrasing

When source and target guidelines diverge on voice/style (e.g., first-person "I" vs third-person "my partner"), the target's evolution is intentional. During merges, keep target's phrasing for shared sections and only pull substantively new sections from source. Don't let style diffs inflate the BOTH_UNIQUE assessment — they're cosmetic, not content.
