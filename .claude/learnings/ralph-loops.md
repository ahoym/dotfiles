# Ralph Loops

## Blanket Tool Blocking > Pattern Matching

For unattended loops, block entire tool classes rather than enumerating dangerous patterns. Research loops only need Read, Write, Edit, Glob, Grep, WebFetch, WebSearch — blanket-blocking Bash eliminates the entire class of prompt injection risks (remote code execution, destructive ops, environment manipulation) in 3 lines instead of 200+ lines of regex that can always be bypassed.

Pattern-matching guards are a game of whack-a-mole. Removing the tool entirely is a brick wall.
