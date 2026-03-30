Multi-agent file coordination — worktree commit/merge, staging directories, sandbox workarounds, extractor-writer pattern, and conflict prevention.
- **Keywords:** worktree, cherry-pick, staging directory, extractor-writer, sandbox, file overlap, orchestrator-agent split, subagent write limitation, lifecycle scripts
- **Related:** none

---

## Coordinating Interface Changes Across Parallel Subagents

When removing a parameter/prop from many modules using parallel subagents, each agent must update **both** the module's interface and any call sites within the same file.

**The Problem:** Agent A removes `config` from `ModuleX`'s interface. Agent B removes `config` from `ModuleY`'s interface. But `ModuleX` calls `ModuleY(config)` — if Agent A doesn't also update that call site, the build breaks because `ModuleY` no longer accepts `config`.

**The Rule:** Each subagent should:
1. Remove the parameter from the module's interface/signature
2. Remove the parameter from internal destructuring/usage
3. Add the replacement (e.g., context lookup, import) inside the module
4. **Update all call sites within that file** where the callee is also being refactored

**Execution Order:** Leaf modules first (no callees to update), then mid-level (update own interface + fix leaf call sites), then top-level entry points last.

## Sandbox Workaround: Lifecycle Scripts for Out-of-Directory Operations

Task tool subagents are sandboxed to the project directory. They cannot create directories, write, or edit files outside the project root. For skills that need to operate in a git worktree (outside project root), create a single lifecycle shell script with subcommands (create, attach, write, read, delete, commit, remove) and pre-approve it:

```
Bash(bash ~/.claude/commands/<skill-name>/worktree-lifecycle.sh:*)
```

Key design decisions:
- Use heredoc redirect syntax (`bash ... write ... <<'DELIM'`) so the command starts with `bash` and matches the permission pattern
- Single permission entry covers all operations
- Auto-cleanup of stale worktrees in create/attach subcommands
- Every filesystem operation the agent might need (CRUD) must have a corresponding subcommand — without `read`, agents resort to fragile `git show branch:path`; without `delete`, agents cannot clean up probe/test files before committing

## Standardize Worktree Agent Commit Behavior

