# Skill Mode (commands)

## 2. Read the skill package

For the target skill directory:
1. Read `SKILL.md` (main instructions)
2. List and read all reference files in the skill directory
3. Note the skill's description, usage patterns, and reference file count

## 3. Evaluate the skill

Using the Skill Pruning Criteria in classification-model.md, evaluate:

| Dimension | What to check |
|-----------|---------------|
| **Relevance** | Is the workflow this skill automates still used? |
| **Overlap** | Does another skill do 80%+ the same thing? |
| **Complexity vs value** | Does the skill's complexity justify its usage frequency? |
| **Reference freshness** | Are reference files current, or do they reference stale patterns? |
| **Scope** | Is the skill too broad (should split) or too narrow (should merge)? |

Also check:
- Does the skill have reference files that could be pruned or consolidated?
- Is the skill description accurate for what it actually does?
- Are there missing reference files that would improve execution?
- **Cross-skill reference deduplication:** Compare reference files against companion skills — especially producer/consumer pairs. Check for >80% content overlap. The superset version is usually in the skill that uses the content more heavily. Resolution: move the superset to `skill-reference/` and update both skills to reference the shared path.
- **Producer/consumer contract validation:** When two skills form a producer/consumer pair, validate that the producer generates every section the consumer expects. A term appearing in the consumer doesn't mean the producer actually generates it.

## 4. Classify the skill

| Classification | Description |
|----------------|-------------|
| **Keep** | Skill is relevant, well-scoped, and reference files are current |
| **Enhance** | Skill is useful but missing context, reference files, or coverage |
| **Merge** | Skill overlaps significantly with another — combine them |
| **Split** | Skill is too broad — break into focused skills |
| **Prune** | Skill is outdated, too specialized, or easily done manually |

For each classification, note:
- **Confidence**: High/Medium/Low
- **Rationale**: Why this classification
- **Target**: If merging/enhancing, which skill?

## Skill Report Format

```
## Skill Curation: <skill-name>

### Overview
- **Description**: ...
- **Files**: SKILL.md + N reference files
- **Classification**: Keep / Enhance / Merge / Split / Prune
- **Confidence**: High/Medium/Low

### Evaluation
- **Relevance**: ...
- **Overlap**: ...
- **Reference freshness**: ...
- **Scope**: ...

### Recommended Actions
- [ ] Action 1
- [ ] Action 2
```

## Skill Mode Apply Actions

- Enhance: add missing reference files or context to the skill
- Merge: combine two skills into one, delete the redundant one
- Split: create new skill directories, distribute content
- Prune: delete the skill directory (with approval)

## Skill Mode Example

```
User: /learnings:curate commands/git/monitor-pr-comments

Claude:
## Skill Curation: git-monitor-pr-comments

### Overview
- **Description**: Watch a PR in background and address new comments
- **Files**: SKILL.md + 2 scripts (init-tracking.sh, monitor-script.sh)
- **Classification**: Prune
- **Confidence**: Medium

### Evaluation
- **Relevance**: Specialized — background polling for PR comments
- **Overlap**: Partially overlaps with git-address-pr-review
- **Complexity vs value**: Requires background agent setup for occasional use
- **Reference freshness**: Scripts are current

### Recommended Actions
- [ ] Prune skill (complex setup, rare use case)

Apply? [Apply all] [Discuss] [Skip]
```
