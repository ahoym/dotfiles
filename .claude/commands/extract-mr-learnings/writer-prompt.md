# Writer Subagent Prompt Template

Fill in `<placeholders>` before passing to each writer subagent.

**Orchestrator instructions (do not include below the line):**
- Spawn TWO writers in parallel: one project-specific, one general
- For project writer: set WRITER_SCOPE=project, list only project files, set SCOPE_FILTER to "project-specific"
- For general writer: set WRITER_SCOPE=general, list only global files, set SCOPE_FILTER to "general"
- Both writers receive the SAME concatenated extractor outputs
- DEDUP_GUIDANCE: list known recurring patterns from the progress tracker notes (do not improvise — pull from the plan file's batch notes)

---

You are the <WRITER_SCOPE> writer subagent for PR learnings extraction batch <BATCH_NUMBER> (PRs #<FIRST_NUMBER>-#<LAST_NUMBER>).

## Your scope

You ONLY write to <WRITER_SCOPE> files. Ignore learnings with scope other than "<SCOPE_FILTER>".

- Learnings marked **Scope: project-specific** go to the project writer only
- Learnings marked **Scope: general** go to the general writer only
- If a learning has value in both scopes, each writer handles its own version independently

## Your job

1. Read all existing files in your location (listed below)
2. Deduplicate extracted learnings against existing entries
3. Enrich existing entries where patterns recur (update frequency, add source PRs)
4. Append new learnings to the appropriate category files
5. Create new category files only if nothing existing fits

## Write location

<LEARNINGS_PATH>

## Existing files to read first

<LEARNINGS_FILES>

## Entry format

```markdown
### Concise title

What the learning is, why it matters, and when it applies.

- **Source**: PR #number (+ any others where this recurred)
- **Frequency**: once | recurring | convention
- **Takeaway**: One-line actionable summary.
```

## Extracted learnings to process

<CONCATENATED_EXTRACTOR_OUTPUTS>

## Dedup guidance

<DEDUP_GUIDANCE>

When enriching existing entries:
- Add new source PRs to the **Source** line
- Upgrade **Frequency** if pattern now qualifies (once -> recurring -> convention)
- Expand the description only if the new instance adds meaningfully different context

Prefer fewer, larger file writes over many small edits to minimize system overhead.
