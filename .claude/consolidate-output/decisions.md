# Decision Log

All consolidation actions and judgments, logged for auditability and rollback.

**Format**: Every action (HIGH auto-applied, MEDIUM judged, persona enrichment) gets a row. The Decision column shows `applied`, `blocked`, or `skipped`. The Rationale column explains why — especially important for MEDIUM judgments where the agent exercised autonomous discretion.

| Iter | Content Type | Action | Source | Target | Confidence | Decision | Rationale |
|------|-------------|--------|--------|--------|------------|----------|-----------|
| 1 | LEARNINGS | delete duplicate sections | claude-authoring-skills.md | claude-authoring-personas.md (already exists) | HIGH | applied | 8 persona sections (judgment layer, gotchas convention, extends, proactive loads, reviewer personas, compose from learnings, tools encode philosophy, gotchas file convention) were duplicated verbatim in spoke file claude-authoring-personas.md after hub-and-spoke refactor but never removed from source |
| 1 | LEARNINGS | delete file | validation.md | ralph-loop.md (already covered) | HIGH | applied | 12-line file; both sections ("Validate means run it" and "Verify docs against source code") fully covered with more context in ralph-loop.md |
| 1 | LEARNINGS | delete duplicate sections | claude-authoring-guidelines.md | claude-authoring-learnings.md (already exists) | HIGH | applied | 3 cross-cutting authoring sections (genericization, persona-learning boundary test, avoid nesting subdirectories) were duplicated verbatim in claude-authoring-learnings.md — removed from guidelines spoke since they're about learnings organization |
| 2 | SKILLS | fix stale path | ralph:init SKILL.md | — | HIGH | applied | 6 occurrences of `docs/claude-learnings/` replaced with `docs/learnings/` — inconsistent with ralph:brief, ralph:resume, explore-repo, and actual project structure convention. Breaks workflow: init creates projects in path that brief/resume can't find |
| 4 | LEARNINGS | delete duplicate section | claude-authoring-skills.md (Compound Skill: Grep Before Creating New Files) | claude-authoring-learnings.md (Grep Before Creating New Files) | HIGH | applied | Near-verbatim duplicate — both sections have identical content about grepping before creating new learnings files and checking persona references. The learnings version is the general pattern; the skills version was a skill-specific wrapper with no additional content. |
| 4 | LEARNINGS | delete duplicate section | bash-patterns.md (glab api --jq) | gitlab-cli.md (line 15) | HIGH | applied | Same fact about glab api lacking --jq flag. gitlab-cli.md is the natural home for glab CLI knowledge. bash-patterns version added code examples but the core fact is already in gitlab-cli with its own example. |