Tell worktree agents explicitly: **"Do NOT commit your changes — leave them unstaged."** This ensures a single extraction path (`git diff > patch && git apply`) for every agent. Mixed commit behavior (some commit, some don't) forces the orchestrator to check each worktree individually and use different extraction methods.

If an agent does commit despite instructions, fall back to `git cherry-pick`. But the goal is to eliminate this branch entirely.

## Worktree Agent Verification: Full Lint Stack

Every worktree agent's verification step should run the **full** lint stack, not just pytest:
```bash
poetry run pytest --tb=short
poetry run ruff check
poetry run ruff format --check
poetry run pyright .
```
Skipping lint/format in agents causes issues to accumulate at the end, requiring multiple fix-commit cycles in the main worktree.

## Worktree Agent Merge: Check Commit State Before Extracting

Worktree agents may or may not commit their changes — check both `git log` and `git status` in the worktree before extracting. Uncommitted changes need `git diff > patch && git apply`, while committed changes need `git cherry-pick`. Mixing up the extraction method produces empty patches or missed changes.

**Pattern:**
```bash
git log origin/main..HEAD --oneline   # new commits?
git status --short                     # unstaged changes?
# Uncommitted → git diff > patch && git apply
# Committed   → git cherry-pick <sha>
```

## Cross-Agent File References Need Orchestrator Verification

When parallel agents each create files that *reference each other* (paths, function calls, shared IDs), no individual agent can verify the integration seams — each only sees its own output. Distinct from the "interface changes" pattern (agents editing shared code): here agents create independent files with cross-references baked into strings and paths.

**Fix:** After all agents complete, the orchestrator must verify integration points: file paths match, shared constants agree, argument signatures align. Budget time for this — agents produce correct structure but wrong cross-references (e.g., `$SCRIPT_DIR/validate.sh` vs `$SCRIPT_DIR/seed/validate.sh`).

## Subagents Cannot Write .md Files

The Write tool blocks documentation file creation (`.md`, `README`) unless explicitly requested by the user. Background agents can't get user approval, so they silently fail. This is a systemic blocker for skills like `explore-repo` where agents produce `.md` output files.

**Workarounds (in preference order):**
1. **Pre-create directories + resume pattern**: Orchestrator creates output directories (`mkdir -p docs/learnings`) *before* launching agents. If agents still fail on Write (permission prompt they can't answer), resume them after the user approves the first write — agents retain their full analysis context, so the resume only costs 1 tool call per agent. This avoids re-doing all analysis work.
2. Have the orchestrator write files instead of delegating writes to subagents
3. Use Bash (`cat <<'EOF' > file.md`) in the agent — may also be blocked but worth trying
4. **Transcript extraction pattern**: after blocked agents complete, launch extraction agents that read the transcript output files (chunked `Read` with offset/limit) and write the actual files from orchestrator context

**Resume pattern details**: When N agents fail on Write, resume all N in parallel — each retains full analysis context, so the resume costs only 1 Write call per agent (observed: ~60-90s vs ~200-370s for fresh scans). The transcript extraction pattern (option 4) doubles agent count but recovers from permission failures; launch extractors in parallel to minimize wall-clock time.

## Extractor-Writer Subagent Pattern

For bulk data processing (e.g., extracting learnings from 460 MRs), split into two subagent roles:

1. **Extractors** (N parallel): Each processes one item (MR, file, etc.), fetches its own data, returns structured output. Research-only — no file writes.
2. **Writer** (1 sequential): Receives all extractor outputs concatenated, reads existing files, deduplicates, classifies, and writes updates.

**Why separate:** Extractors run in parallel and absorb raw data noise (API responses, discussion threads) that would pollute the main context. The writer handles dedup coherently because it sees all extractions at once + all existing content. Main context becomes pure orchestration: fetch metadata → spawn extractors → spawn writer → update progress.

**Context cost:** Subagent results still flow back to main context as messages. System reminders also echo back every file edit the writer makes. Minimize by having the writer do fewer, larger writes (full file rewrites) rather than many small edits.

## Split Writers by Output Location for Parallelism

When a batch workflow writes to independent file sets (e.g., project-specific learnings vs global learnings), split into parallel writer subagents — one per location. Each writer reads and deduplicates only against its own files. Cuts writer wall-clock time roughly in half since the bottleneck is reading existing files + processing.

## Staging Directory Pattern for Out-of-Project Writes

Background agents cannot write to paths outside the project directory — this is a hardcoded restriction that no permission pattern can override. When agents need to produce files destined for external locations (e.g., `~/.claude/learnings/`), have them write to a staging directory inside the project instead. The orchestrator then copies staged files to their final locations in foreground, where the restriction doesn't apply.

Pattern: agent reads from real location (dedup), writes to `docs/learnings/_staging/<scope>/`, orchestrator runs `cp` + `rm -rf` after all agents complete. The staging files are also visible in `git status` before being applied, enabling review.

## Pre-Read External Files Before Launching Agents

Agents inherit the parent session's permission scope. Files outside permissioned directories (e.g., `~/Downloads/`) cause silent failures — agents complete analysis but can't read the inputs. When launching agents that need files from outside the workspace, read the files yourself first and pass the content in the agent prompt. The analysis is the expensive part; providing input content is cheap.

## Orchestrator/Agent Split for Multi-Step Skills

Split SKILL.md into two files when a skill has a multi-step background workflow:
1. **Orchestrator (SKILL.md)** — User interaction only: identifying items, displaying for selection, gathering input. Target ~80 lines. List reference files as conditional (no eager `@`).
2. **Background agent steps (separate .md)** — Autonomous workflow executed by a Task agent. Use aliases at top, decision tables for branching, inline warnings at point of use, error recovery at bottom.

## Full Write > Incremental Edit for Content-Aware Merges

When merging diverged files with many structural changes (new sections, reordered content, genericized examples), a full `Write` is more reliable than many incremental `Edit` calls. Incremental edits can create duplication artifacts — e.g., a section gets inserted inside an existing code block, or an edit's context match lands in the wrong location after prior edits shifted content.

**Recovery pattern:** If an agent detects duplication after incremental edits (by reading the file back), it should abandon the edit approach and do a full `Write` with the correct merged content. This self-correction is cheaper than debugging cascading edit failures.

## File Overlap as Parallel Conflict Predictor

When independent work items (issues, tasks) could run in parallel, check for file overlap before launching. Issues that touch the same files (e.g., two terminology sweeps both editing persona files) cause merge conflicts in parallel worktree agents. Options: pre-filter conflicting items into sequential batches, accept conflicts and resolve post-merge, or group by file domain and run groups sequentially. File overlap analysis is cheap (grep issue bodies for mentioned paths/patterns) and prevents the most common parallel failure mode.

## Background Agents Can Commit Foreground Changes

When a background agent shares a working tree with the foreground session, `git add` in the background agent stages whatever is on disk — including uncommitted foreground edits. If the background agent commits, foreground changes get bundled into the background commit with its unrelated message. The foreground session then sees its files as "already committed" with no diff against HEAD. Mitigation: use `isolation: "worktree"` for background agents that will commit, or ensure the foreground commits its changes before launching background work on the same files.

## Reuse Existing Worktrees Instead of Creating New Ones

When sweep skills need worktrees for PR branches, check `git worktree list` first. Prior sweeps (review, work-items) often leave worktrees checked out to the same branches. Reusing avoids "branch already used by worktree" errors and skips creation/cleanup overhead. Only create new worktrees for PRs without existing ones; only clean up worktrees the current run created.

## Propagate Persona to Subagent Sessions

When launching `claude -p` sessions that will invoke domain-specific skills (addressing review comments, implementing features), include a `set-persona` invocation in the prompt based on the PR's domain. Auto-detect from PR title, branch name, and changed file paths. This gives the subagent the right domain lens (priorities, gotchas, proactive loads) without manual intervention.

## Agent Worktree Isolation for Active-Branch PRs

`git worktree add` can't check out a branch already checked out in another worktree. For sweep addressing of PRs on the director's active branch, use `Agent(isolation: "worktree")` — it creates a temporary worktree, the agent addresses findings and pushes, then the worktree is cleaned up. This is ad-hoc (not integrated into `let-it-rip.sh`) but reliable. The agent gets a full isolated copy and can invoke skills normally.

## Cross-Refs

- `~/.claude/skill-references/subagent-patterns.md` — universal subagent patterns (output verification, intermediate files, structured templates)
- `~/.claude/learnings/claude-code/multi-agent/director-patterns.md` — director-layer patterns including active-branch workaround
