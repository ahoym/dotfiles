# Decision Log

All consolidation actions and judgments, logged for auditability and rollback.

**Format**: Every action (HIGH auto-applied, MEDIUM judged, persona enrichment) gets a row. The Decision column shows `applied`, `blocked`, or `skipped`. The Rationale column explains why — especially important for MEDIUM judgments where the agent exercised autonomous discretion.

| Iter | Content Type | Action | Source | Target | Confidence | Decision | Rationale |
|------|-------------|--------|--------|--------|------------|----------|-----------|
| 1 | LEARNINGS | reference-wire | `learnings/aws-patterns.md` | `commands/set-persona/platform-engineer.md` | MEDIUM | applied | Persona covers infrastructure domain but had no Detailed references section. aws-patterns.md has directly relevant AWS patterns (EventBridge, ECS Fargate). Pattern established by react-frontend and xrpl-typescript-fullstack personas. Reversible. |
| 1 | LEARNINGS | reference-wire | `learnings/vercel-deployment.md` | `commands/set-persona/typescript-devops.md` | MEDIUM | applied | Persona lists "Serverless deployment" as a priority and has inline Vercel gotchas, but no Detailed references section pointing to the dedicated Vercel learnings file. Reversible. |
| 10 | DEEP_DIVE | delete-section | `learnings/skill-design.md` § "Conditional vs Always-Loaded References" | — | HIGH | applied | Internal contradiction: #15 uses `@./reply-templates.md` as "always loaded" example, but #14 explicitly states "@ references in SKILL.md are hints, not auto-load directives" and "neither auto-loads, so the distinction is moot." Also redundant with `claude-md-authoring.md` § "Conditional @ Reference Pattern" for CLAUDE.md context. #14 already provides the correct conditional reference pattern. No unique content lost. |
