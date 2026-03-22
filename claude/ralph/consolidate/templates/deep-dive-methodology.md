# Deep Dive Methodology

Read by the consolidation agent when `PHASE` is `DEEP_DIVE`. Not needed during broad sweeps.

## Per-Invocation Execution

Each deep dive invocation processes either a **cluster batch** (all candidate files in a cluster subdirectory) or a **single unclustered file**. Check the next entry in DEEP_DIVE_CANDIDATES to determine which mode.

### Cluster Batch (learnings in a subdirectory)

1. **Read all cluster files** in parallel (e.g., all files in `claude/learnings/frontend/`)
2. **Read `claude/commands/learnings/curate/SKILL.md`** for Content Mode methodology
3. **Iterate through each file** in the cluster, applying Content Mode (steps 2–6) per file. For each file:
   - Overrides for autonomous context (same as unclustered):
     - **Step 7 (report)**: Skip
     - **Step 8 (approval)**: Auto-apply HIGHs and MEDIUMs (log each in decisions.md with rationale). Record LOWs in review.md.
     - **Step 9 (results)**: Skip
   - The full cluster is in context — leverage this for intra-cluster cross-referencing
4. **Structural opportunity scans** (after per-file analysis):
   - **Merge for cohesion**: 2+ files in the cluster where a combined version would be more discoverable. MEDIUM auto-apply.
   - **Split for discoverability**: A cluster file >150 lines with 3+ distinct sub-topics that have independent lookup value. MEDIUM auto-apply.
   - These scans are most effective at cluster level where all files are in context simultaneously.
5. **Compound insights** if findings were applied (same methodology as broad sweep step 8 in spec.md)
6. **Update output files** — increment SWEEP_COUNT, append iteration log row (`| N | DEEP_DIVE | cluster-name (K files) | ... |`), move cluster from DEEP_DIVE_CANDIDATES to DEEP_DIVE_COMPLETED
7. **Update tracker** — set `last_deep_dive_run` to current `run_count` for ALL files in the cluster (not just those with findings) in `deep-dive-tracker.json`. Write the updated tracker to disk.
8. **Commit**: `git commit -m "consolidate: deep-dive N — cluster-name (K files, summary)"`

### Unclustered File (single file)

1. **Read `claude/commands/learnings/curate/SKILL.md`** and follow its Content Mode methodology (steps 2–6) for the target file. For `skill-references/*` files, apply the **reference-file gate** (learnings:curate step 4a): deduplication is removed from consuming skills, not from the reference. Overrides for autonomous context:
   - **Step 1 (target)**: Already determined — use the next file from DEEP_DIVE_CANDIDATES
   - **Step 7 (report)**: Skip — no interactive report needed
   - **Step 8 (approval)**: Instead of `AskUserQuestion`, auto-apply HIGHs and MEDIUMs (log each in decisions.md with rationale). Record LOWs in review.md.
   - **Step 9 (results)**: Skip — output files serve this purpose
2. **Compound insights** if findings were applied (same methodology as broad sweep step 8 in spec.md)
3. **Update output files** — increment SWEEP_COUNT, append iteration log, move file from DEEP_DIVE_CANDIDATES to DEEP_DIVE_COMPLETED
4. **Update tracker** — set the deep-dived file's `last_deep_dive_run` to current `run_count` in `deep-dive-tracker.json`. Write the updated tracker to disk.
5. **Commit**: `git commit -m "consolidate: deep-dive N — filename (summary)"`

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

With cluster batching, 15 invocations covers significantly more files than before. The `min_deep_dives` floor (default 20) is a file count, not invocation count — a typical run processes 20+ files in 5-10 invocations.
