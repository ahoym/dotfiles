---
name: session-retro
description: "Run end-of-session retrospective: compound learnings, then discuss skill performance, communication, and improvements."
allowed-tools:
  - Skill
  - AskUserQuestion
---

# Session Retro

End-of-session routine that captures learnings and facilitates a retrospective.

## Usage

- `/session-retro` - Run the full end-of-session retro

## Instructions

1. **Compound learnings**: Invoke `/learnings:compound` using the Skill tool. Wait for it to complete fully before continuing.

2. **Skill performance**: Share your observations on how the skills used this session performed — what went well, what was rough. Include a **learnings load review** with provenance tracking — for each learnings file that was loaded or referenced, note *how* it was loaded:

   | Source | Meaning |
   |--------|---------|
   | **Index** | Read via `~/.claude/learnings/CLAUDE.md` index lookup |
   | **Hard gate** | Session-start glob, plan-mode entry, or implementation-start check |
   | **Soft gate** | Confidence-level check, friction-triggered, or keyword-triggered |
   | **Persona proactive** | Listed in the active persona's `## Proactive Cross-Refs` |
   | **Skill reference** | Read because a skill's instructions or reference files pointed to it |
   | **Operator-prompted** | Read because the operator asked a question or raised a topic that required it |
   | **Self-directed** | Read on own initiative to inform a decision, without a gate or prompt triggering it |
   | **Cross-ref** | Followed from a `## Cross-Refs` in another loaded file |

   Include a **Loaded?** column with three states to track actual context cost:

   | Value | Meaning | Cost |
   |-------|---------|------|
   | **Yes** | Full read into context | Real token cost |
   | **Sniffed** | Opened briefly to check relevance (offset+limit read, first few lines) | Small cost |
   | **No** | Known reference, never opened (e.g., listed in persona's Cross-Refs) | Zero cost |

   This distinction calibrates whether proactive cross-refs are earning their context cost.

   This surfaces whether the search protocol is doing its job or whether useful files are only reached via persona coverage or manual reads. Also note: which files influenced decisions, which were noise, whether any useful files were missed, and whether any soft gates *should have* fired but didn't.

   Then ask the operator for their perspective. Discuss naturally.

3. **Communication quality**: Share your honest assessment of how communication went — specific moments that worked, things you could've done better. Then ask the operator for their take. Discuss naturally.

4. **Improvements**: Share your ideas for improvements based on the above. As part of this, consider: did anything this session reveal a guideline that's missing, redundant, or out of sync with how we actually work? Then ask the operator if they have additional ideas. Discuss and capture anything actionable.

5. **Final compound**: Once all discussion is complete, invoke `/learnings:compound` again using the Skill tool. The retro discussion itself often produces new insights worth capturing — patterns noticed, guidelines proposed, communication preferences clarified. This second pass ensures those don't get lost.

Run each step sequentially. Lead with your own perspective at each stage, then invite the operator's — this is a two-way retro, not an interview. **Do not advance to the next step until the operator signals they're done with the current one.** Ask explicitly before moving on.

**This is a conversation, not a facilitated meeting.** The numbered steps are topics, not a script. Don't rush through them. Don't end every message with a formulaic handoff question ("What's your take?", "Ready to move on?"). Respond to what the operator actually said — follow up, push back, go deeper. Match the operator's pace and energy. If a topic has legs, stay on it. The steps exist so nothing gets skipped, not so you can optimize for completion.

**Be verbose and genuinely reflective.** Don't summarize — share your full thinking. Name specific moments, what worked, what you'd do differently, and why. The best retro insights come from detailed honest reflection, not polished bullet points. If you're holding back a thought, say it.
