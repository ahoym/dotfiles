# Deep Research: Dynamic Context Injection Adoption

## What Is Dynamic Context Injection?

The `` !`command` `` syntax in SKILL.md runs shell commands as **preprocessing** before Claude sees the skill content. The command output replaces the placeholder inline. Claude only sees the rendered result, not the command.

```markdown
## Context
- Current branch: !`git branch --show-current`
- Uncommitted changes: !`git diff --stat`
```

**Key characteristics:**
- Runs at invocation time, before Claude's prompt is assembled
- Not cached — re-runs on every invocation (always fresh data)
- On command failure, Claude sees the raw error/stderr
- No retry logic — one shot
- Runs in the user's shell context (CWD, permissions, env vars)
- Output counts toward the skill's token budget (content-level, not metadata-level)

---

## Candidate Evaluation Framework

A good `!`command`` candidate must score well on ALL five criteria:

| Criterion | Description | Weight |
|-----------|-------------|--------|
| **Reliability** | Command rarely fails, regardless of repo state | Critical |
| **Output size** | Small, bounded output (ideally <5 lines) | Critical |
| **Always needed** | Info is used on every invocation, not just conditional branches | High |
| **Saves a step** | Without injection, Claude would run the same command as its first action | Medium |
| **Read-only** | No side effects, no mutations, no network dependencies if possible | Critical |

### Disqualifiers

- Command output could be unbounded (e.g., `git log`, `gh pr diff`)
- Command requires network access that may be unavailable or slow (e.g., `gh api ...`)
- Command only succeeds in specific states (e.g., `git diff --name-only --diff-filter=U` only works during active merge)
- Command output needs Claude's interpretation to be useful (defeats the purpose — Claude should run it itself)

---

## Skill-by-Skill Evaluation

### Tier 1: Strong Candidates (recommend adoption)

#### `git/create-pr`

| Injection | Command | Output | Score |
|-----------|---------|--------|-------|
| Current branch | `git branch --show-current` | 1 line | 5/5 |
| Existing PR check | `gh pr list --head $(git branch --show-current) --json number,url --jq 'length'` | 1 line ("0" or "1") | 3/5 |

**Recommendation:** Inject current branch name. The existing-PR check requires `gh` (network), so it's marginal — but the skill already runs `gh pr list` as one of its first steps, so pre-fetching saves a round-trip. If you're comfortable with the network dependency, inject both.

```markdown
## Context
- Current branch: !`git branch --show-current`
- Commits on branch: !`git log origin/main..HEAD --oneline 2>/dev/null | head -20`
```

Note: `git log` is bounded here with `head -20` and falls back gracefully with `2>/dev/null`.

#### `git/address-pr-review`

| Injection | Command | Output | Score |
|-----------|---------|--------|-------|
| Current branch | `git branch --show-current` | 1 line | 5/5 |

**Recommendation:** Inject current branch. Do NOT inject PR number detection (`gh pr view --json number`) because it fails when the branch has no associated PR, and the skill already handles this case gracefully in its argument parsing logic.

```markdown
## Context
- Current branch: !`git branch --show-current`
```

#### `git/resolve-conflicts`

| Injection | Command | Output | Score |
|-----------|---------|--------|-------|
| Current branch | `git branch --show-current` | 1 line | 5/5 |

**Recommendation:** Inject current branch. Do NOT inject conflicted file list (`git diff --name-only --diff-filter=U`) — it only produces output during an active merge, which is a minority of invocations (skill may be invoked to *start* a merge that produces conflicts).

```markdown
## Context
- Current branch: !`git branch --show-current`
```

#### `git/explore-pr`

| Injection | Command | Output | Score |
|-----------|---------|--------|-------|
| Current branch | `git branch --show-current` | 1 line | 5/5 |

**Recommendation:** Inject current branch. PR metadata fetch is too network-dependent and variable-sized.

```markdown
## Context
- Current branch: !`git branch --show-current`
```

#### `git/repoint-branch`

| Injection | Command | Output | Score |
|-----------|---------|--------|-------|
| Current branch | `git branch --show-current` | 1 line | 5/5 |
| Changed files | `git diff --name-only origin/main...HEAD` | Variable, typically <50 lines | 3/5 |

**Recommendation:** Inject current branch. Changed files is useful but output size varies — bound it with `head`.

```markdown
## Context
- Current branch: !`git branch --show-current`
- Changed files (vs main): !`git diff --name-only origin/main...HEAD 2>/dev/null | head -50`
```

#### `git/split-pr`

| Injection | Command | Output | Score |
|-----------|---------|--------|-------|
| Current branch | `git branch --show-current` | 1 line | 5/5 |

**Recommendation:** Inject current branch. PR metadata is fetched via `gh` and is too variable.

```markdown
## Context
- Current branch: !`git branch --show-current`
```

#### `git/monitor-pr-comments`

| Injection | Command | Output | Score |
|-----------|---------|--------|-------|
| Current branch | `git branch --show-current` | 1 line | 5/5 |
| Repo identifier | `gh repo view --json owner,name --jq '.owner.login + "/" + .name'` | 1 line | 4/5 |

**Recommendation:** Inject both. Repo identifier is small, reliable (only fails if not in a git repo, which would make the skill useless anyway), and always needed. The `gh` dependency is acceptable because this skill is inherently GitHub-only.

```markdown
## Context
- Current branch: !`git branch --show-current`
- Repository: !`gh repo view --json owner,name --jq '.owner.login + "/" + .name' 2>/dev/null`
```

---

### Tier 2: Marginal Candidates (case-by-case)

#### `git/cascade-rebase`

| Injection | Command | Output | Score |
|-----------|---------|--------|-------|
| Current branch | `git branch --show-current` | 1 line | 5/5 |
| Branch list | `git branch --list` | Unbounded | 2/5 |

