# GitLab MR review via notes (v2 stub)
# Write review body via Write tool, then:
glab api projects/:id/merge_requests/<IID>/notes -F "body=$(cat <FILE>)"
