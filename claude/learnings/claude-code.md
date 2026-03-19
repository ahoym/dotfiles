# Claude Code

## Task Tool: `isolation: "worktree"` Limitations

The `isolation: "worktree"` parameter on the Task tool creates a git worktree from the **HEAD commit** of the current branch with an auto-generated branch name (e.g., `worktree-agent-a41c89bc`). There is no way to:

- Specify a base ref (e.g., branch from another agent's branch instead of HEAD)
- Control the branch name (e.g., `feat/plan-slug/agent-name`)

**Critical distinction:** The worktree is created from the HEAD **commit**, not the working directory state. Unstaged/uncommitted files in the working tree are NOT included in the isolated worktree. If Agent A writes files to the shared working tree and Agent B launches with `isolation: "worktree"`, B's worktree won't have A's files unless A's work was committed first.

**Workaround for dependency files:** Agents can cherry-pick from a dependency's pushed branch as their first step: `git cherry-pick main..<dep-branch>`. This brings the dependency's commits into the isolated worktree. The agent can then rename its branch (`git branch -m <desired-name>`), commit its own work, and push.

**Implication for parallel plans:** DAG-based workflows where dependent agents need worktrees based on a predecessor's branch require manual `git worktree add <path> -b <branch-name> <base-ref>`. This is why `parallel-plan/execute` uses manual worktree commands in Step 5 rather than `isolation: "worktree"`.

## No Mid-Flight Messaging to Background Agents

There is no mechanism to send messages, corrections, or updates to a running background agent. The only interaction points are:

- **Before launch:** The prompt (all context must be provided upfront)
- **During execution:** `TaskOutput` is read-only (status check only)
- **After completion:** `resume` parameter on Task tool continues from where the agent left off

**Implication for discovery propagation:** In fan-out DAGs where all agents launch simultaneously, discoveries from early completers cannot be injected into still-running agents. Treat discoveries as post-execution documentation, not runtime corrections. The only way to act on a discovery mid-execution is to wait for the affected agent to complete, then resume it with corrective instructions.

## Skill Discovery: Sibling vs Subdirectory `.md` Files

`.md` files **next to** a `SKILL.md` (siblings) are treated as reference data — they are not discovered as separate skills. Only `.md` files in **subdirectories** of a skill folder get discovered as sub-skills (e.g., `set-persona:personas:java-backend`).

**Use this to keep data files co-located with a skill** without polluting the skill list. For example, persona definitions or template files can live as siblings of `SKILL.md` and be read by the skill at runtime without appearing as individual invocable skills.

Verified empirically: moving `personas/*.md` up to sit next to `SKILL.md` removed them from the skill list while keeping the main `set-persona` skill functional.

## Permission Rules: `Read()` Covers Glob and Grep

Glob/Grep operations show as `Search(...)` in prompts but the correct allow rule uses **`Read`**, not `Search` or `Glob`.

**Path syntax** (gitignore conventions): `Read(~/path)` (home-relative), `Read(//absolute/path)` (absolute, note double slash), `Read(/relative/path)` (settings-file-relative), `Read(path)` (CWD-relative).

**Example** — auto-allow Glob/Grep under `~/.claude/`:
```json
"permissions": {
  "allow": [
    "Read(~/.claude/learnings/**)",
    "Read(~/.claude/commands/**)"
  ]
}
```

## Background Bash Agents Lack Permissions for File Operations

When using `Task` with `subagent_type: "Bash"` and `run_in_background: true`, the agent typically cannot execute file-writing commands (cp, mkdir, heredoc redirects) because Bash permissions aren't pre-configured for those patterns.

**Workaround:** For file copy/create operations, do them directly in the main thread using Bash, Write, or Edit tools instead of delegating to background Bash agents. Background agents are better suited for long-running processes where the specific Bash commands have pre-configured allow patterns.

### Background Agent Diagnostic Sequence

When a background agent fails silently, follow this sequence:
1. Check if the specific command has a matching allow pattern in settings
2. Test with a simple command that IS in the allow list to isolate permission vs platform issues
3. If the simple command works — missing allow pattern for the specific command
4. If the simple command also fails — escalate as a potential platform issue

The most common cause is a missing Bash allow pattern, not a platform limitation.

## Permissions Are Cached at Session Start

Changes to `settings.json` or `settings.local.json` mid-session are **not picked up** by background agents or the current session. This applies to both project-level and local settings files.

**Impact:** Adding a permission mid-session then launching background agents → agents silently fail with "Permission denied."

**Fix:** Add all required permissions **before** starting the session. If you discover missing permissions mid-execution, add them and restart the session.

### Skill Prerequisites Pattern

Skills requiring Bash commands should document permission patterns in a `## Prerequisites` section. Permission changes must be **committed** to take effect reliably — uncommitted changes may work in the current session but won't persist.

## Worktree Isolation Creates Permission Mismatches

Edit/Write permission patterns like `Edit(~/.claude/commands/**)` resolve to absolute paths. Agents in worktrees edit files at `<worktree>/commands/...` — a different path that doesn't match.

**When to skip worktrees:** Agents have disjoint file scopes (no conflict risk) and no build/test isolation needed. Especially mechanical edits (YAML, markdown).

**When worktrees are needed:** Code tasks with `tsc --noEmit` or build steps where parallel agents would see each other's half-written files.

**Skill tool in worktrees:** Skills write to `~/.claude/` paths by convention, which resolves to the main repo — not the worktree. Autonomous agents in worktrees that need compound-style behavior should inline the methodology (Read/Edit/Write directly) rather than invoke the Skill tool. This also avoids: hook restrictions on the Skill tool, AskUserQuestion calls with no user present, and ~120 lines of skill context loaded per invocation.

## Bash Permission Prefix Matching Gotchas

Bash permission patterns match on the **literal command prefix**. Common breaks:

1. **`cd &&` prefix:** `cd /tmp/worktree && git add .` starts with `cd`, not `git` — won't match `Bash(git add:*)`. Fix: use `git -C <dir>` instead.
2. **`git -C` prefix:** `git -C ../worktree push` doesn't match `Bash(git push:*)` because `-C` comes before `push`. Workaround: push from main repo — `git push origin <branch>` works for worktree commits (shared object database).
3. **Tilde expansion:** Background agents may expand `~` to `/Users/...`, breaking `Bash(bash ~/.claude/...:*)`. Always pass `~` literally — the shell expands at runtime, permission checks the literal text.
4. **Quoted strings trigger prompts regardless of allow patterns.** Even with `Bash(gh api:*)` in the allow list, `gh api 'url?param=val'` or `gh api "url?param=val"` triggers a permission prompt. The permission system appears to treat the full command including quotes as the match target. Workaround: avoid quotes entirely — use `--paginate` instead of `?per_page=100`, filter client-side with `--jq` instead of `?since=`, and use `-f` flag for string values instead of quoting.
5. **`&&` chaining:** `git add . && git commit -m "msg"` in a single Bash call can trigger rejection because the combined command doesn't match simple patterns like `Bash(git add:*)`. Run each command as a separate Bash call.
6. **Inline `$()` subshells:** `git log ^$(git merge-base HEAD main)` doesn't match simple patterns. Split into two calls — store the subshell result in a variable from one Bash call, use it in the next. Applies to any command where `$()` is embedded in arguments.
7. **`python3 -c` for JSON parsing:** `python3 -c "import json; ..."` triggers permission prompts because of quoted strings. Use `jq` instead — it's auto-permitted and handles the same tasks. When passing API output to subagents, prefer passing raw JSON directly rather than parsing in the main context at all.
8. **Shell redirects break pattern matching.** `Bash(date:*)` matches `date -u +%s` but NOT `date -u +%s > file` — the redirect makes it a different command string. Fix: use separate tool calls (Bash for computation, Write/Edit for file I/O) instead of shell redirects.

## Write/Edit Permission Pattern Gotchas

Write and Edit permission patterns use a different matching mechanism than Bash prefix matching. Gotchas specific to these tools:

1. **Tilde vs absolute paths:** Permission patterns like `Write(~/**/tmp/change-request-replies/**)` require the tool call to use `~/...` paths. Passing the expanded absolute path (`/Users/<user>/...`) won't match the tilde-based pattern.
2. **Symlink CWD-relative normalization:** When `~/.claude` is a symlink (e.g., to `WORKSPACE/dotfiles/.claude`) and CWD is the symlink target, Write/Edit tools may normalize `~/.claude/...` paths through the symlink to CWD-relative (`.claude/...`) before the permission check. Tilde-based patterns like `Edit(~/.claude/skill-references/**)` won't match the normalized path. Fix: add CWD-relative companion patterns (e.g., `Edit(.claude/**)`) alongside tilde patterns when working in symlinked repos.
3. **Edit tool displays as `Update` in permission prompts.** The tool is called `Edit` in code, but the permission prompt shows `Update(.claude/...)`. `Edit(...)` patterns do NOT match `Update` prompts — they are different permission keys. Fix: add `Update(...)` companion patterns for every `Edit(...)` pattern.
4. **Write tool `file_path` requires absolute or `~/` paths** per its spec, but permission patterns may use CWD-relative. In symlinked repos, Write normalizes paths unpredictably — prefer Bash for simple file writes (e.g., epoch timestamps) and reserve Write for content files where CWD-relative patterns are pre-configured.
5. **`replace_all: true` on Edit replaces ALL occurrences in the file** — not just in the target section. When a variable name appears in both definition and usage sections, use targeted `replace_all: false` edits to avoid collateral damage.

## `.claude/` Path Protection: Project-Scoped Write/Edit Guard

Direct Write/Edit calls to paths containing `.claude/` prompt when the session's CWD is inside that `.claude/` directory (e.g., a dotfiles repo symlinked to `~/.claude/`). Not configurable via permission patterns, `settings.local.json`, or auto-accept mode.

**Scope:** Project-scoped, not global. Sessions in other repos can write to `~/.claude/` paths via normal permission patterns without prompting.

**Skill bypass:** Skills with `allowed-tools: [Write, Edit]` in SKILL.md frontmatter bypass the guard entirely — Write/Edit to `.claude/` paths auto-allow. This is why `/learnings:compound` works without prompting.

**Remaining friction:** Only affects ad-hoc direct Write/Edit calls during dotfiles sessions. For any repeatable workflow, wrapping it in a skill with `allowed-tools` eliminates the prompts.

## Settings File Merge Behavior

`settings.json` (project) and `settings.local.json` (local) **merge additively** for permission arrays. Duplicating patterns across both is harmless but redundant. Precedence (highest → lowest): managed → CLI args → `settings.local.json` → `settings.json` → `~/.claude/settings.json`. Deny at any level cannot be overridden by allow at another.

## Cron and Polling Patterns

1. **Cron iterations share the parent session's context.** Unlike `claude --print` (truly stateless), cron-fired prompts run in the same REPL session. Conversation state, session variables, and tool permissions persist across firings. Use session state for cron-scoped data — no files needed.
2. **LLMs cannot reliably infer wall-clock time.** For time-dependent logic (staleness checks, timeouts), always use `date -u +%s` to get the current epoch. Never estimate time from conversation context or message timestamps — the math will be wrong.
3. **Quick-exit `per_page=5` can miss concurrent comments.** Multiple comments from the same review submission share the same `created_at` timestamp. If the quick-exit returns 5 comments and a 6th exists at the same timestamp, it's silently dropped. Always do a full incremental fetch after detecting new activity.

## Scoping Bash Permissions: Helper Scripts

When a skill needs Bash commands that don't match existing patterns, wrap them in a helper script and pre-approve just that script:

```bash
#!/usr/bin/env bash
# worktree-commit.sh — wraps git operations for permission scoping
git -C "$1" add -A && git -C "$1" commit -m "$2"
```

Permission: `Bash(bash ~/.claude/commands/<skill>/worktree-commit.sh:*)` — any arguments, without exposing broad `git -C` permissions.

**Anti-pattern: `Bash(bash:*)`** matches ANY `bash` command including `bash -c '<anything>'` — agents discover this bypass when commands are auto-denied. Always scope with path: `Bash(bash ~/.claude/commands/<skill>/lifecycle.sh:*)`.

## Use TaskOutput, Not Bash, to Check Background Bash Tasks

When monitoring background Bash commands launched with `run_in_background: true`, always use the `TaskOutput` tool — never fall back to ad-hoc Bash commands (like `tail`, `grep`, or `cat` on output files under `/private/tmp/`). Note: `TaskOutput` only works for background Bash tasks — for background Agent tasks, rely on the automatic notification system (see `multi-agent-patterns.md` § "TaskOutput Only Works for Background Bash Tasks").

**Why:**
- `TaskOutput` with `block: false` gives a non-blocking status check — no Bash permissions needed
- `TaskOutput` with `block: true` and a timeout waits for completion cleanly
- Ad-hoc Bash commands on output files require Bash permission patterns that aren't typically pre-configured, causing repeated permission prompts

## Context Continuation Loses File Contents

When a session is continued from a compacted conversation (context overflow), **all file contents read in the prior session are lost**. The conversation summary preserves metadata (file paths, line numbers, key findings) but not the actual file text. Budget time for re-reading source files after continuation.

**Mitigation:** Capture critical landmarks explicitly in conversation (e.g., "txFailureResponse is at line 200-209 in lib/api.ts") so continuation reduces re-reading to verification rather than discovery.

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

## Subagents Receive Full CLAUDE.md Context

Subagents launched via the Agent tool receive CLAUDE.md and all `@`-referenced guidelines — including the learnings search protocol. They can search and load learnings independently via gate #1 (session start). However, persona gates (#2–3) only fire at plan mode entry and implementation start — phases subagents rarely enter. The orchestrator has better context for persona selection and should include a persona assignment in the subagent prompt for domain-specific work.

## Worktree CWD Pinning

Claude Code resets CWD to the worktree root after every Bash call — `cd` to another directory doesn't persist between calls. Within a single Bash call, `cd /path && git status` works, but the next Bash call starts back at the worktree root.

**Impact:** Cross-repo operations (e.g., committing to main from a worktree session) require either `cd && <cmd>` chains (don't match permission patterns) or `git -C` (same problem). There is no friction-free path.

**Mitigations:**
- Surface the constraint to the user before attempting cross-repo operations. See `claude/worktrees/CLAUDE.md` for the documented constraint and recommended approach.
- **Split across sessions:** Make file edits in the worktree session (Edit/Write land on disk at the main repo path), then handle git operations from a separate session rooted in the main repo — no CWD pinning, no permission friction.

## Persisted Tool Output Nests Line-Number Prefixes

When Bash output exceeds the inline limit, it's saved to a persisted file under `tool-results/`. Reading that file via Read adds a `N→` line-number prefix. If the Read result itself exceeds the limit and is persisted again, the next Read adds another prefix layer — producing `N→  N→  N→ ...` nesting that's unreadable. Always read the **original** persisted file with `offset` + `limit` parameters rather than re-reading a persisted copy of a persisted copy.

## Multi-Step Git Ops Across Repos Require `cd` on Every Call

CWD resets to the session's working directory after every Bash call — a `cd` in one call does not persist to the next. For multi-step git operations targeting a different repo (e.g., cherry-picking onto a worktree branch while CWD is the main repo), either:

1. **Chain all steps in one call**: `cd <path> && git cherry-pick <hash> && git push ...`
2. **Prefix every call with `cd <path>`**: if steps must be separate, start each Bash call with `cd <path>` — never assume CWD carried over

Failing to do this causes commands to silently run against the wrong repo. The symptom is a successful git operation on the wrong branch (e.g., cherry-pick lands on `main` instead of a feature branch).

## `.claude/` Directory Protection

Claude Code has built-in protection for a project's `.claude/` directory that triggers permission prompts on Edit/Write regardless of permission patterns in `settings.json`. This is separate from the permission system — no pattern configuration can override it.

**Workaround for dotfiles repos:** Store config files in a non-`.claude` directory (e.g., `claude/`) and symlink individual items into `~/.claude/`. The tilde-based permission patterns (`Edit(~/.claude/commands/**)`) then work normally because the real files aren't under a project `.claude/` path.

**Related:** Tilde permission patterns don't resolve through symlinks. If `~/.claude/commands` is a symlink to `/path/to/dotfiles/.claude/commands`, the pattern `Edit(~/.claude/commands/**)` sees the symlink path but the tool resolves to the real path — they don't match. Moving files out of `.claude/` fixes both issues at once.

## See also

- `~/.claude/learnings/multi-agent-patterns.md` — worktree agent isolation, sandbox workarounds, background agent orchestration (complements the permissions/platform angle here)
- `~/.claude/learnings/claude-code-hooks.md` — hooks vs permissions independence, PreToolUse as security boundary (complements the permissions cluster here)

