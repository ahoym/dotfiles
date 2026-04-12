# Prompt Template

Template for structuring the verification analysis. The skill populates placeholders before running the check.

## Input Placeholders

| Placeholder | Source | Required |
|-------------|--------|----------|
| `{{INTENT}}` | Intent file content (director mode) or self-captured summary (standalone) | Yes |
| `{{INTENT_SOURCE}}` | `director-negotiated`, `operator-confirmed`, or `inferred-from-pr-description` | Yes |
| `{{DIFF}}` | Full PR diff from `gh pr diff` | Yes |
| `{{COMMENTS}}` | All PR comments and review threads from `gh` API | Yes |
| `{{DISCIPLINE_RULES}}` | Content of `discipline-rules.md` | Yes |
| `{{MODE}}` | `standalone` or `director` | Yes |

## Report Template

```markdown
## Convergence Verification: PR #<NUMBER> — <TITLE>

### Discipline Check

- [x/fail] **Footnote format** — <count> agent comments checked, <result>
- [x/fail] **Body shape** — <result with citation if failed>
- [x/fail] **Reaction discipline** — <result with citation if failed>
- [x/fail] **Loop closure** — <result with citation if failed>
- [x/fail] **Issue references** — <result>
- [x/fail] **Empty review guard** — <result>

### Intent Alignment

> Intent source: `{{INTENT_SOURCE}}` — <confidence framing>

#### Acceptance Criteria

| Criterion | Delivered? | Evidence |
|-----------|-----------|----------|
| <criterion from intent> | Yes/No/Partial | <commit SHA, diff lines, or "not found"> |

#### Scope

- **In scope, delivered**: <items from intent that landed>
- **Intentional expansion**: <items pulled in beyond intent, with justification visible in PR>
- **Unrelated drift**: <changes unrelated to intent — surface, don't judge>
- **Missed cleanup**: <intent items not delivered and not deferred>

#### Quality Gate

<Only if issues found. Placeholders, TODOs, half-implemented branches. Cite file + line.>

#### Side Effects

<Changes outside the intent — ambient commits, config changes, etc. Surface, don't judge.>

---
- *Co-Authored with [Claude Code](https://claude.ai/code) (<model>)*
- *Persona:* convergence-verifier
- *Role:* Verifier
```

## Confidence Framing by Intent Source

- **`director-negotiated`**: "Intent was captured and confirmed by the operator at session start. Scope analysis is high-confidence."
- **`operator-confirmed`**: "Intent was drafted from PR metadata and confirmed by the operator. Scope analysis is medium-confidence."
- **`inferred-from-pr-description`**: "Intent was inferred from the PR description without explicit confirmation. Scope analysis is advisory — treat as suggestions to verify, not assertions."

## Mode-Specific Behavior

### Standalone mode
- Clarification needed? Ask the operator directly via conversation.
- Output: post as top-level PR comment.

### Director mode
- Clarification needed? Output `CLARIFY: <question>` and stop. Director routes it.
- Output: post as top-level PR comment AND write to `<session_dir>/verify-pr-<N>.md`.
