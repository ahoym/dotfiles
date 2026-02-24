# Deep Research: Skill Testing and Validation

## Executive Summary

The Agent Skills ecosystem has a reference validation tool (`skills-ref validate`) but it enforces the **strict open standard** — it rejects Claude Code extension fields like `disable-model-invocation`, `context`, `hooks`, etc. This creates a fundamental compatibility gap: any skill using Claude Code-specific features (which this repo's implementation plan heavily recommends) will fail spec-only validation. The repo needs a **custom validation script** that understands both spec fields and Claude Code extensions. No established CI/CD pattern exists in the ecosystem yet — neither Anthropic's own repos nor the agentskills org have automated skill validation workflows.

---

## 1. `skills-ref validate` — Complete Analysis

### What It Is

A Python CLI tool in the [`agentskills/agentskills`](https://github.com/agentskills/agentskills/tree/main/skills-ref) repository. Labeled as v0.1.0 and explicitly marked **"for demonstration purposes only. Not meant to be used in production."**

### Installation

Requires Python 3.11+. Core dependencies: `click` (CLI) + `strictyaml` (YAML parsing).

```bash
# Clone and install locally
git clone https://github.com/agentskills/agentskills
cd agentskills/skills-ref
python -m venv .venv && source .venv/bin/activate
pip install -e .
```

Not published to PyPI — local/editable install only.

### Three Commands

| Command | Purpose | Exit Codes |
|---------|---------|-----------|
| `skills-ref validate <path>` | Validate skill directory structure + frontmatter | 0=valid, 1=errors |
| `skills-ref read-properties <path>` | Extract frontmatter as JSON | 0=success, 1=error |
| `skills-ref to-prompt <path>...` | Generate `<available_skills>` XML for agent prompts | 0=success, 1=error |

### Exact Validation Rules

Source: [`validator.py`](https://github.com/agentskills/agentskills/blob/main/skills-ref/src/skills_ref/validator.py)

**Directory/file checks:**
- Path exists and is a directory
- Contains `SKILL.md` (case-insensitive: `skill.md` also accepted)
- YAML frontmatter starts with `---` and is properly closed

**Required fields:**
- `name` — mandatory in the spec
- `description` — mandatory in the spec

**Name validation:**
- Max 64 chars (Unicode NFKC normalized)
- Lowercase only (checked with `.lower()`)
- No start/end hyphens
- No consecutive hyphens (`--`)
- Only alphanumeric + hyphens
- **Must match parent directory name** exactly
- Supports i18n: Chinese, Cyrillic, etc. (unicode lowercase letters allowed)

**Description validation:**
- Non-empty string
- Max 1,024 chars

**Compatibility validation (if present):**
- Max 500 chars

**Allowed fields (CRITICAL):**
```python
ALLOWED_FIELDS = {"name", "description", "license", "allowed-tools", "metadata", "compatibility"}
```

**Any field not in this set produces an error.** This means ALL Claude Code extensions are rejected:
- `disable-model-invocation` → error
- `user-invocable` → error
- `argument-hint` → error
- `context` → error
- `agent` → error
- `model` → error
- `hooks` → error

### Test Coverage

24 test cases covering: valid skills, missing paths, uppercase names, length limits, directory mismatches, unexpected fields, i18n characters, NFKC normalization. Well-tested but narrowly scoped to spec compliance.

---

## 2. Compatibility Gap: This Repo vs. The Spec

### Current State — ALL 22 Skills Would Fail

Every SKILL.md in this repo has only a `description` field in frontmatter. The spec validator would report:

1. **"Missing required field: name"** — Claude Code infers the name from the directory path; the spec requires it explicitly
2. No other spec violations currently (descriptions are present and reasonable length)

### Post-Implementation Plan — More Failures

The implementation plan (Phases 1-4) recommends adding Claude Code-specific fields:

| Planned Addition | Phase | Spec Compliance |
|-----------------|-------|----------------|
| `disable-model-invocation: true` | 1A | **FAIL** — unexpected field |
| `argument-hint: [value]` | 1B | **FAIL** — unexpected field |
| `hooks: { ... }` | 4B | **FAIL** — unexpected field |
| `context: fork` | Future | **FAIL** — unexpected field |
| `agent: Explore` | Future | **FAIL** — unexpected field |
| `model: haiku` | 4A | **FAIL** — unexpected field |
| `name: skill-name` | Could add | PASS — if constraints met |

### Fundamental Tension

The Agent Skills spec is **cross-platform minimal**. Claude Code extends it with platform-specific features. These two goals are in tension:

- **Spec compliance** = portable but feature-limited
- **Claude Code extensions** = powerful but platform-specific

This repo is a personal dotfiles collection targeting Claude Code specifically (A12 in assumptions). Cross-platform portability is explicitly deprioritized. Therefore: **Claude Code extensions should take priority over strict spec compliance.**

---

## 3. Ecosystem CI/CD Landscape

### Official Repos — No CI/CD

| Repo | CI/CD | Testing | Skill Validation |
|------|-------|---------|-----------------|
| [`agentskills/agentskills`](https://github.com/agentskills/agentskills) | None visible | pytest locally | None automated |
| [`anthropics/skills`](https://github.com/anthropics/skills) | None visible | None | "Test in your own environment" |
| This repo | No `.github/` dir | None | None |

### Contributing Guidelines

`agentskills/agentskills` CONTRIBUTING.md: *"Make your changes and verify they work locally"* — no automated quality gates, no required CI checks.

### Community Patterns

[`ChrisWiles/claude-code-showcase`](https://github.com/ChrisWiles/claude-code-showcase): Demonstrates PostToolUse hooks for format/lint after file edits, but no skill-level validation. Uses `skill-eval.sh` and `skill-eval.js` for intelligent skill suggestion (matching prompts to skills), not validation.

No established community pattern for automated skill validation CI/CD.

### Claude Code Built-in Testing

Claude Code provides limited testing capabilities:

| Method | What It Checks | Automation |
|--------|---------------|------------|
| `/context` | Skills loaded, budget warnings, excluded skills | Manual only |
| "What skills are available?" | Skill discovery works | Manual only |
| `/skill-name` | Skill invocation works | Manual only |
| Troubleshooting guidance | Description quality, budget overflow | Manual only |

No built-in `validate` command. No programmatic validation API.

---

## 4. Recommended Validation Architecture

### Three-Layer Model

```
Layer 1: Static Structural Validation (automated, CI-friendly)
    ↓
Layer 2: Semantic Validation (automated, CI-friendly)
    ↓
Layer 3: Behavioral Testing (requires live Claude session, manual)
```

### Layer 1: Static Structural Validation

**What**: File/directory structure and YAML parsing.

**Checks:**
- [ ] SKILL.md exists in each skill directory
- [ ] YAML frontmatter is parseable (opens with `---`, closes with `---`, valid YAML)
- [ ] `description` field present and non-empty (Claude Code's only hard requirement)
- [ ] SKILL.md under 500 lines
- [ ] All `@reference.md` eager references resolve to existing files
- [ ] All `reference.md` conditional references resolve to existing files
- [ ] No orphaned files in skill directories (files not referenced from SKILL.md)

**Tooling**: Custom Python or shell script. StrictYAML or PyYAML for parsing.

### Layer 2: Semantic Validation

**What**: Field values, types, and cross-skill constraints.

**Checks:**

**Frontmatter fields (Claude Code superset of spec):**

| Field | Type | Constraints |
|-------|------|-------------|
| `name` | string | Max 64 chars, lowercase + hyphens, matches dir name, no start/end/consecutive hyphens |
| `description` | string | Max 1,024 chars, non-empty |
| `disable-model-invocation` | boolean | `true` or `false` |
| `user-invocable` | boolean | `true` or `false` |
| `argument-hint` | string | Should use `[bracket]` convention |
| `context` | string | Only `"fork"` is valid |
| `agent` | string | Built-in types or custom agent name |
| `model` | string | `haiku`, `sonnet`, `opus` (or full model IDs) |
| `hooks` | mapping | Valid hook structure (PreToolUse, PostToolUse, Stop) |
| `allowed-tools` | string | Space-delimited tool names |
| `license` | string | Free-form |
| `compatibility` | string | Max 500 chars |
| `metadata` | mapping | String keys, string values |

**Cross-skill checks:**
- [ ] Context budget estimation: sum `name` + `description` lengths for non-`disable-model-invocation` skills, warn if > 16K chars
- [ ] No duplicate skill names across all skill directories
- [ ] `context: fork` skills don't reference Task tool usage in their body (incompatible)

**Consistency checks:**
- [ ] `$ARGUMENTS` usage in body is consistent with `argument-hint` presence
- [ ] `!`command`` syntax uses valid shell commands (basic syntax check)
- [ ] `disable-model-invocation: true` skills don't also have `user-invocable: false` (contradictory)
- [ ] `context: fork` requires a task-based body (not just reference content)

### Layer 3: Behavioral Testing

**What**: Live invocation in a Claude Code session. Cannot be automated in CI.

**Checks:**
- [ ] `/context` shows expected skills loaded, no budget overflow warnings
- [ ] Each skill responds to `/skill-name` invocation
- [ ] `argument-hint` displays in autocomplete
- [ ] Subagent delegation works for `context: fork` skills
- [ ] Dynamic context injection (`!`command``) resolves correctly
- [ ] Skills work in both git and non-git directories (graceful degradation)

**Recommendation**: Create a manual test checklist, not an automated test. Run after significant changes.

---

## 5. Implementation Options

### Option A: Shell Script (Lightweight)

**Pros:** Zero dependencies, fast, fits existing Bash-heavy workflow.
**Cons:** YAML parsing in shell is fragile, limited semantic validation.

```bash
#!/bin/bash
# scripts/validate-skills.sh
errors=0
for dir in .claude/commands/*/ .claude/commands/*/*/; do
  skill="$dir/SKILL.md"
  [ -f "$skill" ] || continue

  # Check YAML frontmatter exists
  head -1 "$skill" | grep -q "^---" || { echo "FAIL: $skill missing frontmatter"; errors=$((errors+1)); }

  # Check description present
  grep -q "^description:" "$skill" || { echo "FAIL: $skill missing description"; errors=$((errors+1)); }

  # Check line count
  lines=$(wc -l < "$skill")
  [ "$lines" -gt 500 ] && { echo "WARN: $skill is $lines lines (>500)"; }
done
exit $errors
```

**Best for**: Quick pre-commit sanity check.

### Option B: Python Script (Comprehensive)

**Pros:** Proper YAML parsing, full semantic validation, can reuse `skills-ref` parsing logic.
**Cons:** Requires Python 3.11+, adds dependency.

Could either:
1. **Fork/extend `skills-ref`** — patch `ALLOWED_FIELDS` to include Claude Code extensions, add Claude Code-specific validation
2. **Write standalone** — ~200 lines of Python using `strictyaml` or `pyyaml`, implementing all Layer 1 + Layer 2 checks

**Best for**: CI/CD pipeline or comprehensive pre-commit validation.

### Option C: Claude Code Hook (Post-Edit)

**Pros:** Validates in real-time as skills are edited. Zero external tooling.
**Cons:** Only catches issues during editing sessions, not in CI.

Settings-level PostToolUse hook that triggers when SKILL.md files are modified:

```json
{
  "PostToolUse": [{
    "matcher": "Edit|Write",
    "hooks": [{
      "type": "command",
      "command": "bash -c 'FILE=$(echo $TOOL_INPUT | jq -r .file_path 2>/dev/null); [[ $FILE == *SKILL.md ]] && python ~/.claude/scripts/validate-skill.py $(dirname $FILE) || true'"
    }]
  }]
}
```

**Best for**: Development-time safety net, not CI/CD.

### Recommended Combination

| Layer | Tool | Trigger |
|-------|------|---------|
| Quick sanity | Shell script (Option A) | Pre-commit hook |
| Full validation | Python script (Option B) | GitHub Actions on push to `.claude/commands/**` or `.claude/skills/**` |
| Development-time | Claude Code hook (Option C) | PostToolUse on SKILL.md edits |
| Behavioral | Manual checklist | After significant skill changes |

---

## 6. CI/CD Integration Patterns

### GitHub Actions Workflow

```yaml
name: Validate Skills
on:
  push:
    paths: ['.claude/commands/**', '.claude/skills/**']
  pull_request:
    paths: ['.claude/commands/**', '.claude/skills/**']

jobs:
  validate-skills:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: pip install strictyaml
      - name: Validate all skills
        run: python scripts/validate-skills.py
      - name: Estimate context budget
        run: python scripts/estimate-context-budget.py
```

**Path-scoped triggering** ensures the workflow only runs when skill files change, keeping CI costs low.

### Pre-Commit Hook

Using a simple shell-based check (since this repo has no package manager or build system):

```bash
#!/bin/bash
# .git/hooks/pre-commit or linked via settings
changed_skills=$(git diff --cached --name-only | grep 'SKILL.md')
if [ -n "$changed_skills" ]; then
  for skill in $changed_skills; do
    dir=$(dirname "$skill")
    # Basic structural check
    head -1 "$skill" | grep -q "^---" || { echo "FAIL: $skill missing frontmatter"; exit 1; }
    grep -q "^description:" "$skill" || { echo "FAIL: $skill missing description"; exit 1; }
  done
fi
```

### Claude Code Hook (Settings-Level)

Could be added to user or project settings for real-time validation during development. See Option C above.

---

## 7. Relationship to `skills-ref validate`

### Should This Repo Use `skills-ref validate`?

**No, not directly.** The tool rejects Claude Code extension fields, making it incompatible with the implementation plan.

### Should This Repo Track `skills-ref` Compatibility?

**Optional, low priority.** If cross-platform portability becomes important later (A12), a separate "spec compliance" check could strip Claude Code fields and validate the remaining core fields. But since this is a personal dotfiles repo targeting Claude Code exclusively, spec compliance is a nice-to-have, not a requirement.

### Could `skills-ref` Be Extended?

The tool's strict field checking is the main obstacle:

```python
ALLOWED_FIELDS = {"name", "description", "license", "allowed-tools", "metadata", "compatibility"}
```

Options:
1. **Fork and patch** — Add Claude Code fields to `ALLOWED_FIELDS`. Low effort but creates maintenance burden.
2. **Upstream contribution** — Propose a `--strict` / `--lenient` flag that allows unknown fields. The spec could treat unknown fields as warnings instead of errors. Worth proposing to the agentskills org.
3. **Wrapper script** — Run `skills-ref validate` but filter its output to ignore "Unexpected fields" errors. Fragile but zero-maintenance.

**Recommendation**: Don't depend on `skills-ref` for this repo's CI. Build a custom validator that handles the Claude Code superset natively. If/when `skills-ref` adds lenient mode, adopt it for spec-level checks.

---

## 8. What a Custom Validator Should NOT Check

Avoid over-engineering. The validator should **not**:

- Lint Markdown body formatting (too opinionated, SKILL.md is freeform)
- Check skill content quality or completeness (requires human judgment)
- Validate shell commands in `!`command`` syntax beyond basic parse (too many false positives)
- Enforce a specific SKILL.md template/structure (patterns vary by skill type)
- Check for stale cross-skill references like "use `/other-skill`" (too fragile, skills are renamed)
- Run the skills (Layer 3 testing is manual)

---

## 9. Impact on Implementation Plan

### New Phase 0 Task

Add a Phase 0 task to implement the basic validation script before making Phase 1 changes. This establishes a safety net before mass-editing frontmatter.

### Phase 1 Validation

After adding `disable-model-invocation` and `argument-hint` to skills (Phases 1A, 1B), the validator should catch:
- Invalid boolean values for `disable-model-invocation`
- Missing `argument-hint` when `$ARGUMENTS` is used in skill body
- Context budget estimation to verify `disable-model-invocation` reduced budget consumption

### Phase 4 Validation

When adding `hooks` frontmatter (Phase 4B), the validator should check hook structure:
- Valid event types (PreToolUse, PostToolUse, Stop)
- Valid matcher patterns (tool names with optional glob)
- Valid hook types (command, prompt, agent)
- Command hooks reference existing scripts

### Phase 5 Integration

Phase 5 (Validation & Documentation) should include running the full validation suite and documenting it as a maintenance workflow.

---

## 10. Spec Compliance Opportunity: Add `name` Field

The one spec-compliant improvement that provides immediate value with no downside:

**Add `name:` to all 22 SKILL.md frontmatter blocks.**

This is:
- Required by the spec (currently missing from all skills)
- Harmless in Claude Code (which infers name from directory if absent, but accepts explicit `name`)
- Makes skills self-documenting (you can see the name without checking the directory path)
- Enables future `skills-ref` compatibility if cross-platform becomes relevant
- Required for the `skills-ref read-properties` and `to-prompt` commands to work

The name values would match existing directory names:
- `git/create-pr/SKILL.md` → `name: create-pr`
- `learnings/compound/SKILL.md` → `name: compound`
- `ralph/init/SKILL.md` → `name: init`

**Note**: The nested namespace (e.g., `git:create-pr` in Claude Code) is separate from the `name` field. The spec's `name` matches the immediate parent directory.

---

## Sources

- [Agent Skills Specification](https://agentskills.io/specification) — Official spec including validation section
- [skills-ref Reference Library](https://github.com/agentskills/agentskills/tree/main/skills-ref) — Python CLI tool source code
- [skills-ref validator.py](https://github.com/agentskills/agentskills/blob/main/skills-ref/src/skills_ref/validator.py) — Exact validation rules
- [skills-ref pyproject.toml](https://github.com/agentskills/agentskills/blob/main/skills-ref/pyproject.toml) — Dependencies and version
- [Anthropic Skills Examples](https://github.com/anthropics/skills) — Official reference skills (no CI/CD)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) — Official Claude Code-specific docs
- [Agent Skills Integration Guide](https://agentskills.io/integrate-skills) — How agents should validate skills
- [claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) — Community CI/CD pattern example
