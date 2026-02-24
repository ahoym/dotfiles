# Codebase Summary: ~/.claude Skills Collection

## What This Repo Is

This repo (`~/WORKSPACE/dotfiles`) is symlinked to `~/.claude` — the user's personal Claude Code settings directory. It contains **22 production skills**, shared references, guidelines, learnings, and configuration. Everything here applies globally across all projects.

---

## Directory Layout

```
~/.claude/
├── CLAUDE.md                      # Root instructions (guidelines ref, bash rules, repo context)
├── commands/                      # All 22 skills (SKILL.md entrypoints)
│   ├── git/                       # 9 git workflow skills
│   │   ├── address-pr-review/
│   │   ├── cascade-rebase/
│   │   ├── create-pr/
│   │   ├── explore-pr/
│   │   ├── monitor-pr-comments/
│   │   ├── prune-merged/
│   │   ├── repoint-branch/
│   │   ├── resolve-conflicts/
│   │   └── split-pr/
│   ├── learnings/                 # 4 knowledge management skills
│   │   ├── compound/
│   │   ├── consolidate/
│   │   ├── curate/
│   │   └── distribute/
│   ├── parallel-plan/             # 2 parallel execution skills
│   │   ├── execute/
│   │   └── make/
│   ├── ralph/                     # 2 iterative research skills
│   │   ├── compare/
│   │   └── init/
│   ├── do-refactor-code/          # Standalone
│   ├── do-security-audit/         # Standalone
│   ├── explore-repo/              # Standalone
│   ├── quantum-tunnel-claudes/    # Standalone
│   └── set-persona/               # Standalone (6 persona .md files)
├── guidelines/
│   └── communication.md           # Always-on via @ref in CLAUDE.md
├── learnings/                     # 22 reference docs (not skills)
├── skill-references/              # Shared references consumed by multiple skills
│   ├── agent-prompting.md         # → parallel-plan:make, parallel-plan:execute
│   ├── code-quality-checklist.md  # → do-refactor-code, parallel-plan:execute
│   ├── corpus-cross-reference.md  # Global shared reference
│   ├── platform-detection.md      # → 6 git skills
│   └── subagent-patterns.md       # → multi-agent skills
├── settings.json                  # Global permissions
├── settings.local.json            # Local permission overrides
└── lab/ralph/                     # Experimental scripts
```

---

## Skill Inventory (22 Skills)

### By Namespace

| Namespace | Count | Skills |
|-----------|-------|--------|
| `git/` | 9 | address-pr-review, cascade-rebase, create-pr, explore-pr, monitor-pr-comments, prune-merged, repoint-branch, resolve-conflicts, split-pr |
| `learnings/` | 4 | compound, consolidate, curate, distribute |
| `parallel-plan/` | 2 | execute, make |
| `ralph/` | 2 | compare, init |
| *(standalone)* | 5 | do-refactor-code, do-security-audit, explore-repo, quantum-tunnel-claudes, set-persona |

### Frontmatter Usage Across All 22 Skills

| Field | Skills Using It | Notes |
|-------|----------------|-------|
| `description` | **22/22** | Universal — every skill has this |
| `context` | **0/22** | No skills use `context: fork` |
| `disable-model-invocation` | **0/22** | All skills remain in context budget |
| `user-invocable` | **0/22** | All skills are both user- and model-invocable |
| `agent` | **0/22** | No subagent type overrides |
| `allowed-tools` | **0/22** | Expected — feature is currently broken |
| `hooks` | **0/22** | No skill-scoped hooks |
| `model` | **0/22** | No per-skill model overrides |
| `argument-hint` | **0/22** | No autocomplete hints |

**Key finding:** All 22 skills use description-only frontmatter. No advanced frontmatter features are in use anywhere.

---

## Patterns In Use

### Reference File Loading

Three tiers of reference loading are used consistently:

1. **Always-loaded (`@file.md`)** — Only 2 skills use this:
   - `ralph/init` → `@spec-template.md`, `@progress-template.md`
   - `explore-repo` → `@agent-prompts.md`

