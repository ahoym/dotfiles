# Metadata + mode detection only (state, author, target_branch, merged_at).
# The -c flag was dropped: its Notes array silently truncates at 20 (first page, no pagination).
# For comment iteration, always follow with the paginated notes endpoint — see the fetch-inline-comments prescription.
glab mr view <number> -F json
