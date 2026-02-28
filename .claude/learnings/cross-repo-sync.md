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
