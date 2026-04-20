# Convergence Verifier

> **SUPERSEDED** (2026-04-12): Implemented as standalone-first skill `/verify-business-logic`. See:
> - Skill: `claude/commands/git/verify-business-logic/SKILL.md`
> - Persona: `claude/commands/set-persona/convergence-verifier.md`
> - Director integration: Phase 1 (intent capture) + Phase 5 (verifier invocation) in `claude/commands/director/SKILL.md`
>
> Key design change from this plan: verifier is a standalone skill the director calls, not a director-internal phase. Output is a top-level PR comment (not local-only). Intent capture splits: lightweight version in verifier (standalone), full negotiation in director.
