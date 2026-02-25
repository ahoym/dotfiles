# Ralph Loops

## Blanket Tool Blocking > Pattern Matching

For unattended loops, block entire tool classes rather than enumerating dangerous patterns. Research loops only need Read, Write, Edit, Glob, Grep, WebFetch, WebSearch — blanket-blocking Bash eliminates the entire class of prompt injection risks (remote code execution, destructive ops, environment manipulation) in 3 lines instead of 200+ lines of regex that can always be bypassed.

Pattern-matching guards are a game of whack-a-mole. Removing the tool entirely is a brick wall.

## Plan vs Reality Delta Check

Before implementing a plan, compare it against existing code to find the actual delta. Plans are often written before implementation begins — by the time you execute, much may already exist. Read all relevant files first, identify what's already done, and only implement what's actually missing. This avoids redundant work and keeps changes minimal.
