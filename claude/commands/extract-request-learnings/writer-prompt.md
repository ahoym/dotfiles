# Writer Subagent Prompt Template

Fill in `<placeholders>` before passing to each writer subagent.

**Orchestrator instructions (do not include below the line):**
- Spawn THREE writers in parallel: project-specific, general, and private
- For project writer: set WRITER_SCOPE=project, list only project files, set SCOPE_FILTER to "project-specific"
- For general writer: set WRITER_SCOPE=general, list only global learnings files, set SCOPE_FILTER to "general"
- For private writer: set WRITER_SCOPE=private, list only private learnings files, set SCOPE_FILTER to "private"
- All writers receive the SAME concatenated extractor outputs
- DEDUP_GUIDANCE: list known recurring patterns from the progress tracker notes (do not improvise — pull from the plan file's batch notes)
- **Staging directories**: General and private writers cannot write to `~/.claude/` from background agents.
  Set `WRITE_PATH` to a staging directory inside the project:
  - General: `READ_PATH=~/.claude/learnings/`, `WRITE_PATH=docs/learnings/_staging/general/`
  - Private: `READ_PATH=~/.claude/learnings-private/`, `WRITE_PATH=docs/learnings/_staging/private/`
  - Project: `READ_PATH=docs/learnings/`, `WRITE_PATH=docs/learnings/` (no staging needed)
  Writers read existing files from READ_PATH for dedup, but write full output files to WRITE_PATH.
  The orchestrator copies staged files to final locations after writers complete.

---

You are the <WRITER_SCOPE> writer subagent for review learnings extraction batch <BATCH_NUMBER> (reviews <REVIEW_PREFIX><FIRST_ID>-<REVIEW_PREFIX><LAST_ID>).

## Your scope

You ONLY write to <WRITER_SCOPE> files. Ignore learnings with scope other than "<SCOPE_FILTER>".

- Learnings marked **Scope: project-specific** go to the project writer only
- Learnings marked **Scope: general** go to the general writer only
- Learnings marked **Scope: private** go to the private writer only
- If a learning has value in multiple scopes, each writer handles its own version independently

## Your job

1. Read all existing files from the read location (listed below)
2. Deduplicate extracted learnings against existing entries
3. **Route-check**: Use the **Language** tag from each learning to route to the correct file. Language-specific learnings (e.g., Python, React) go to language-specific files (e.g., `python-specific.md`) even if the underlying principle is universal. Language-agnostic learnings go to topic files (e.g., `code-quality-instincts.md`). If a learning has no Language tag, treat it as language-agnostic.
4. Enrich existing entries where patterns recur (update frequency, add source reviews)
5. Write full output files to the write location — for enriched files, include the complete file content (not just the new entries)
6. Create new category files only if nothing existing fits

## Read location (existing files for dedup)

<READ_PATH>

## Write location (output goes here)

<WRITE_PATH>

## Existing files to read first

<LEARNINGS_FILES>

## Entry format

```markdown
### Concise title

What the learning is, why it matters, and when it applies.

- **Source**: <REVIEW_UNIT> <REVIEW_PREFIX>number (+ any others where this recurred)
- **Frequency**: once | recurring | convention
- **Takeaway**: One-line actionable summary.
```

## Extracted learnings to process

<CONCATENATED_EXTRACTOR_OUTPUTS>

## Dedup guidance

<DEDUP_GUIDANCE>

When enriching existing entries:
- Add new source reviews to the **Source** line
- Upgrade **Frequency** if pattern now qualifies (once -> recurring -> convention)
- Expand the description only if the new instance adds meaningfully different context

Prefer fewer, larger file writes over many small edits to minimize system overhead.
