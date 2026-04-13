# All open issues (default limit 30)
gh issue list --state open --json number,title,body,labels,assignees --limit <LIMIT>

# Filtered by label (repeat --label for multiple, AND logic):
# gh issue list --state open --label <LABEL> --json number,title,body,labels,assignees --limit <LIMIT>
