# Comparison Checklist

Aspects to compare when evaluating duplicate Ralph loop directories.

## Comparison Aspects

| Aspect | What to Compare |
|--------|-----------------|
| **File structure** | Which has more files? Are there unique files in each? |
| **progress.md** | Which has more iterations? Better tracking? |
| **spec.md** | Which follows the structured Ralph loop format? v1 vs v2? |
| **Research depth** | Compare line counts and topic coverage in info.md |
| **Implementation detail** | Which has code examples, phase breakdowns, PR strategy? |
| **Assumptions documented** | Does one have an assumptions-and-questions.md? |
| **Logs** | Does one have iteration logs showing execution history? |
| **Deep research files** | Which has separate topic.md files for deep dives? |

## Signs One Directory is Superseded

1. **Minimal progress.md** - Just completion marker vs full structured tracking
2. **Shorter research** - Significantly fewer lines in info.md
3. **Less structured spec** - Informal vs proper Ralph loop format
4. **No iteration logs** - Suggests single incomplete run vs multiple iterations
5. **Missing documentation** - No assumptions, codebase analysis, or Q&A
6. **v1 spec vs v2 spec** - v1 has fixed 4 tasks, v2 has dynamic task generation

## Quick Comparison Table Template

```markdown
| Aspect | Dir A | Dir B |
|--------|-------|-------|
| Total files | X | Y |
| Iterations tracked | N | M |
| Research lines (info.md) | ~200 | ~500 |
| Implementation phases | 6 | 10 |
| Has assumptions doc | No | Yes |
| Has iteration logs | No | Yes |
| Spec version | v1 | v2 |
| Deep research files | 0 | 3 |
```

## Porting Decision

Before deleting the superseded directory:

1. Read unique files in both directories
2. Search for any sections not covered in the newer version
3. If found, port specific sections (not whole files)
4. Usually nothing needs porting - newer version is comprehensive

## When to Consolidate Instead

Consolidate (rather than delete) when directories evolved independently and contain unique valuable content:

- Different spec versions with distinct features worth keeping
- Deep research files in one, core docs in another
- Different iteration counts with complementary (not overlapping) coverage

See the "Consolidating Duplicate Ralph Loop Projects" section in `docs/learnings/ralph-loop-usage.md` for the full consolidation process.
