# Codebase Summary: Claude Skills in This Repo

Concise reference for agents working on skill improvements. All skills live in `~/.claude/commands/` (the legacy `commands/` directory, not `skills/`).

---

## Repository Structure

```
~/.claude/
├── CLAUDE.md                          # Project instructions (references guidelines, bash/glob tips, sync-source)
├── settings.json                      # Shared settings (permissions, etc.)
├── settings.local.json                # Local overrides
├── commands/                          # ← ALL 22 skills live here (not skills/)
│   ├── ralph/                         # Iterative research loop
│   │   ├── init/                      #   Initialize research project
│   │   └── compare/                   #   Compare duplicate research dirs
│   ├── explore-repo/                  # Deep-scan repo for docs & gaps
│   ├── quantum-tunnel-claudes/        # Sync skills/learnings from source repo
│   ├── set-persona/                   # Activate domain-specific persona
│   ├── parallel-plan/                 # Parallel execution framework
│   │   ├── make/                      #   Analyze plan for parallelization
│   │   └── execute/                   #   Execute parallel plan with DAG scheduling
│   ├── learnings/                     # Knowledge management
│   │   ├── compound/                  #   Capture session learnings
│   │   ├── consolidate/               #   Multi-sweep exhaustive curation
│   │   ├── curate/                    #   Single-pass curation
│   │   └── distribute/               #   Copy global learnings to project
│   ├── do-refactor-code/              # Structured refactoring analysis
│   ├── do-security-audit/             # Parallel security audit
│   └── git/                           # Git workflow skills (8 total)
│       ├── address-pr-review/         #   Fetch & address PR comments
│       ├── cascade-rebase/            #   Rebase stacked branch chains
│       ├── create-pr/                 #   Create/update PRs
│       ├── explore-pr/                #   Fetch PR context + Q&A
│       ├── monitor-pr-comments/       #   Background PR comment watcher
│       ├── prune-merged/              #   Clean merged local branches
│       ├── repoint-branch/            #   Extract changes to new PR
│       ├── resolve-conflicts/         #   Merge conflict resolution
│       └── split-pr/                  #   Split large PRs
├── skill-references/                  # Shared reference docs (loaded by multiple skills)
│   ├── agent-prompting.md             #   Best practices for subagent prompts
│   ├── code-quality-checklist.md      #   Structural quality checks
│   ├── corpus-cross-reference.md      #   Cross-reference for learnings corpus
│   ├── platform-detection.md          #   GitHub/GitLab detection logic
│   └── subagent-patterns.md           #   Subagent delegation patterns
├── learnings/                         # 22 domain-specific learning files
│   ├── skill-design.md                #   Skill authoring patterns
│   ├── claude-code.md                 #   Claude Code behavior & gotchas
│   ├── git-patterns.md                #   Git workflow patterns
│   ├── parallel-plans.md              #   Parallel execution learnings
│   ├── multi-agent-patterns.md        #   Multi-agent coordination
│   └── ... (17 more domain files)
└── guidelines/
    └── communication.md               # Communication style (referenced from CLAUDE.md)
```

---

## Skill Inventory (22 Skills)

### By Namespace

| Namespace | Count | Skills |
|:----------|:------|:-------|
| `git:*` | 8 | address-pr-review, cascade-rebase, create-pr, explore-pr, monitor-pr-comments, prune-merged, repoint-branch, resolve-conflicts, split-pr |
| `learnings:*` | 4 | compound, consolidate, curate, distribute |
| `parallel-plan:*` | 2 | make, execute |
| `ralph:*` | 2 | init, compare |
| (ungrouped) | 6 | explore-repo, quantum-tunnel-claudes, set-persona, do-refactor-code, do-security-audit |

### By Size (body lines, excluding frontmatter)

| Tier | Skills | Lines |
|:-----|:-------|:------|
| Large (>300) | learnings:consolidate, parallel-plan:execute, explore-repo, learnings:curate, parallel-plan:make, git:address-pr-review | 315–616 |
| Medium (80–300) | git:prune-merged, git:repoint-branch, git:resolve-conflicts, git:explore-pr, learnings:distribute, learnings:compound, do-security-audit, git:cascade-rebase, git:monitor-pr-comments, git:create-pr, git:split-pr, ralph:compare | 75–259 |
| Small (<80) | ralph:init, set-persona, do-refactor-code | 52–67 |

**Note:** 6 skills exceed the Anthropic-recommended 500-line / 5,000-word guideline for SKILL.md bodies. `learnings:consolidate` (616 lines) is the largest.

---

## Frontmatter Usage

Every skill has a `description` field. **No other frontmatter fields are used.** Specifically absent:

