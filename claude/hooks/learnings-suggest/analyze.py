#!/usr/bin/env python3
"""Cross-reference suggest.jsonl and reads.jsonl to compute suggestion hit rates.

Manual invocation — produces a tuning report. Pair every suggested path with
any Read of the same file (path normalized to relative-from-~) that happened
within MATCH_WINDOW_SEC of the suggestion in the same session.

Outputs three panels:
  - Tier hit rates: did [strong] / [weak] tiers actually get loaded?
  - Top performers: files where suggestions consistently lead to loads
  - Noise candidates: files often suggested but rarely loaded
  - Coverage gaps: files often loaded but never suggested
"""

import json
import os
import sys
from collections import defaultdict
from pathlib import Path

ART = Path.home() / ".claude" / "claude-artifacts" / "ast"
SUGGEST_LOG = ART / "suggest.jsonl"
READS_LOG = ART / "reads.jsonl"
MATCH_WINDOW_SEC = 300  # 5 min: Read must come within this window of the suggestion
DEFAULT_LOOKBACK_DAYS = 7


def load_jsonl(path):
    if not path.exists():
        return []
    out = []
    with path.open() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                out.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return out


def normalize_path(p):
    """Map absolute paths and `~/.claude/...` to a comparable form."""
    if not p:
        return ""
    home = str(Path.home())
    if p.startswith("~/"):
        p = home + p[1:]
    p = str(Path(p).resolve()) if Path(p).exists() else p
    # Strip the homedir prefix for readability
    if p.startswith(home + "/"):
        p = "~" + p[len(home):]
    return p


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=DEFAULT_LOOKBACK_DAYS)
    ap.add_argument("--top", type=int, default=10)
    args = ap.parse_args()

    suggests = load_jsonl(SUGGEST_LOG)
    reads = load_jsonl(READS_LOG)

    if not suggests:
        print(f"No suggestion log at {SUGGEST_LOG}", file=sys.stderr)
        sys.exit(1)

    cutoff = max(s.get("ts", 0) for s in suggests) - args.days * 86400
    suggests = [s for s in suggests if s.get("ts", 0) >= cutoff]
    reads = [r for r in reads if r.get("ts", 0) >= cutoff]

    # Build session → sorted-reads index for O(R) lookups
    reads_by_session = defaultdict(list)
    for r in reads:
        reads_by_session[r.get("session") or "_"].append((r.get("ts", 0), normalize_path(r.get("path", ""))))
    for sess in reads_by_session.values():
        sess.sort()

    # Per-tier and per-file outcome counts
    tier_counts = defaultdict(lambda: {"suggested": 0, "loaded": 0})
    file_suggested = defaultdict(int)
    file_loaded_from_suggest = defaultdict(int)
    prompts_with_suggestions = 0
    total_prompts = len(suggests)

    for s in suggests:
        hits = s.get("hits") or []
        if hits:
            prompts_with_suggestions += 1
        s_ts = s.get("ts", 0)
        s_sess = s.get("session") or "_"
        session_reads = reads_by_session.get(s_sess, [])
        # In-window read paths
        window = {
            p for (ts, p) in session_reads
            if s_ts <= ts <= s_ts + MATCH_WINDOW_SEC
        }
        for hit in hits:
            path = normalize_path(hit.get("path", ""))
            tier = hit.get("tier", "weak")
            tier_counts[tier]["suggested"] += 1
            file_suggested[path] += 1
            if path in window:
                tier_counts[tier]["loaded"] += 1
                file_loaded_from_suggest[path] += 1

    # Files Read but never suggested in their window
    file_loaded_unsolicited = defaultdict(int)
    suggested_paths_seen = set(file_suggested.keys())
    for sess, entries in reads_by_session.items():
        # All reads where there was no preceding-window suggestion of the same path
        # (cheap approximation: count reads of files that never appear in suggestions at all)
        for ts, p in entries:
            if p not in suggested_paths_seen:
                file_loaded_unsolicited[p] += 1

    def panel(title):
        print(f"\n{title}")
        print("=" * len(title))

    panel(f"Suggestion telemetry — last {args.days} days")
    print(f"Total prompts logged:        {total_prompts}")
    pct = (100 * prompts_with_suggestions // total_prompts) if total_prompts else 0
    print(f"Suggestions fired:           {prompts_with_suggestions}  ({pct}%)")
    for tier in ("strong", "weak"):
        c = tier_counts[tier]
        rate = (100 * c["loaded"] // c["suggested"]) if c["suggested"] else 0
        print(f"  [{tier}] tier:               {c['suggested']:4d}  hit rate {rate}%  ({c['loaded']} loads)")

    panel("Top performers (suggested → loaded)")
    perf = sorted(file_suggested.items(), key=lambda kv: -file_loaded_from_suggest.get(kv[0], 0))
    for path, n_suggested in perf[: args.top]:
        n_loaded = file_loaded_from_suggest.get(path, 0)
        rate = (100 * n_loaded // n_suggested) if n_suggested else 0
        if n_loaded == 0:
            continue
        print(f"  {path:<55}  {n_suggested:3d} →  {n_loaded:3d}  ({rate}%)")

    panel("Noise candidates (suggested ≥3 times, never loaded)")
    noise = [(p, n) for p, n in file_suggested.items() if n >= 3 and file_loaded_from_suggest.get(p, 0) == 0]
    noise.sort(key=lambda kv: -kv[1])
    if not noise:
        print("  (none)")
    for path, n in noise[: args.top]:
        print(f"  {path:<55}  {n:3d} suggestions, 0 loaded")

    panel("Coverage gaps (loaded ≥3 times, never suggested)")
    gaps = sorted(file_loaded_unsolicited.items(), key=lambda kv: -kv[1])
    gaps = [(p, n) for p, n in gaps if n >= 3]
    if not gaps:
        print("  (none)")
    for path, n in gaps[: args.top]:
        print(f"  {path:<55}  {n:3d} loads, 0 suggestions")


if __name__ == "__main__":
    main()
