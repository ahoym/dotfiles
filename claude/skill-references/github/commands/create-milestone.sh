# Create a GitHub milestone. No native `gh milestone` subcommand exists —
# use the REST API directly. After creation, reference the milestone by
# its title via `gh issue create --milestone <TITLE>`.
#
# NOTE: -f field=value triggers a gh-api security warning when DESCRIPTION
# contains `###` markdown headings (see learnings/bash-patterns.md). For
# multi-line / heading-bearing descriptions, switch to stdin form:
#   printf '%s' "$DESCRIPTION" | gh api repos/<OWNER>/<REPO>/milestones \
#     --method POST -f title=<TITLE> --input -
gh api repos/<OWNER>/<REPO>/milestones --method POST \
  -f title=<TITLE> \
  -f description=<DESCRIPTION> \
  --jq '{number, title, html_url}'
