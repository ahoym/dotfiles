# Deep Research: Skill Context Budget Optimization

## Executive Summary

**The context budget is NOT under pressure.** All 23 loaded skills (22 repo + 1 built-in) consume approximately **4,900 chars out of a 16,000 char budget — ~31% utilization**. There is headroom for ~52 additional skills before any would be excluded.

This finding materially changes the implementation plan:
- `disable-model-invocation: true` should be motivated by **preventing unwanted auto-invocation**, not budget savings
- Description compression is valuable for **routing accuracy**, not budget recovery
- The 500-line SKILL.md audit is the more actionable optimization (1 skill exceeds the limit)

---

## 1. How the Budget Works

### Mechanism

Claude Code maintains a character budget for skill metadata (names + descriptions) that gets loaded into every conversation. This budget determines which skills Claude "knows about" — skills that don't fit are silently excluded.

| Parameter | Value | Source |
|-----------|-------|--------|
| Budget formula | 2% of context window | [Official docs](https://code.claude.com/docs/en/skills) |
| Fallback | 16,000 characters | Official docs |
| Opus 4.6 context | 200K tokens (~800K chars) | Model spec |
| Calculated budget | 2% × 800K = ~16K chars | Matches fallback |
| Override env var | `SLASH_COMMAND_TOOL_CHAR_BUDGET` | Official docs |
| Diagnostic command | `/context` | Official docs — shows budget warnings |

### What Counts Against the Budget

Each skill entry in the budget has this approximate structure:

| Component | Est. Chars | Notes |
|-----------|-----------|-------|
| XML/framing tags | ~85 | Internal wrapping per skill entry |
| Skill name | ~16 (avg) | Namespace:name format |
| Location field | ~4 | "personal", "project", etc. |
| Description text | variable | From SKILL.md frontmatter |
| **Total overhead per skill** | **~109** | **Before description text** |

Source: [Empirical budget analysis](https://gist.github.com/alexey-pelykh/faa3c304f731d6a962efc5fa2a43abe1) based on 63 skills. Note: this overhead estimate is from a third-party analysis and may vary by Claude Code version. The key formula is:

```
chars_per_skill = description_length + ~109
total_budget_used = sum(chars_per_skill for each loaded skill)
```

### What Gets Excluded

When skills exceed the budget, **truncation is based on cumulative total, not individual description length.** Skills are loaded in priority order (enterprise > personal > project > plugin). Once the budget fills, remaining skills are silently excluded — no error, no warning (except via `/context`).

### What Does NOT Count Against This Budget

- SKILL.md body content (loaded only on invocation)
- Supporting files (reference.md, examples/, scripts/)
- CLAUDE.md content (separate budget)
- Tool definitions (separate allocation)
- `@`-referenced files (always-on cost, but separate from skill budget)

---

## 2. Current Budget Consumption — Per-Skill Breakdown

### All 23 Loaded Skills

| # | Skill Name | Desc Chars | Est. Total | % of Budget |
|---|-----------|-----------|-----------|-------------|
| 1 | `learnings:consolidate` | 248 | 357 | 2.2% |
| 2 | `keybindings-help` *(built-in)* | 228 | 337 | 2.1% |
| 3 | `parallel-plan:execute` | 225 | 334 | 2.1% |
| 4 | `parallel-plan:make` | 222 | 331 | 2.1% |
| 5 | `learnings:curate` | 165 | 274 | 1.7% |
| 6 | `quantum-tunnel-claudes` | 109 | 218 | 1.4% |
| 7 | `learnings:distribute` | 105 | 214 | 1.3% |
| 8 | `learnings:compound` | 92 | 201 | 1.3% |
| 9 | `explore-repo` | 90 | 199 | 1.2% |
| 10 | `git:repoint-branch` | 79 | 188 | 1.2% |
| 11 | `git:split-pr` | 78 | 187 | 1.2% |
| 12 | `git:create-pr` | 78 | 187 | 1.2% |
| 13 | `ralph:init` | 72 | 181 | 1.1% |
| 14 | `ralph:compare` | 72 | 181 | 1.1% |
| 15 | `do-security-audit` | 67 | 176 | 1.1% |
| 16 | `git:cascade-rebase` | 66 | 175 | 1.1% |
| 17 | `git:monitor-pr-comments` | 65 | 174 | 1.1% |
| 18 | `git:explore-pr` | 57 | 166 | 1.0% |
| 19 | `git:prune-merged` | 56 | 165 | 1.0% |
| 20 | `set-persona` | 55 | 164 | 1.0% |
| 21 | `git:address-pr-review` | 54 | 163 | 1.0% |
| 22 | `do-refactor-code` | 53 | 162 | 1.0% |
| 23 | `git:resolve-conflicts` | 41 | 150 | 0.9% |
| | **TOTAL** | **2,501** | **4,908** | **30.7%** |

### Budget Summary

| Metric | Value |
|--------|-------|
| Total budget | 16,000 chars |
| Current consumption | ~4,908 chars |
| **Utilization** | **~30.7%** |
| **Remaining headroom** | **~11,092 chars** |
| Additional skills at avg desc length | ~52 more |
| Skills to fill budget (at avg 103-char desc) | ~75 total |

---

## 3. Capacity Planning

### How Many Skills Can Fit?

| Avg Description Length | Max Skills | Current Count | Headroom |
|----------------------|-----------|--------------|----------|
| 250 chars (verbose) | ~45 | 23 | +22 |
| 200 chars | ~52 | 23 | +29 |
| 150 chars | ~62 | 23 | +39 |
| **103 chars (current avg)** | **~75** | **23** | **+52** |
| 80 chars (concise) | ~85 | 23 | +62 |
| 50 chars (minimal) | ~101 | 23 | +78 |

### Growth Scenarios

**Conservative (30 → 40 skills)**: At current average description length, 40 skills would use ~8,480 chars (53% budget). No action needed.

**Moderate (40 → 60 skills)**: At 60 skills with 103-char avg descriptions, ~12,720 chars (80% budget). Start monitoring with `/context` but no compression needed.

**Aggressive (60+ skills)**: Would approach budget limits. Description compression to ≤130 chars recommended to maintain ~67 skill capacity.

---

## 4. Impact on Implementation Plan

### Phase 0.1 (Measure Context Budget) — Downgraded Priority

**Previous priority**: High — "must measure before optimizing"
**New priority**: Low — measurement confirms comfortable fit; `/context` validation is a nice-to-have sanity check, not a blocking prerequisite.

**Recommendation**: Still run `/context` in a live session for empirical confirmation, but don't block other phases on it. The theoretical analysis is high-confidence.

### Phase 1A (`disable-model-invocation`) — Unchanged Priority, Changed Rationale

**Previous rationale**: "Removes these 4 descriptions from context budget"
**New rationale**: Prevents unwanted auto-invocation of manual-only skills

Budget savings from the 4 candidates (ralph:init, ralph:compare, quantum-tunnel-claudes, set-persona) would be ~744 chars — reducing utilization from 31% to 26%. **Not meaningful for budget**, but still the right thing to do for invocation control.

### Phase 2A (Description Optimization) — Downgraded Urgency

**Previous rationale**: "Every char counts against the 16K budget"
**New rationale**: Description quality improves routing accuracy, not budget recovery

The 3 longest descriptions that might benefit from shortening:

| Skill | Current Desc Chars | Contains Routing Phrases |
|-------|-------------------|------------------------|
| `learnings:consolidate` | 248 | No — all functional content |
| `parallel-plan:execute` | 225 | Yes — "Use when the user says..." |
| `parallel-plan:make` | 222 | Yes — "Use when the user says..." |

The "Use when..." phrases in parallel-plan skills take ~100 chars each. Whether to keep them depends on routing accuracy, not budget. **Test without them first** — the skill names and functional descriptions may be sufficient for Claude's inference.

### Phase 0.3 (Validation Script) — Budget Estimator Is Nice-to-Have

The proposed validation script included "context budget estimation" as a feature. Given 31% utilization, this is low-value. Implement structural + semantic validation first; add budget estimation only if the collection grows past 50 skills.

---

## 5. SKILL.md Line Count Analysis

The 500-line recommendation applies to SKILL.md body content (what gets loaded on invocation). Two skills exceed this:

| Skill | Lines | Status | Recommendation |
|-------|-------|--------|----------------|
| `learnings/consolidate` | 640 | **Over limit** | Extract state machine / approval flow to reference file |
| `learnings/curate` | 450 | Borderline | Review — classification model is already in separate file |
| `parallel-plan/execute` | 396 | Under limit | OK |
| `explore-repo` | 368 | Under limit | OK |
| `parallel-plan/make` | 320 | Under limit | OK |
| `git/address-pr-review` | 314 | Under limit | OK |

**`learnings/consolidate` at 640 lines** is the only clear violation. It already delegates analysis methodology to `learnings:curate` via a conditional reference, but its state machine, approval flow, and sweep orchestration logic account for the excess. Candidates for extraction:
- State variable tracking table and sweep lifecycle (~80 lines)
- Detailed approval flow and confidence level handling (~100 lines)
- These could move to a `consolidation-workflow.md` reference file

**`learnings/curate` at 450 lines** is borderline. It already has 2 external reference files (`classification-model.md`, `persona-design.md`). The remaining 450 lines are core methodology — splitting further would fragment the workflow.

---

## 6. Built-In Skills: keybindings-help

`keybindings-help` is a **bundled skill** that Claude Code always loads, even with `--disable-slash-commands`. This is a [known bug](https://github.com/anthropics/claude-code/issues/24156).

| Detail | Value |
|--------|-------|
| Source | Built-in (bundled with Claude Code) |
| Budget cost | ~337 chars (2.1% of budget) |
| Token cost per cycle | ~50 tokens |
| Can be disabled | No (bug — bypasses all settings) |

**Impact**: Negligible. At 2.1% of budget, this is not worth worrying about.

---

## 7. Validation Steps for Live Session

Run these in a Claude Code session to empirically confirm the theoretical analysis:

### Step 1: Check `/context` Output

```
/context
```

Expected output includes:
- Token usage breakdown
- Whether any skills are excluded from context
- **If no warning about excluded skills appears, all skills fit within budget** (confirming our analysis)

### Step 2: Verify Skill Visibility

```
What skills are available?
```

Claude should list all 22 repo skills + keybindings-help. If any are missing, they've been excluded from context.

### Step 3: Post-Implementation Validation (After Phase 1A)

After adding `disable-model-invocation: true` to the 4 manual-only skills, run `/context` again. The 4 skills should no longer appear in the context budget, and the remaining 18+1 skills should still fit comfortably.

---

## 8. Recommendations Summary

| Recommendation | Priority | Rationale |
|---------------|----------|-----------|
| **No immediate budget optimization needed** | — | 31% utilization with ~52-skill headroom |
| Run `/context` for empirical confirmation | Low | Nice-to-have sanity check, not blocking |
| Add `disable-model-invocation` to 4 skills | Medium | For invocation control, not budget |
| Review parallel-plan routing phrases | Low | Test if routing works without "Use when..." |
| Extract content from `learnings/consolidate` | Medium | 640 lines exceeds 500-line recommendation |
| Monitor budget if collection grows past 50 skills | Low | Only relevant at ~60+ skills |
| Don't add budget estimation to validation script | Low | Not useful at current scale |

---

## Sources

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) — Official reference (Feb 2026)
- [Skill Budget Empirical Analysis](https://gist.github.com/alexey-pelykh/faa3c304f731d6a962efc5fa2a43abe1) — Third-party budget measurement with 63 skills
- [keybindings-help Bug Report](https://github.com/anthropics/claude-code/issues/24156) — Built-in skill loading issue
- Live system prompt observation (this conversation) — 23 skills listed in `<system-reminder>` block
