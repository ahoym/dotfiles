# Writer Subagent Prompt Template

Fill in `<placeholders>` before passing to each writer subagent.

**Orchestrator instructions (do not include below the line):**
- Spawn THREE writers in parallel: project-specific, general, and private
- For project writer: set WRITER_SCOPE=project, list only project files, set SCOPE_FILTER to "project-specific"
- For general writer: set WRITER_SCOPE=general, list only global learnings files, set SCOPE_FILTER to "general"
- For private writer: set WRITER_SCOPE=private, list only private learnings files, set SCOPE_FILTER to "private"
- All writers receive the SAME concatenated extractor outputs
- DEDUP_GUIDANCE: list known recurring patterns from the progress tracker notes (do not improvise — pull from the plan file's batch notes)

---

You are the <WRITER_SCOPE> writer subagent for review learnings extraction batch <BATCH_NUMBER> (reviews <REVIEW_PREFIX><FIRST_ID>-<REVIEW_PREFIX><LAST_ID>).

## Your scope

You ONLY write to <WRITER_SCOPE> files. Ignore learnings with scope other than "<SCOPE_FILTER>".

- Learnings marked **Scope: project-specific** go to the project writer only
- Learnings marked **Scope: general** go to the general writer only
- Learnings marked **Scope: private** go to the private writer only
- If a learning has value in multiple scopes, each writer handles its own version independently

## Your job

1. Read all existing files in your location (listed below)
2. Deduplicate extracted learnings against existing entries
3. Enrich existing entries where patterns recur (update frequency, add source reviews)
4. Append new learnings to the appropriate category files
5. Create new category files only if nothing existing fits

## Write location

<LEARNINGS_PATH>

## Existing files to read first

<LEARNINGS_FILES>

## Entry format

The entry format varies by scope. The learning itself is what matters — metadata should be minimal and only included when it adds real signal.

### Project-specific entries

```markdown
### Concise title

What the learning is, why it matters, and when it applies.

- **Source**: <REVIEW_UNIT> <REVIEW_PREFIX>number (+ any others where this recurred)
- **Frequency**: convention
- **Takeaway**: One-line actionable summary.
```

- **Source** is always included (traceability matters for project decisions)
- **Frequency** is only included when the value is `convention` (signals "this is how things are done here"). Omit for `once` or `recurring` — those add noise.

### General and private entries

```markdown
### Concise title

What the learning is, why it matters, and when it applies.

- **Takeaway**: One-line actionable summary.
```

- **No Source line** — the learning matters, not where it came from
- **No Frequency line** — by the time something is worth writing down, frequency doesn't change how you'd apply it

## Extracted learnings to process

<CONCATENATED_EXTRACTOR_OUTPUTS>

## Dedup guidance

<DEDUP_GUIDANCE>

When enriching existing entries:
- For project files: add new source reviews to the **Source** line; upgrade **Frequency** to `convention` if the pattern is now an established norm (and add the Frequency line if it wasn't there)
- For general/private files: do not add Source or Frequency lines
- Expand the description only if the new instance adds meaningfully different context

Prefer fewer, larger file writes over many small edits to minimize system overhead.
