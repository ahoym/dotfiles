Statusline script authoring: JSON schema, subprocess environment constraints, and field availability timing.
- **Keywords:** statusline, status line, terminal width, rate_limits, resets_at, context_window, tput, stty, /dev/tty
- **Related:** ~/.claude/learnings/bash-patterns.md

## JSON Schema

Top-level keys available to statusline scripts: `context_window`, `cost`, `cwd`, `exceeds_200k_tokens`, `model`, `output_style`, `rate_limits`, `session_id`, `transcript_path`, `version`, `vim`, `workspace`.

Key nested structures:
- `rate_limits.five_hour` / `seven_day`: `{ used_percentage, resets_at }` — `resets_at` is a unix timestamp
- `context_window`: `used_percentage`, `remaining_percentage`, `total_input_tokens`, `total_output_tokens`, `context_window_size`, `current_usage`
- `model`: `display_name` (e.g. `"Opus 4.6 (1M context)"`)
- `workspace`: `current_dir`, `project_dir`, `added_dirs`
- No terminal dimensions in the JSON.

## Terminal Width Detection

`tput cols`, `$COLUMNS`, and bare `stty size` all return 80 or fail — the subprocess has no tty on stdin (stdin is the JSON pipe). Use `stty size </dev/tty` to read the actual terminal device:
```bash
cols=$(stty size </dev/tty 2>/dev/null | awk '{print $2}')
cols=${cols:-80}
```

## Field Availability

`context_window.used_percentage` and `rate_limits.*` only populate after the first API response. They are absent from the JSON on session boot. Design scripts to handle missing fields gracefully.
