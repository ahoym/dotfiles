Claude Code permission system — Bash prefix matching, Read/Write/Edit pattern gotchas, settings merge, worktree permission mismatches, and .claude/ path protection.
- **Keywords:** permissions, Bash prefix matching, settings.json, settings.local.json, Write permission, Edit permission, .claude/ protection, helper scripts, worktree permission mismatch, deny precedence, deny-first, allow override, filesystem deny, personal directories, colon separator, glob boundary, shell glob sandbox
- **Related:** none

---

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
4. **Quoted strings trigger prompts regardless of allow patterns.** Even with `Bash(gh api:*)` in the allow list, `gh api 'url?param=val'` or `gh api "url?param=val"` triggers a permission prompt. The permission system appears to treat the full command including quotes as the match target. Workaround: avoid quotes entirely — use `--paginate` instead of `?per_page=100`, filter client-side with `--jq` instead of `?since=`, and use `-f` flag for string values instead of quoting. For standalone `jq` filters that need string comparisons (e.g., timestamp filtering), use `jq --arg varname 'value'` to pass values as variables (`$varname` in the filter) instead of embedding double-quoted string literals in the jq expression.
5. **`&&` chaining:** `git add . && git commit -m "msg"` in a single Bash call can trigger rejection because the combined command doesn't match simple patterns like `Bash(git add:*)`. Run each command as a separate Bash call.
6. **Inline `$()` subshells:** `git log ^$(git merge-base HEAD main)` doesn't match simple patterns. Split into two calls — store the subshell result in a variable from one Bash call, use it in the next. Applies to any command where `$()` is embedded in arguments.
7. **`python3 -c` for JSON parsing:** `python3 -c "import json; ..."` triggers permission prompts because of quoted strings. Use `jq` instead — it's auto-permitted and handles the same tasks. When passing API output to subagents, prefer passing raw JSON directly rather than parsing in the main context at all.
8. **Shell redirects break pattern matching.** `Bash(date:*)` matches `date -u +%s` but NOT `date -u +%s > file` — the redirect makes it a different command string. Fix: use separate tool calls (Bash for computation, Write/Edit for file I/O) instead of shell redirects.
9. **`:` is the glob boundary, not `/`.** `*` after `/` only matches within that path segment (like filesystem globs). `*` after `:` matches the entire remaining command string including `/` characters. `Bash(rm tmp/change-request-replies/*)` fails for `rm tmp/change-request-replies/foo.md` — use `Bash(rm tmp:*)` instead. Same applies to `ls`, `mkdir`, and any command with path arguments.
10. **Sandbox blocks shell globs in destructive commands.** `rm tmp/change-request-replies/34-*` is rejected with "Glob patterns are not allowed in write operations" regardless of permission patterns. Must list files explicitly — but see #9 for the permission pattern that allows it.

## Write/Edit Permission Pattern Gotchas

Write and Edit permission patterns use a different matching mechanism than Bash prefix matching. Gotchas specific to these tools:

1. **Tilde vs absolute paths:** Permission patterns like `Write(~/**/tmp/change-request-replies/**)` require the tool call to use `~/...` paths. Passing the expanded absolute path (`/Users/<user>/...`) won't match the tilde-based pattern.
2. **Symlink CWD-relative normalization:** When `~/.claude` is a symlink (e.g., to `WORKSPACE/dotfiles/.claude`) and CWD is the symlink target, Write/Edit tools may normalize `~/.claude/...` paths through the symlink to CWD-relative (`.claude/...`) before the permission check. Tilde-based patterns like `Edit(~/.claude/skill-references/**)` won't match the normalized path. Fix: add CWD-relative companion patterns (e.g., `Edit(.claude/**)`) alongside tilde patterns when working in symlinked repos.
3. **Edit tool displays as `Update` in permission prompts.** The tool is called `Edit` in code, but the permission prompt shows `Update(.claude/...)`. `Edit(...)` patterns do NOT match `Update` prompts — they are different permission keys. Fix: add `Update(...)` companion patterns for every `Edit(...)` pattern.
4. **Write tool `file_path` requires absolute or `~/` paths** per its spec, but permission patterns may use CWD-relative. In symlinked repos, Write normalizes paths unpredictably — prefer Bash for simple file writes (e.g., epoch timestamps) and reserve Write for content files where CWD-relative patterns are pre-configured.
5. **`replace_all: true` on Edit replaces ALL occurrences in the file** — not just in the target section. When a variable name appears in both definition and usage sections, use targeted `replace_all: false` edits to avoid collateral damage.

## `claude -p` Permission Resolution Differs from Interactive

