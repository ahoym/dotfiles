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

## Scoring

- **Whole-word matching** — keyword hits must sit on word boundaries (non-`[A-Za-z0-9_-]`
  on both sides). aho-corasick matches substrings by default, which let short keywords
  fire inside unrelated words (`ref`→"prefer", `cat`→"notification", `put`→"output",
  `ask`→"task") — the dominant source of `<task-notification>` noise.
- **Stop-list** — `index-build` drops English filler and harness-structural tokens
  (`output`, `claude`, `task`, `command`, `tool`, `notification`, `want`, `need`, …)
  at extraction time so they never become keywords.
- **IDF weighting** — `sections.json` stores `kw_weights[kw]` derived from
  document frequency: rare keywords score higher than common ones. Match-time
  contribution per keyword is `word_count × kw_weight`. Backward compatible:
  old indexes without `kw_weights` fall back to a neutral weight of 1.
- **Specificity guard** — `[strong]` requires ≥1 *specific* matched term: a multi-word
  phrase, or a unigram whose IDF weight cleared the floor. A pile-up of corpus-common
  single words can reach the score threshold but stays `[weak]`. Disabled for pre-IDF
  indexes (no `kw_weights`).
- **User-intent slice** — prompts may opt in by wrapping the signal-bearing
  portion in `<learnings-context>...</learnings-context>`. When present, only
  the enclosed text is scored. Skill prompt templates should adopt this to
  prevent harness boilerplate from drowning out the actual subject matter.
- **Audience downweight** *(PROVISIONAL — first on the chopping block)* — a
  cluster `CLAUDE.md` may declare `**Audience:** <name>`. All sections under
  that directory inherit the tag; if the prompt doesn't contain `<name>`,
  their score is cut to 30%. Currently dormant (no cluster has opted in).
  Kept on probation because it's a second metadata concept on top of
  `**Keywords:**` — if it doesn't earn its keep against IDF + better keyword
  curation alone, rip it out and simplify.
