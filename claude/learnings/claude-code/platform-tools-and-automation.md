Claude Code tool behavior and automation — @ references, cron patterns, polling cost, file operation prerequisites, symlink resolution, and GitHub API patterns.
- **Keywords:** @ reference, cron, polling, /loop, TaskOutput, symlink, Glob, Read before Write, GitHub API, WebFetch, parallel tool call, CLAUDE.md auto-loading
- **Related:** none

---

> Cross-reference: For worktree-specific permission mismatches, see `platform-permissions.md` § "Worktree Isolation Creates Permission Mismatches".
> Cross-reference: For Task tool isolation mechanics, see `platform-worktrees-and-isolation.md` § "Task Tool: isolation: worktree Limitations".

## Cron and Polling Patterns

1. **Cron iterations share the parent session's context.** Unlike `claude --print` (truly stateless), cron-fired prompts run in the same REPL session. Conversation state, session variables, and tool permissions persist across firings. Use session state for cron-scoped data — no files needed.
2. **LLMs cannot reliably infer wall-clock time.** For time-dependent logic (staleness checks, timeouts), always use `date -u +%s` to get the current epoch. Never estimate time from conversation context or message timestamps — the math will be wrong.
3. **Quick-exit `per_page=5` can miss concurrent comments.** Multiple comments from the same review submission share the same `created_at` timestamp. If the quick-exit returns 5 comments and a 6th exists at the same timestamp, it's silently dropped. Always do a full incremental fetch after detecting new activity.

## Use TaskOutput, Not Bash, to Check Background Bash Tasks

When monitoring background Bash commands launched with `run_in_background: true`, always use the `TaskOutput` tool — never fall back to ad-hoc Bash commands (like `tail`, `grep`, or `cat` on output files under `/private/tmp/`). Note: `TaskOutput` only works for background Bash tasks — for background Agent tasks, rely on the automatic notification system (see `multi-agent-patterns.md` § "TaskOutput Only Works for Background Bash Tasks").

**Why:**
- `TaskOutput` with `block: false` gives a non-blocking status check — no Bash permissions needed
- `TaskOutput` with `block: true` and a timeout waits for completion cleanly
- Ad-hoc Bash commands on output files require Bash permission patterns that aren't typically pre-configured, causing repeated permission prompts

## WebFetch Cannot Parse PDF Files

`WebFetch` returns raw binary for PDFs — it can't extract text. The `Read` tool supports PDFs natively but requires `poppler-utils` (`brew install poppler`). If poppler isn't available, find text conversions via web search (gists, blog summaries, markdown conversions) as a fallback.

## Always `Read` Before `Write`

The Write tool requires a prior `Read` attempt on the target file — `Glob` doesn't satisfy this prerequisite. For new files: `Read` (gets "file does not exist" error) → `Write`. For existing files: `Read` → `Edit`.

## Subagent Reads Don't Satisfy Main-Thread Edit Prerequisites

When a Task subagent reads a file, that Read does NOT count for the main thread's Edit/Write prerequisite check. The main thread must `Read` the file itself before calling `Edit` — even if a subagent already read and analyzed the file's contents. This commonly surfaces when subagents evaluate skills/files in parallel and the orchestrator then tries to bulk-edit based on their findings.

**Recovery:** After subagent analysis, batch the required `Read` calls for files you need to edit, then proceed with edits.

## Parallel Tool Call Error Cascade

When multiple tool calls are sent in a single batch and one fails, all sibling calls in the same batch fail with `"Sibling tool call errored"` — regardless of whether they would have succeeded independently. The failing call's error is reported normally; the siblings get a generic cascade error.

**Recovery:** Identify which calls actually failed vs which were cascade victims. Retry the valid calls individually or in a new batch (without the failing call).

## `~/.claude` Symlink Structure

`~/.claude` is a real directory on disk. Key subdirectories (`commands/`, `guidelines/`, `learnings/`, `lab/`) are **directory-level symlinks** to the dotfiles repo (e.g., `commands -> /Users/<user>/WORKSPACE/dotfiles/.claude/commands`). Edits to files under these paths land in the repo automatically — no separate copy step needed.

Other entries (e.g., `CLAUDE.md`, `settings.json`) are individually symlinked. Non-dotfiles content (`history.jsonl`, `debug/`, `cache/`) lives directly in `~/.claude/` as real files.

## Glob Limitations with Symlinks

Glob can silently return empty results in two cases: (1) untracked files in directories, and (2) paths through directory symlinks. Since `~/.claude` subdirectories are symlinks, `Glob(path: "/Users/<user>/.claude")` returns empty while `ls` finds files. Fall back to `Bash` `ls` when searching inside symlinked directory trees. Verify claims about file existence/absence with `ls` before stating files don't exist.

## Sanitizing Examples: Preserve Pedagogical Intent

When scrubbing personal details from learning examples, use generic placeholders (`/Users/<user>/`) rather than replacing with the "correct" form (`~/.claude`). If the learning demonstrates that absolute paths fail, replacing the example with a tilde path removes the demonstration of the failure. Match the placeholder to the role the value plays in the example.

## `/loop` + Review Skill for Async PR Babysitting

`/loop 1m /git:address-request-comments` creates a recurring cron job that polls a PR for new review comments every minute. Useful when waiting for reviewer feedback — the agent fetches, categorizes, and replies to comments automatically, then presents actionable suggestions for approval.

