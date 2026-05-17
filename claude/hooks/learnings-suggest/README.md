# learnings-suggest

UserPromptSubmit hook that suggests relevant learnings files based on prompt keywords.

## Components

- `src/main.rs` — runtime hook. Reads `sections.json` + per-provider
  `.keyword-index.json`, emits `<learnings-suggestions>` block.
- `src/bin/index-build.rs` — offline indexer. Walks every provider's learnings
  dir, parses section headers, writes `sections.json`.
- `src/bin/read-log.rs` — telemetry reader.
- `analyze.py` — telemetry analyzer.

## Provider model

Providers come from `~/.claude/learnings-providers.json`. Each has a `base`
(the learnings directory) and a `root` (`base.parent()`) — paths are encoded
relative to `root` so `rel` includes the leaf dir (e.g.
`learnings/python-specific.md`). This aligns section-index entries with
hand-curated `.keyword-index.json` paths, which use the same prefix.

Every section in `sections.json` carries `provider: <name>` + `rel`. At runtime,
hits reverse-resolve the provider's `root` and join `rel` to reconstruct the
full path — so suggestions render correctly regardless of where a provider
lives on disk (not hardcoded to `~/.claude/learnings/`).

projectLocal providers exist only at hook runtime (CWD-dependent), so
`index-build` calls `providers(false)` while `main` calls `providers(true)`.

## Indexes

- `~/.claude/claude-artifacts/ast/sections.json` — section-level (preferred)
- `<provider>/.keyword-index.json` — file-level (fallback, curated by `/learnings:curate`)
