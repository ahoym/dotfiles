Cross-platform skill portability — GitHub/GitLab command unification, shared reference files, and platform detection caching.
- **Keywords:** platform unification, GitHub, GitLab, dual commands, shared references, brace-expansion, platform detection, session-stable, sweep
- **Related:** ~/.claude/learnings/claude-code/skill-platform-portability.md

---

## Dual Platform Commands for Diverged APIs

When unifying GitHub/GitLab skills, CLI commands (`gh pr create` vs `glab mr create`) can use variable substitution (`$CREATE_CMD`). API calls cannot — JSON field names (`number` vs `iid`, `body` vs `description`), query params (`direction=asc` vs `sort=asc&order_by=created_at`), and endpoint shapes diverge too much. Use side-by-side platform blocks for API calls:

```markdown
**GitHub:**
\```bash
gh api "repos/{owner}/{repo}/pulls/..." | jq '{number, ...}'
\```

**GitLab:**
\```bash
glab api "projects/:id/merge_requests/..." | jq '{iid, ...}'
\```
```

Variable tables in step 1 ("Detect platform") work well for CLI commands and flags.

## Shared Reference Files Reduce Cross-Skill Duplication

When multiple skills duplicate the same platform-specific command blocks (e.g., GitHub vs GitLab API calls), extract them into shared reference files under `~/.claude/skill-references/`. Split by platform (`github-commands.md`, `gitlab-commands.md`) so each skill reads only the file matching its detected platform — avoids loading unused commands. Don't use `@` references for these files; skills should Read selectively after platform detection.

Benefits:
- Bug fixes apply once (e.g., fixing a jq escaping issue in the shared file fixes all skills)
- New platform support added in one place
- Skills stay focused on workflow logic, not API mechanics
- Selective Read loads ~half the tokens vs auto-inlining both platforms

Pattern: skill step 1 defines variables (`$VIEW_CMD`, `$API_CMD`), shared reference uses those variables in command templates, skill steps reference sections by name.

### Session-Stable References: Skip-If-Cached Instruction Pattern

When a shared reference produces a result that's stable within a session (e.g., platform detection — the git remote doesn't change mid-session), add explicit conditional language to the instruction step: "if not already detected this session, read X and follow its logic." This enables the LLM to skip both the file read and the detection bash call on subsequent skill invocations in the same session. Saves ~200 tokens + 1 bash call + 1 file read per subsequent invocation. The reference section should use backtick-quoted paths (not `@`) with a note like "read if platform not yet detected this session."

## Skill Deduplication: Platform-Specific vs Platform-Agnostic

When a platform-agnostic skill (e.g., `address-request-comments`) supersedes a platform-specific one (e.g., `address-pr-review`), check whether the older skill is still referenced or should be removed. Keeping both causes confusion about which to invoke and risks the older one falling out of sync with improvements made to the newer version.

## Reference Platform Command Sections by Name, Don't Inline

Skills should reference sections in the platform commands file (e.g., "use **Fetch Diff** from the platform commands file") rather than inlining `gh`/`glab` commands. This keeps skills platform-agnostic — the commands file handles GitHub vs GitLab differences. Inline commands are only appropriate before the commands file is loaded (e.g., platform detection in step 0).

## Nest Platform-Specific References in Subdirectories

When reference files are platform-specific (GitHub vs GitLab), nest them in `github/` and `gitlab/` subdirectories rather than using flat prefix naming (`github-foo.md`, `gitlab-foo.md`). Benefits: shorter filenames, natural grouping, cleaner paths in skill instructions. The index file (`commands.md`) lives inside each subdirectory alongside its cluster files.

## Brace-Expansion Path Format for Platform References

Use `~/.claude/skill-references/{github,gitlab}/file.md` in skill instructions rather than "read `file.md` from `dir/github/` or `dir/gitlab/`". The brace-expansion format is a single resolvable path expression. The split format requires assembling a filename with one of two directory options — more cognitive overhead, same information.

## Sweep Both Platforms When Fixing Reference Files

When fixing a bug in a platform-specific reference file (e.g., `github/comment-interaction.md`), always check and fix the equivalent file for the other platform (`gitlab/comment-interaction.md`). Same applies to `pr-management.md` and any other paired files. The fix is often mechanical (same pattern, different CLI syntax), but skipping it guarantees drift.

## Sweep Sub-Reference Files During Restructuring

When renaming or restructuring reference file paths, sweep conditional reference files (edge-cases, re-review-mode, lgtm-verification, etc.) — not just the parent SKILL.md. These sub-references often contain inline mentions like "see the platform commands file" that also need updating. Use `grep -rn` across the entire `commands/` tree to catch all occurrences.

## Cross-Refs

- `~/.claude/learnings/claude-code/skill-platform-portability.md` — platform features, frontmatter fields, cross-platform compatibility (complements the design-pattern focus here)
