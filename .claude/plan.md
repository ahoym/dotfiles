# Plan: Light Grouping for Learnings Directory

## Problem

55+ flat learnings files are approaching a scale where filename-based discovery becomes less reliable. With a forthcoming cross-reference system using literal paths, directory structure will carry meaning beyond just organization — groups become units in the reference graph.

## Proposed Groups

Based on existing filename prefixes with 3+ files:

| Group | Files | Current names |
|-------|-------|---------------|
| `claude-authoring/` | 6 | `claude-authoring-{claude-md,content-types,guidelines,learnings,personas,skills}.md` |
| `xrpl/` | 5 | `xrpl-{amm,cross-currency-payments,dex-data,gotchas,patterns,permissioned-domains}.md` |
| `java/` | 5 | `spring-boot.md`, `spring-boot-gotchas.md`, `java-observability.md`, `java-observability-gotchas.md`, `java-infosec-gotchas.md` |

Everything else (~39 files) stays flat at `learnings/` root. No `misc/` or `general/` group.

### Naming within groups

Strip the group prefix from filenames to avoid redundancy:
- `claude-authoring/claude-md.md` (not `claude-authoring/claude-authoring-claude-md.md`)
- `xrpl/gotchas.md` (not `xrpl/xrpl-gotchas.md`)
- `java/spring-boot.md` (keeps its name — no `java-` prefix to strip)

### File placement: `quarkus-kotlin.md`

`quarkus-kotlin.md` goes in `java/`. It's JVM-ecosystem-specific. Cross-references from top-level files like `reactive-data-patterns.md` will bridge the gap.

## Changes Required (atomic commit)

### 1. Move files into subdirectories

Create `learnings/{claude-authoring,xrpl,java}/` and move + rename files.

### 2. Update learnings search protocol (`guidelines/context-aware-learnings.md`)

- Session-start glob: `*.md` → `**/*.md` for all three learnings directories
- Add note: subdirectories are domain groups, not type boundaries

### 3. Update `claude-authoring-learnings.md` → `claude-authoring/learnings.md`

- Revise "Avoid Nesting Subdirectories Inside learnings/" section to distinguish type nesting (still bad) from domain grouping (now endorsed)
- Add guidance: ungrouped files stay top-level; don't force categorization

### 4. Update compound skill (`commands/learnings/compound/SKILL.md`)

- Target file paths section: document that existing subdirectories should be used for matching domains
- Add rule: compound skill routes to existing groups but never creates new ones

### 5. Update persona references (~9 persona files)

Update bare paths like `learnings/spring-boot.md` → `learnings/java/spring-boot.md` in all persona files that reference moved files.

### 6. Update any other skills/commands referencing moved files

Grep results show ~30 files in `commands/` reference learnings paths. Update all literal path references to moved files.

### 7. Update `learnings-private/` convention

If `learnings-private/` exists in future, same grouping convention applies. No action now — just document the convention.

## What this plan does NOT do

- Create the cross-reference system (separate effort)
- Force ungrouped files into categories
- Change how the compound skill creates new files for ungrouped domains
- Add sub-grouping within groups (premature — revisit if a group exceeds ~10 files)

## Risk

**Primary:** Missed path references causing silent breakage. Mitigated by comprehensive grep + atomic commit.

**Secondary:** `quarkus-kotlin.md` in `java/` may be less discoverable for reactive/Kotlin-specific searches. Mitigated by future cross-references.

## Execution order

Steps 1-6 in a single atomic commit. Verify with grep that no stale `learnings/<old-filename>` references remain.
