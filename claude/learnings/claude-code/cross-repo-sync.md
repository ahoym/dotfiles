Patterns for syncing Claude Code config between repos — quantum-tunnel merges, rsync export/import, platform terminology adaptation, and bidirectional sync strategies.
- **Keywords:** quantum-tunnel, rsync, sync, PR-to-MR, platform-detection, bidirectional, tarball, branch import, BOTH_UNIQUE, SUPERSET, skill naming, write-time separation
- **Related:** none

---

## Quantum-tunnel-claudes path-mismatch gap

Inventory comparison by relative path misses skills with different names across repos (e.g., `create-pr` ↔ `create-mr`). **Solved** by unified platform-neutral names (`create-request`, `address-request-comments`, etc.).

## Platform-detection.md is intentionally dual-platform

`skill-references/platform-detection.md` contains a mapping table with both GitHub (`gh pr`) and GitLab (`glab mr`) commands side by side. This is by design — it's a reference for platform detection logic. Don't adapt its `gh` references when porting between GitHub- and GitLab-flavored repos.

## Example tables inside skills need adaptation too

When porting skills between GitHub/GitLab repos, it's not enough to adapt command references and skill name fields. Example tables embedded in skill instructions (like cluster examples showing `git:split-pr, git:create-pr, ...`) also contain skill names that need PR→MR adaptation. These are easy to miss because they look like illustrative content rather than functional references. **Note:** unified `-request` skills eliminate this class of problem for the git skills — but the pattern still applies to any future platform-divergent skills.

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

## Context Continuation Can Produce Inaccurate File Paths

When a session is compacted and continued, the summary may record file paths inaccurately (e.g., `learnings/persona-design.md` instead of actual `commands/learnings/curate/persona-design.md`). The summary captures the *concept* of what was being worked on but may simplify or misremember the exact path.

**Fix:** At the start of a continuation session, re-verify paths with `Glob` or `find` before attempting reads. Don't trust summary paths verbatim — treat them as hints, not sources of truth.

## Large Inventory Output Handling

When inventory scripts produce 60KB+ output, both Bash and Read persist the output to files. Reading a persisted file can itself produce another persisted file (output still too large), creating an access loop. Pattern: (1) `grep -n '==='` on the persisted file to find section boundaries, (2) `sed -n 'start,endp'` to extract sections to `/tmp`, (3) Read with offset/limit on the extracted file. Alternatively, use Read with offset/limit directly on the persisted file if you know the line ranges.

## Bulk Sync: cp for Copies, Read+Edit for Merges

For quantum-tunnel syncs with 20+ items, use `bash cp` in batch commands for straightforward copies and superset:source overwrites (1-2 tool calls total). Reserve Read+Edit/Write only for BOTH_UNIQUE files needing content-aware merges. The skill's Read+Write instruction ensures correctness; `cp` achieves the same with dramatically fewer tool calls.

## Style Divergence: Keep Target's Evolved Phrasing

When source and target guidelines diverge on voice/style (e.g., first-person "I" vs third-person "my partner"), the target's evolution is intentional. During merges, keep target's phrasing for shared sections and only pull substantively new sections from source. Don't let style diffs inflate the BOTH_UNIQUE assessment — they're cosmetic, not content.

## Write-Time Separation Eliminates AI Merge for Sync

Instead of filtering content at sync-time (which requires token-expensive AI to distinguish shareable from non-shareable learnings), separate at write-time into `~/.claude/learnings/` (global, syncs to dotfiles) and `~/.claude/learnings-private/` (stays local). The routing question in `learnings:compound` is "broadly reusable?" vs "useful but too specific to share?" — one decision at write-time replaces an entire quantum-tunnel session at sync-time. Syncing to dotfiles becomes a simple rsync of `learnings/`, `guidelines/`, `commands/` — no AI needed.

## Label Non-Shared Content as "Private", Not "Company-Specific"

Use neutral labels like "private" for content that shouldn't be shared externally. Terms like "company-specific" signal to anyone reading the skill that there's sensitive content nearby worth hunting for if the filter misses something. "Private" is semantically accurate (doesn't leave this machine) and security-neutral — consistent with established conventions like `settings.local.json` and `.local` env files.

## Bidirectional rsync: `--delete` Is Asymmetric

For **export** (working repo → dotfiles), `--delete` is correct — dotfiles should mirror the shareable subset exactly. For **import** (dotfiles → working repo), `--delete` is dangerous — the working repo may have files the source doesn't (extra learnings, MR-named skills that differ from PR-named counterparts). Default import to additive (no `--delete`), with an explicit opt-in flag for destructive sync.

## PR↔MR Skill Names Are Invisible to rsync — Solved by Unification

Platform-divergent skill directory names are unrelated paths to rsync. **Solved** by unifying into platform-neutral names with runtime detection via `skill-references/platform-detection.md`.

**Naming convention:** Use "request" (shared root of "pull request" and "merge request"). Avoid "review" as noun — ambiguous with code review. **Pressure-test names before writing** — naming cascades into cross-references, templates, descriptions, and related skills tables.

## Within-File Section Removals Are Invisible to PREVIOUSLY_REMOVED

The `PREVIOUSLY_REMOVED` git history check only catches whole-file deletions — it looks for files that once existed in the target's git history but were later removed. It does NOT detect sections removed *within* a file by a prior commit. When the source still has that section, the content-aware merge re-introduces it.

**Example:** Target intentionally removed a "Just-in-time Layer" section from `context-aware-learnings.md` (commit b8d250b with explicit rationale: "unreliable across sessions"). Source still had it. Merge re-added it. User had to catch it manually.

**Mitigation:** After merging BOTH_UNIQUE files, check `git log --oneline -5 -- <file>` for recent commits touching that file. If any exist, `git show <commit> -- <file>` to verify no intentionally-removed sections were re-introduced. This is especially important for files with recent curation commits.

## Producer-Consumer Skill Pair Check During Sync

When a sync updates a producer skill (e.g., `parallel-plan/make`), check whether its consumer (`parallel-plan/execute`) needs corresponding updates. The two files form a contract — changes to output format, section names, or file structure in the producer may break the consumer's parsing.

**Quick check:** Read both files and verify the consumer's parsing references (section names, file extensions, expected fields) match what the producer now generates. In this session, execute was already ahead (the two-file format originated there), so no update was needed — but the check itself prevents silent contract drift.

## Branch-Based Batch Import for Bidirectional Sync

When two repos evolve independently and sync via tarball (e.g., one side can't push to the other's remote), extract the tarball onto a temporary branch and merge into main instead of overwriting the working tree. Git's 3-way merge uses the previous import commit as the merge base, so files changed on only one side merge cleanly and conflicts surface naturally.

```bash
git checkout -b batch-import
tar xzf <tarball> -C .
git add -A && git commit -m "batch import $(date +%Y-%m-%d)"
git checkout main && git merge batch-import
git branch -d batch-import
```

**Why branch+merge over direct extraction:** Direct `tar xzf` into the working tree clobbers local changes to shared files. The branch approach preserves both sides' edits and only requires manual resolution when both sides touched the same file.

## Cross-Refs

No cross-cluster references.
