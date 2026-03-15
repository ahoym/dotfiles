# Deep Dive Methodology

Read by the consolidation agent when `PHASE` is `DEEP_DIVE`. Not needed during broad sweeps.

## Per-File Execution

Each deep dive invocation processes ONE file (preserves the one-sweep-per-invocation model):

1. **Read `.claude/commands/learnings/curate/SKILL.md`** and follow its Content Mode methodology (steps 2–6) for the target file. Overrides for autonomous context:
   - **Step 1 (target)**: Already determined — use the next file from DEEP_DIVE_CANDIDATES
   - **Step 7 (report)**: Skip — no interactive report needed
   - **Step 8 (approval)**: Instead of `AskUserQuestion`, auto-apply HIGHs and MEDIUMs (log each in decisions.md with rationale). Record LOWs in review.md.
   - **Step 9 (results)**: Skip — output files serve this purpose
2. **Compound insights** if findings were applied (same methodology as broad sweep step 8 in spec.md)
3. **Update output files** — increment SWEEP_COUNT, append iteration log, move file from DEEP_DIVE_CANDIDATES to DEEP_DIVE_COMPLETED
4. **Update tracker** — set the deep-dived file's `last_deep_dive_run` to current `run_count` in `deep-dive-tracker.json`. Write the updated tracker to disk.
5. **Commit**: `consolidate: deep-dive N — <filename> (<summary>)`

## Bounded — No Re-Convergence

Deep dives do NOT cascade back to broad sweeps. Rationale:
- Broad sweeps already confirmed no cross-file regressions exist
- Deep dive changes are small (pattern-level, not file-level)
- Cross-file effects are logged in decisions.md for the next consolidation run

After all candidates processed → completion (`WOOT_COMPLETE_WOOT`).

## Max Guard

If deep dives exceed 15 invocations without completing all candidates, stop with `MAX_DEEP_DIVES_HIT`:
1. Write `MAX_DEEP_DIVES_HIT` as the first line of progress.md
2. Update report.md status to `MAX_DEEP_DIVES_HIT`
3. Add to review.md with `[MAX-DEEP-DIVES]` tag: "Deep dive phase hit 15-invocation limit — remaining candidates need manual curation"
4. List remaining unprocessed candidates in the entry

Typical runs should have 10–15 candidates (minimum floor + organic). The 15-invocation limit is a safety net.
