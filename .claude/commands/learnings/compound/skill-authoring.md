# Skill Authoring

Guidelines for writing Claude Code skills and protocols.

## No Half-Steps in Numbered Instructions

When writing numbered steps in skills or protocols, use proper integer steps (Step 0, 1, 2, 3...), not half-steps (Step 1.5). Half-steps signal the structure wasn't planned upfront, add uncertainty about ordering, and make the sequence harder to reference. If a new step needs to be inserted, renumber all subsequent steps.

## Verify Assumptions Before Documenting

Always test assumptions with a controlled experiment before writing them as facts across multiple files. Before documenting a technical limitation, run a minimal reproducer that isolates the specific claim. If testing "agents can't use X", test with a known-working variant first before concluding it's a platform issue.

Common pattern: permission-denied errors in background agents are almost always missing allow patterns, not platform constraints. Test with a command known to be allowed before escalating.

## Background Agent Permission Debugging

When a background agent fails silently (no output, or "permission denied"), follow this diagnostic sequence:

1. Check if the specific command has a matching allow pattern in `.claude/settings.local.json`
2. Test with a simple command that IS in the allow list (e.g., `echo "test"`) to isolate permission vs platform issues
3. If the simple command works — the issue is a missing allow pattern for the specific command
4. If the simple command also fails — escalate as a potential platform issue

The most common cause of background agent failure is a missing Bash allow pattern, not a fundamental limitation.