Key details:
- Uses `CronCreate` with `recurring: true`; auto-expires after 3 days
- Incremental fetches via `?since=<timestamp>` avoid reprocessing old comments
- Stop with `CronDelete` when done
- The agent replies on the platform first, then posts suggestion summaries as PR comments (not CLI prompts)

## @ References Only Resolve in CLAUDE.md and SKILL.md

`@path/to/file.md` references are resolved by the CLI at load time — not by the agent or the Read tool. They work in CLAUDE.md and SKILL.md only. Data files (personas, reference docs, learnings) cannot use `@` — the agent must explicitly Read them.

**Path resolution styles** (empirically verified 2026-03-13):

| Style | Example | Works? |
|-------|---------|--------|
| CWD/project-root relative | `@.claude/learnings/foo.md` | ✅ Yes |
| Tilde expansion | `@~/.claude/learnings/foo.md` | ✅ Yes |
| Relative traversal | `@../../learnings/foo.md` | ❌ No |
| Skill-directory relative | `@sibling.md` (from SKILL.md) | ❌ No |

CWD-relative and tilde work consistently across repos. CWD-relative fails cross-repo when the target doesn't exist relative to the other project's root.

**Three-layer path resolution model:**

| Layer | CWD-relative | Tilde | `../../` | Sibling |
|-------|-------------|-------|----------|---------|
| **`@` reference (CLI)** | ✅ | ✅ | ❌ | ❌ |
| **Read tool (direct)** | ✅ | ✅ | ❌ | ❌ |
| **Agent (manual expansion)** | ✅ | ✅ | ✅ | ✅ |

The agent layer works because the CLI injects a "Base directory for this skill" header. Agents resolve relative paths against this base directory, then pass the absolute path to Read. See `path-resolution.md` guideline.

**Session-level dedup:** The CLI deduplicates `@` references within a session — only the first load of a given file triggers a Read. Use a file not yet loaded when testing.

## GitHub API: Edit PR Review Comment Endpoint

The endpoint for editing a pull request review comment is `pulls/comments/{comment_id}` — NOT `pulls/{number}/comments/{comment_id}`. The PR number is not in the path.

```bash
gh api repos/{owner}/{repo}/pulls/comments/<comment_id> -X PATCH -F body=@.gh-reply.tmp
```

Using the wrong path (`pulls/<number>/comments/<id>`) returns a 404.

## Setup Scripts Must Track Symlink Target Changes

When a file moves within the repo (e.g., `CLAUDE.md` from root to `.claude/CLAUDE.md`), update the setup script's symlink list. The symlink at `~/.claude/` will still point to the old location, causing silent breakage on fresh installs. The fix is mechanical (add to ITEMS list) but easy to forget — the existing install works fine because the symlink was updated manually.

## Use `--body-file` for `gh pr create` to Avoid Permission Prompts

HEREDOC content with quoted strings in `gh pr create --body "..."` triggers permission prompts on every line. Write the body to a temp file and use `--body-file` instead:

```bash
# Write body via Write tool to tmp/change-request-replies/pr-body.md, then:
gh pr create --base main --title "title" --body-file tmp/change-request-replies/pr-body.md
rm -rf tmp/change-request-replies
```

Same pattern works for `gh pr edit --body-file`. The `tmp/change-request-replies/` directory is already used for comment replies in `github-commands.md`.

## Test Skills for Empirical CLI Behavior Verification

Create a throwaway skill under `.claude/commands/test-<topic>/SKILL.md` to test CLI behaviors that can't be verified by reading code (e.g., `@` reference parsing, permission resolution, skill discovery). The skill body describes the test, and invoking it via `/test-<topic>` exercises the real CLI loader. Delete after testing. Useful when documentation is ambiguous or absent — the CLI's behavior is the ground truth.

## GitHub Reviews API: Single Payload with Inline Comments

`POST /repos/{owner}/{repo}/pulls/{number}/reviews` accepts a JSON payload with both a review summary (`body`) and an array of inline comments (`comments[]`). Each comment specifies `path`, `line`, `side`, and `body`. This avoids N+1 API calls (one per comment). Use `gh api --input file.json` to post — write the payload to a temp file to avoid shell quoting issues with complex JSON.

## Polling Loop Token Cost

Each `/loop` invocation of a skill costs ~4-5K tokens minimum even on no-op runs — skill instructions (~3K) + platform detection ref (~500) + API calls (~200) + response (~50). At 3-minute intervals, that's ~80-100K tokens/hour for confirming nothing changed. Factor this into interval selection: use 10m+ for review polling unless rapid response is needed.

## CLAUDE.md Auto-Loading Is Scoped to Project CWD Tree

CLAUDE.md auto-loading only works within the project directory hierarchy — parent directories at launch (upward walk), subdirectories on demand when the agent reads a file there (downward discovery). Directories outside the CWD tree (e.g., `~/.claude/learnings/xrpl/`) do **not** auto-load their CLAUDE.md when an agent reads files there. Glob and Grep do not trigger auto-loading either.

For learnings cluster CLAUDE.md files: rely on the search pipeline to load them explicitly (the `context-aware-learnings` guideline says "read cluster CLAUDE.md files when the cluster is relevant"). Don't assume the platform handles it.

## Cross-Refs

No cross-cluster references.
