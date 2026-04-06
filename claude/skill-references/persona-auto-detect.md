---
name: persona-auto-detect
description: "Shared persona auto-detection instructions for autonomous agents — index-based discovery using persona filenames as signals."
---

# Persona Auto-Detection

Select a domain persona by matching work item signals against available personas.

1. **List available personas:** `ls ~/.claude/commands/set-persona/*.md` (exclude `SKILL.md`). Persona filenames are descriptive — e.g., `java-backend.md`, `react-frontend.md`, `claude-config-author.md`.

2. **Collect signals** from the work item: issue labels, title keywords, body keywords, and file paths/frameworks from the repo summary.

3. **Match filenames against signals.** Scan the persona filenames for overlap with your signals. Examples:
   - Issue mentions "skill", "persona", "CLAUDE.md", "learnings" → `claude-config-author`
   - Repo has `*.java`, `pom.xml`; issue labels include `java` → `java-backend`
   - Issue mentions "react", "component"; repo has `*.tsx` → `react-frontend`
   - Issue mentions "deploy", "CI/CD", "pipeline" → `platform-engineer`

4. **Confirm the top candidate.** Read the first 5 lines of the matched persona file to verify domain fit. If it declares `## Extends:`, also read the parent(s).

5. **Adopt or skip.** If the match fits, adopt its lens. If no filename resonates with the signals, proceed without a persona — don't force a weak match.

Announce: `🎭 Persona: <name>` or `🎭 No persona match — proceeding without`