2. **Conditional references** (mentioned in body, read on demand) — Most common pattern. Skills list reference files but only read them when a specific step requires it.

3. **Shared references** (`~/.claude/skill-references/`) — 5 shared files consumed across multiple skills. `platform-detection.md` is the most widely shared (6 git skills).

### Supporting File Types

| Type | Examples | Skills Using |
|------|----------|-------------|
| Shell scripts | `init-tracking.sh`, `monitor-script.sh`, `inventory.sh` | monitor-pr-comments, quantum-tunnel-claudes |
| Templates | `pr-body-template.md`, `spec-template.md`, `skill-template.md` | create-pr, ralph/init, learnings/compound |
| Checklists | `comparison-checklist.md`, `public-release-review.md` | ralph/compare, learnings/compound |
| Reference docs | `reply-templates.md`, `rebase-patterns.md`, `classification-model.md` | Various |
| Persona files | `java-backend.md`, `platform-engineer.md`, etc. | set-persona |

### Skill Complexity Spectrum

| Complexity | Skills | Characteristics |
|------------|--------|----------------|
| **Simple** (self-contained) | prune-merged, distribute, repoint-branch | Single SKILL.md, no supporting files |
| **Medium** (1-3 refs) | create-pr, explore-pr, resolve-conflicts, cascade-rebase, split-pr, do-refactor-code, ralph/compare | SKILL.md + conditional refs |
| **Complex** (4+ refs, orchestration) | learnings/compound (6 refs), learnings/consolidate (4 refs, delegates to curate), monitor-pr-comments (scripts), parallel-plan/make, parallel-plan/execute, explore-repo | Multi-file, orchestration patterns |

---

## Architecture Observations

### What's Working Well

1. **Consistent namespace structure** — `git/`, `learnings/`, `parallel-plan/`, `ralph/` create clear groupings
2. **Conditional reference loading** — Most skills avoid `@` eager loading, keeping token costs low
3. **Shared reference pattern** — `skill-references/` prevents duplication across skills (platform-detection.md shared by 6 skills)
4. **Separation of concerns** — Skills that orchestrate background work (monitor-pr-comments) use shell scripts for the background loop, keeping SKILL.md focused on orchestration

### Improvement Opportunities

1. **No `disable-model-invocation: true`** on any skill — All 22 skill descriptions consume context budget. Manual-only skills like `ralph/init`, `ralph/compare`, `quantum-tunnel-claudes`, `set-persona` could use this to save budget.

2. **No `argument-hint`** — Skills that take arguments (e.g., `do-refactor-code <filepath>`, `explore-pr <pr-number>`) would benefit from autocomplete hints.

3. **No `context: fork`** — Some skills are pure-function candidates (explore-repo, do-security-audit) that could run in isolated subagents.

4. **`commands/` → `skills/` migration** — The repo uses `commands/` exclusively. While functionally equivalent, `skills/` is the recommended convention going forward.

5. **Stale settings** — `settings.local.json` references old path `compound-learnings/` (now `learnings/compound/`) and has a typo `Read(~.claude/*)`.

6. **No `agents/` directory** — Custom subagent definitions could complement skills that spawn Task subagents (parallel-plan/execute, explore-repo).

---

## Configuration

### Permissions (settings.json)

Globally allows:
- **Bash**: git commands, gh PR commands, common utils (curl, find, ls, grep, chmod), skill scripts
- **Read**: commands/**, guidelines/**, learnings/**, skill-references/**, skills/**, ~/WORKSPACE/**
- **Write/Edit**: guidelines/**, learnings/**, skill-references/**, skills/**

Notable: Write/Edit permissions exist for `skills/` but not `commands/` — consistent with eventual migration direction.

### Sync

Skills sync from `~/WORKSPACE/mahoy-claude-stuff` via the `quantum-tunnel-claudes` skill, configured by `sync-source:` in CLAUDE.md.

---

## Cross-References

- **Research findings**: See [info.md](./info.md) for best practices documentation
- **Source learnings**: `~/.claude/learnings/skill-design.md` (existing skill design patterns)
- **V1 research**: `docs/learnings/claude-skills-best-practices/` (templates only, no research)
