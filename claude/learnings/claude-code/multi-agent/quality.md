Multi-agent quality and validation — verification patterns, trust arc, agent-to-agent review, prompt design, and assumption checking.
- **Keywords:** trust arc, agent-to-agent review, verify assumptions, gate announcements, intent files, TaskOutput, subagent verification, front-load context
- **Related:** none

---

## Verify Subagent Research Actually Used Web Sources

When delegating research to subagents (Task tool with `claude-code-guide` or `Explore`), check the **sources** in their output — not just the conclusions. Subagents may read local files and existing learnings instead of performing fresh web searches, then present recycled information as new research. This is especially problematic when the local files contain the very claims you're trying to validate.

**Red flags:** output only cites local file paths, no WebSearch/WebFetch calls in the work, conclusions perfectly match existing assumptions. **Fix:** explicitly instruct subagents to "use WebSearch and WebFetch to find NEW information — do not rely on local files" and review whether they actually did.

## Three-Branch Gate Announcements

Every hard gate (session start, plan mode, implementation start) needs three announcement templates: positive match, already satisfied, and skip/no-match. Missing a branch means the gate fires silently — no observability on whether it executed. During calibration this is especially costly: silent skips look identical to gates that didn't fire at all, making it impossible to diagnose whether the system is working.

## Delegated Operations via Intent Files

When an agent can't execute certain operations (e.g., Bash blocked by security hooks), delegate via structured intent files: agent writes requests to a dedicated file (one per line), outer loop processes them between iterations. Prefer explicit intent files over parsing action logs — separate concerns, simpler parsing, no coupling to log format.

Example: agent can't `git rm` (Bash blocked) → writes `claude/consolidate-output/pending-deletions.txt` with paths to delete → wiggum.sh reads the file between iterations and runs `git rm` for each entry. Safety check: only delete files that are truly empty (prevents accidental deletion from wrong paths).

## Front-Load Structural Context in Subagent Prompts

When delegating classification or evaluation tasks to subagents, include structural context that prevents misclassification — don't assume the subagent will infer it. For example, when evaluating skills, tell the subagent that subdirectory skills (e.g., `explore-repo/brief/`) are already sub-commands of their parent, not independent skills to merge. Without this, subagents flag false positives based on surface-level overlap analysis.

## Verify Assumptions Before Documenting

Test assumptions with a controlled experiment before writing them as facts across multiple files. Run a minimal reproducer that isolates the specific claim. If testing "agents can't use X", test with a known-working variant first before concluding it's a platform issue.

## Cross-Check Subagent Inventory Comparisons

When subagents compare file inventories across two directories, they may report files as "unique to X" that actually exist in both — especially with large file counts (50+). Always cross-check subagent diff results against a canonical source you control (e.g., a glob you ran yourself). The error compounds when the over-reported "unique" files drive downstream decisions (what to copy, what to merge).

## Agent-to-Agent Review Architecture

Reviewer → addresser → human is a viable review cycle. The addresser investigates deeper than the reviewer (reads full files, not just the diff) and can surface issues the reviewer missed. When the addresser agrees with a suggestion, auto-implement without human approval; escalate only on disagreement or uncertainty. The human's role shifts from approving every change to reviewing the PR diff and calibrating agent judgment over time.

Use structured footnotes (`Persona + Role`) to separate comment chains when both agents post as the same GitHub user. Comments without a Role tag are human.

## Iterative Testing for Timing-Dependent Autonomous Features

Autonomous features with timing-dependent side effects (stale poll auto-cancel, timeout-based cleanup, rate-limiting) need iterative testing with a human watching. The spec gets ~70% right, but edge cases only surface in production: premature cancellation, clock access limitations, permission friction on state persistence. Design the first version, run it live, observe failures, fix, repeat. The loop itself is the test harness.

## Trust-Building Arc as Human-Agent Collaboration Model

The manager-report trust pattern maps directly to human-agent autonomy calibration: small scoped tasks with close review → demonstrate good judgment → gradually expand scope → occasional mistakes that are caught and learned from. Learnings, guidelines, and personas are trust artifacts — accumulated evidence of calibration, not just rules for an agent. This frame is useful for evaluating system changes: does this change help build trust (positive signals, outcome tracking) or just constrain behavior (more rules)?

## Verification: Targeted Grep Over Full File Reads

After subagent writes, verify with `wc -l`, `grep -c`, and a 5-line spot-check — not full file reads. Full reads consume ~8k tokens per batch for equivalent confidence to ~400 tokens of grep. Reserve full reads for debugging when grep checks fail.

## TaskOutput Only Works for Background Bash Tasks

`TaskOutput` with `block: false` works for background Bash commands (`run_in_background: true`), not for background Agent tasks. Agent IDs from `run_in_background` agents are tracked via the automatic notification system — you'll be notified when they complete. Don't poll with `TaskOutput`; it returns "No task found" errors.
