# Create a GitHub milestone. No native `gh milestone` subcommand exists —
# use the REST API directly. After creation, reference the milestone by
# its title via `gh issue create --milestone <TITLE>`.
gh api repos/<OWNER>/<REPO>/milestones --method POST \
  -f title=<TITLE> \
  -f description=<DESCRIPTION> \
  --jq '{number, title, html_url}'