**Recommendation:** Inject current branch only. Full branch list can be very long and isn't always useful (user typically provides the chain via arguments).

#### `explore-repo`

| Injection | Command | Output | Score |
|-----------|---------|--------|-------|
| Current branch | `git branch --show-current` | 1 line | 5/5 |
| HEAD commit | `git rev-parse --short HEAD` | 1 line | 5/5 |
| Project root | `git rev-parse --show-toplevel` | 1 line | 5/5 |

**Recommendation:** Strong candidate for all three. These are always needed, always reliable, always small.

```markdown
## Context
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`
- Current branch: !`git branch --show-current 2>/dev/null`
- HEAD: !`git rev-parse --short HEAD 2>/dev/null`
```

#### `learnings/distribute`

| Injection | Command | Output | Score |
|-----------|---------|--------|-------|
| Project root | `git rev-parse --show-toplevel` | 1 line | 5/5 |

**Recommendation:** Inject project root. Always needed, always small.

```markdown
## Context
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`
```

---

### Tier 3: Not Recommended

#### `git/prune-merged`

Branch listing output is unbounded. The skill doesn't benefit from pre-fetched context because its first step is already a git fetch + branch analysis that Claude needs to interpret.

#### `do-refactor-code`

No useful preprocessing. The file path comes from `$ARGUMENTS` and the analysis is entirely Claude's work.

#### `do-security-audit`

No useful preprocessing. Launches subagents, which do their own context gathering.

#### `learnings/compound`, `learnings/consolidate`, `learnings/curate`

These operate on conversation history and file corpus, not git state. No shell commands would add useful pre-context.

#### `parallel-plan/make`, `parallel-plan/execute`

Complex orchestration skills. Context comes from the plan file passed as argument, not from shell state.

#### `ralph/init`, `ralph/compare`

Minimal shell context needed. Topics come from arguments.

#### `quantum-tunnel-claudes`

Already runs `inventory.sh` as a major step, but this is too large/complex for preprocessing. The script output needs Claude's interpretation.

#### `set-persona`

No shell context needed. Persona resolution is file-based.

---

## Universal Pattern: Current Branch

**7 of 9 git skills** need the current branch name as their first piece of context. This is the single highest-value injection across the entire skill collection.

```markdown
## Context
- Current branch: !`git branch --show-current`
```

This pattern:
- Always succeeds (returns "(HEAD detached at ...)" in detached state, which is still useful)
- Output is always 1 line
- Saves Claude one Bash tool call on every invocation
- Zero risk of large output

**Implementation approach:** Add a `## Context` section as the first content block in each git skill's SKILL.md body.

---

## Error Handling Pattern

Always use `2>/dev/null` for commands that might fail in non-git directories:

```markdown
- Current branch: !`git branch --show-current 2>/dev/null`
```

For commands with network dependencies, provide fallback context:

```markdown
- Repository: !`gh repo view --json owner,name --jq '.owner.login + "/" + .name' 2>/dev/null || echo "unknown"`
```

Claude will see "unknown" and know to detect the repo itself. This is better than seeing a raw error message.

---

## Token Cost Analysis

| Injection Type | Typical Output Size | Tokens Added |
|---------------|---------------------|--------------|
| Branch name | ~20 chars | ~5 tokens |
| HEAD commit hash | ~7 chars | ~3 tokens |
| Project root path | ~40 chars | ~10 tokens |
| Repo identifier | ~30 chars | ~8 tokens |
| Commit log (bounded) | ~500 chars | ~100 tokens |
| Changed files (bounded) | ~500 chars | ~100 tokens |

**Cost is negligible.** Even the largest injections (bounded commit logs) add <100 tokens — a tiny fraction of the skill's total content which is typically 2000-5000 tokens.

---

## Summary: Recommended Adoptions

### High Priority (clear value, zero risk)

| Skill | Injection |
|-------|-----------|
| `git/create-pr` | branch name, bounded commit log |
| `git/address-pr-review` | branch name |
| `git/resolve-conflicts` | branch name |
| `git/explore-pr` | branch name |
| `git/repoint-branch` | branch name, bounded changed files |
| `git/split-pr` | branch name |
| `git/monitor-pr-comments` | branch name, repo identifier |
| `explore-repo` | project root, branch name, HEAD hash |
| `learnings/distribute` | project root |

### Low Priority (useful but marginal)

| Skill | Injection |
|-------|-----------|
| `git/cascade-rebase` | branch name only (skip branch list) |

### Skip (no value or too risky)

`prune-merged`, `do-refactor-code`, `do-security-audit`, `learnings/compound`, `learnings/consolidate`, `learnings/curate`, `parallel-plan/make`, `parallel-plan/execute`, `ralph/init`, `ralph/compare`, `quantum-tunnel-claudes`, `set-persona`

---

## Implementation Notes

1. **Standard section name:** Use `## Context` as the section heading for dynamic injections, placed immediately after the frontmatter and before the first instructional section.

2. **Error suppression:** Always append `2>/dev/null` to git commands that might run outside a repo.

3. **Output bounding:** For variable-length output, use `| head -N` to cap size (20-50 lines max).

4. **Fallback values:** For network-dependent commands, use `|| echo "fallback"` to give Claude something to work with.

5. **Testing:** After adding injections, invoke the skill in a non-git directory and a detached HEAD state to verify graceful degradation.

---

## Sources

- [Claude Code Skills docs](https://code.claude.com/docs/en/skills) — Dynamic context injection section
- `~/.claude/learnings/skill-design.md` — Existing documentation of `!`command`` syntax
- All 22 SKILL.md files in `~/.claude/commands/` — analyzed for injection candidates
