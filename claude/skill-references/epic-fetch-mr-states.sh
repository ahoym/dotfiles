#!/usr/bin/env bash
# epic-fetch-mr-states.sh — batch-fetch MR core fields + unaddressed-thread counts
# for a list of MR IIDs in a single GitLab project. Used by epic-fetch-classify
# Phase 4 (epic-state, epic-advance).
#
# Usage:
#   bash epic-fetch-mr-states.sh <project_path> <iid> [<iid> ...]
#
# Args:
#   <project_path>   GitLab project path with slashes (e.g. group/sub/repo).
#                    Will be URL-encoded when calling /discussions.
#   <iid> ...        One or more MR IIDs to fetch.
#
# Output:
#   JSON Lines (one object per MR), in the order IIDs were passed. Fields:
#     iid, state, draft, target_branch, source_branch, web_url,
#     author, assignees, reviewers, merged_at, updated_at, user_notes_count,
#     unaddressed_threads
#
#   On failure to fetch a given MR, the object carries:
#     {"iid": N, "state": "unknown", "error": "<msg>"}
#
# Heuristic for unaddressed_threads (per ~/.claude/skill-references/mr-state-classification.md):
#   A discussion is unaddressed when:
#     - notes[0].resolvable == true
#     - notes[-1].resolved   != true
#     - notes[0].author.username != MR author  AND
#       notes[-1].author.username != MR author
#   Self-posted team-review override: if any system==false note from the MR author
#   exists whose body starts with "## Team Review:", count ALL resolvable-unresolved
#   threads on that MR regardless of who authored them.
#
# Notes:
#   - Discussions are paginated via --paginate.
#   - MRs are fetched sequentially (typical epic has <10 MRs; parallel speedup small).

set -u

if [[ $# -lt 2 ]]; then
  echo "Usage: bash $0 <project_path> <iid> [<iid> ...]" >&2
  exit 64
fi

PROJ="$1"; shift
# URL-encode slashes in project path for /discussions endpoint
PROJ_ENC="${PROJ//\//%2F}"

for iid in "$@"; do
  # Core fields via glab mr view
  if ! mr_json=$(glab mr view "$iid" -R "$PROJ" --output json 2>/dev/null); then
    jq -nc --argjson iid "$iid" '{iid:$iid, state:"unknown", error:"glab mr view failed"}'
    continue
  fi

  author=$(jq -r '.author.username // ""' <<<"$mr_json")

  # Discussions (paginated). May return [] on 404/perms.
  # --paginate emits one JSON array PER PAGE; jq -s 'add' merges them into a
  # single array so the downstream filters see one document (>20 discussions
  # would otherwise yield multi-line jq output and break --argjson).
  discussions=$(glab api "projects/${PROJ_ENC}/merge_requests/${iid}/discussions" --paginate 2>/dev/null | jq -s 'add // []' || echo '[]')

  # Self-posted team-review override: any non-system note from the MR author
  # starting with "## Team Review:" in any discussion.
  has_self_review=$(jq -r --arg author "$author" '
    any(.[]?.notes[]?;
      .system == false
      and .author.username == $author
      and (.body // "" | startswith("## Team Review:"))
    )
  ' <<<"$discussions" 2>/dev/null || echo false)

  if [[ "$has_self_review" == "true" ]]; then
    # Count every resolvable-unresolved thread regardless of author
    unaddressed=$(jq '[.[] | select(.notes[0].resolvable == true) | select((.notes[-1].resolved // false) == false)] | length' <<<"$discussions" 2>/dev/null || echo 0)
  else
    unaddressed=$(jq --arg author "$author" '
      [.[]
        | select(.notes[0].resolvable == true)
        | select((.notes[-1].resolved // false) == false)
        | select(.notes[0].author.username != $author)
        | select(.notes[-1].author.username != $author)
      ] | length
    ' <<<"$discussions" 2>/dev/null || echo 0)
  fi

  jq -c --argjson unaddressed "${unaddressed:-0}" '{
    iid: .iid,
    state: .state,
    draft: .draft,
    target_branch: .target_branch,
    source_branch: .source_branch,
    web_url: .web_url,
    author: (.author.username // null),
    assignees: [.assignees[]?.username],
    reviewers: [.reviewers[]?.username],
    merged_at: .merged_at,
    updated_at: .updated_at,
    user_notes_count: .user_notes_count,
    unaddressed_threads: $unaddressed
  }' <<<"$mr_json"
done
