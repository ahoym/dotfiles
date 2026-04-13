# GitLab MRs referencing an issue (v2 stub)
# Uses issue link API — MRs linked via "closes #N" or manual links
glab api projects/:id/issues/<IID>/related_merge_requests --jq '.[] | {iid, source_branch, state, description}'