Permission patterns that match in interactive sessions may silently fail in `claude -p`. Empirically observed: `Write(~/**/tmp/change-request-replies/**)` matched interactively (all three path forms: CWD-relative, tilde, absolute) but failed in `claude -p` for the same CWD and settings. Adding the full RWEU set (Read/Write/Edit/Update) for the same glob pattern resolved the failure — suggesting `claude -p` may require the complete permission set for a directory before any individual operation matches.

**Diagnostic:** When a `claude -p` session gets denied on a Write, check whether companion Read/Edit/Update patterns exist. Add the full set rather than debugging individual patterns.

**Test pattern:** `echo "<instruction>" | claude -p --verbose --output-format stream-json 2>&1 | grep '"file_path"'` — shows the actual path the model used, confirming the denial isn't a path-form mismatch.

## `.claude/` Directory Protection

Claude Code has built-in protection for a project's `.claude/` directory that triggers permission prompts on Edit/Write regardless of permission patterns in `settings.json`. Not configurable via permission patterns, `settings.local.json`, or auto-accept mode.

**Scope:** Project-scoped, not global. Sessions in other repos can write to `~/.claude/` paths via normal permission patterns without prompting.

**Skill bypass:** Skills with `allowed-tools: [Write, Edit]` in SKILL.md frontmatter bypass the guard entirely — Write/Edit to `.claude/` paths auto-allow. This is why `/learnings:compound` works without prompting.

**Workaround for dotfiles repos:** Store config files in a non-`.claude` directory (e.g., `claude/`) and symlink individual items into `~/.claude/`. The tilde-based permission patterns (`Edit(~/.claude/commands/**)`) then work normally because the real files aren't under a project `.claude/` path.

**Symlink caveat:** Tilde permission patterns don't resolve through symlinks. If `~/.claude/commands` is a symlink to `/path/to/dotfiles/.claude/commands`, the pattern `Edit(~/.claude/commands/**)` sees the symlink path but the tool resolves to the real path — they don't match. Moving files out of `.claude/` fixes both issues at once.

**Remaining friction:** Only affects ad-hoc direct Write/Edit calls during dotfiles sessions. For any repeatable workflow, wrapping it in a skill with `allowed-tools` eliminates the prompts.

## Deny-First Precedence Is Absolute (Empirically Verified 2026-03-29)

Deny rules **always win** over allow rules regardless of specificity. A deny on `Read(//$HOME/**)` blocks `Read(//$HOME/.claude/**)` and `Read(//$HOME/WORKSPACE/**)` even when those are explicitly in the allow list. Tested across `~` and `//` syntaxes — same result.

**Implication:** You cannot "deny broad, allow narrow" for filesystem access. To protect personal directories while allowing code/config access, deny each personal directory individually:

```json
"deny": [
  "Read(~/Applications/**)", "Read(~/Desktop/**)", "Read(~/Documents/**)",
  "Read(~/Downloads/**)", "Read(~/Library/**)", "Read(~/Movies/**)",
  "Read(~/Music/**)", "Read(~/Pictures/**)", "Read(~/Public/**)"
]
```

The `sandbox.filesystem.denyRead` + `allowRead` arrays may offer allow-overrides-deny at the sandbox level (the schema says allowRead "takes precedence"), but this is untested.

## Settings File Merge Behavior

`settings.json` (project) and `settings.local.json` (local) **merge additively** for permission arrays. Duplicating patterns across both is harmless but redundant. Precedence (highest → lowest): managed → CLI args → `settings.local.json` → `settings.json` → `~/.claude/settings.json`. Deny at any level cannot be overridden by allow at another.

## Scoping Bash Permissions: Helper Scripts

When a skill needs Bash commands that don't match existing patterns, wrap them in a helper script and pre-approve just that script:

```bash
#!/usr/bin/env bash
# worktree-commit.sh — wraps git operations for permission scoping
git -C "$1" add -A && git -C "$1" commit -m "$2"
```

Permission: `Bash(bash ~/.claude/commands/<skill>/worktree-commit.sh:*)` — any arguments, without exposing broad `git -C` permissions.

**Anti-pattern: `Bash(bash:*)`** matches ANY `bash` command including `bash -c '<anything>'` — agents discover this bypass when commands are auto-denied. Always scope with path: `Bash(bash ~/.claude/commands/<skill>/lifecycle.sh:*)`.

## `claude -p` `--allowedTools` Needs Edit for File Updates

`Write` creates files but `Edit` is needed to update them. When `claude -p` sessions write a file (e.g., `status.md`) then update it at milestones, `--allowedTools` must include both `Write(path/**)` and `Edit(path/**)`. Missing the Edit pattern causes silent permission failures — the session creates the file but can't modify it afterward.

**Checklist for `--allowedTools`:** For every `Write(...)` pattern where the session will modify files after creation, add a matching `Edit(...)` pattern.

## Cross-Refs

No cross-cluster references.