| Field | Used? | Impact |
|:------|:------|:-------|
| `description` | ✅ All 22 | Primary trigger mechanism |
| `allowed-tools` | ❌ None | All skills run with full session tool access |
| `disable-model-invocation` | ❌ None | All 22 descriptions consume context budget |
| `context: fork` | ❌ None | No skills run in subagent isolation |
| `model:` | ❌ None | All skills use session's default model |
| `user-invocable` | ❌ None | All skills appear in `/` menu |
| `argument-hint` | ❌ None | No autocomplete hints |

---

## Feature Adoption

### `@` Reference Loading (14/22 skills)

Skills load supporting files conditionally (only when needed) or eagerly (every invocation):

| Pattern | Skills | Examples |
|:--------|:-------|:---------|
| Eager (`@file.md` at top) | explore-repo, git:create-pr, git:monitor-pr-comments, git:split-pr, git:repoint-branch, git:resolve-conflicts, git:explore-pr, git:address-pr-review | `@agent-prompts.md`, `@platform-detection.md` |
| Conditional (read in specific steps) | ralph:init, ralph:compare, learnings:compound, learnings:curate, learnings:consolidate, do-refactor-code, parallel-plan:make, parallel-plan:execute, quantum-tunnel-claudes | Read classification-model.md only in step 4 |

### `$ARGUMENTS` Usage (14/22 skills)

Most skills accept arguments for targeting (file paths, PR numbers, branch names, flags like `--dry-run`).

### Dynamic Context Injection (limited)

Only `explore-repo` uses `` !`command` `` preprocessing syntax. Several skills execute git/gh commands procedurally but don't use the shell preprocessing feature.

### Script Files (2 skills)

| Skill | Scripts |
|:------|:--------|
| quantum-tunnel-claudes | `inventory.sh` (file bucketing) |
| git:monitor-pr-comments | `init-tracking.sh`, `monitor-script.sh` (background polling) |

---

## Shared Resources

### skill-references/ (5 files, cross-skill)

| File | Used By |
|:-----|:--------|
| `platform-detection.md` | 7 git skills (create-pr, monitor-pr-comments, split-pr, repoint-branch, resolve-conflicts, explore-pr, address-pr-review) |
| `agent-prompting.md` | parallel-plan:make, parallel-plan:execute |
| `code-quality-checklist.md` | do-refactor-code, parallel-plan:execute |
| `corpus-cross-reference.md` | quantum-tunnel-claudes |
| `subagent-patterns.md` | (available but not directly `@`-referenced by any skill) |

### learnings/compound/ Reference Files (6 files)

These support the `learnings:compound` skill with conditional loading:
- `content-type-decisions.md` — Skill vs guideline vs learning classification
- `skill-template.md` — Template for new skills
- `writing-best-practices.md` — Conciseness and structure guidelines
- `skill-authoring.md` — Skill design patterns
- `iterative-loop-design.md` — Ralph loop patterns
- `public-release-review.md` — Genericization checklist

---

## Patterns Worth Noting

### What This Repo Does Well

1. **Semantic namespacing** — Clear groupings (`git:*`, `learnings:*`, `parallel-plan:*`, `ralph:*`)
2. **Conditional reference loading** — Most `@` refs are gated behind "read only if needed" logic, not eagerly loaded
3. **Shared reference library** — `skill-references/` avoids duplication across git skills (platform-detection used by 7 skills)
4. **Rich supporting docs** — Skills have dedicated reference files for methodology, templates, checklists
5. **Composition** — Skills reference each other (consolidate delegates to curate, monitor-pr-comments delegates to address-pr-review)
6. **Argument conventions** — Consistent `$ARGUMENTS` parsing patterns across skills

### Gaps vs. Official Best Practices

1. **No `allowed-tools` scoping** — Every skill runs with full tool access
2. **No `{baseDir}` usage** — Paths hardcoded as `~/.claude/...`
3. **No `context: fork`** — No subagent isolation despite good candidates (explore-repo, do-security-audit)
4. **Minimal `!`command`` usage** — Only explore-repo; git skills could inject git state
5. **No `disable-model-invocation`** — All 22 descriptions in context budget
6. **Commands not skills** — Using legacy `commands/` directory
7. **No `model:` overrides** — No haiku/sonnet/opus differentiation per skill
8. **No `argument-hint`** — No autocomplete hints for any skill
9. **6 skills exceed recommended size** — Bodies over 300 lines (max: 616)

---

## Key Metrics

| Metric | Value |
|:-------|:------|
| Total skills | 22 |
| Total supporting files | ~29 (refs, templates, personas, scripts) |
| Shared references | 5 (in skill-references/) |
| Largest skill | learnings:consolidate (616 lines) |
| Smallest skill | do-refactor-code (52 lines) |
| Skills using only `description` frontmatter | 22/22 |
| Skills using ANY other frontmatter | 0/22 |
| Learnings files | 22 domain-specific files |
| Guidelines files | 1 (communication.md) |
