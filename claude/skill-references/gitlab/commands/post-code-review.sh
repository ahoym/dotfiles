# GitLab MR review via notes
# Write review body via Write tool, then:
glab api projects/:id/merge_requests/<IID>/notes -F body=@<FILE>
