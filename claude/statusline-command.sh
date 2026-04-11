#!/usr/bin/env bash
# Claude Code status line: cwd | git-branch[*] | model[ctx-size] | ctx%

input=$(cat)

# --- ANSI colors ---
RESET=$'\033[0m'
CYAN=$'\033[36m'
GREEN=$'\033[38;2;152;251;152m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
GRAY=$'\033[90m'

# --- cwd: shorten home to ~ ---
raw_cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
home_prefix="$HOME"
if [[ "$raw_cwd" == "$home_prefix"* ]]; then
  display_cwd="~${raw_cwd#$home_prefix}"
else
  display_cwd="$raw_cwd"
fi

# --- git branch + dirty indicator ---
git_part=""
if git -C "$raw_cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$raw_cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$raw_cwd" rev-parse --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    if ! git -C "$raw_cwd" diff --quiet 2>/dev/null || ! git -C "$raw_cwd" diff --cached --quiet 2>/dev/null; then
      git_part=" ${GREEN}${branch}${YELLOW}*${RESET}"
    else
      git_part=" ${GREEN}${branch}${RESET}"
    fi
  fi
fi

# --- compact model name ---
display_name=$(echo "$input" | jq -r '.model.display_name // ""')
# Strip leading "Claude " and lowercase, spaces to dashes
compact_model=$(echo "$display_name" | sed 's/^Claude //i' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
# Append context window size compactly
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
if [[ "$ctx_size" -ge 1000000 ]]; then
  ctx_label="[$(echo "$ctx_size" | awk '{printf "%dm", $1/1000000}')]"
elif [[ "$ctx_size" -ge 1000 ]]; then
  ctx_label="[$(echo "$ctx_size" | awk '{printf "%dk", $1/1000}')]"
else
  ctx_label=""
fi
model_part="${GRAY}${compact_model}${ctx_label}${RESET}"

# --- context used % ---
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [[ -n "$ctx_pct" ]]; then
  ctx_int=$(printf '%.0f' "$ctx_pct")
  if [[ "$ctx_int" -ge 50 ]]; then
    ctx_color="$RED"
  elif [[ "$ctx_int" -ge 30 ]]; then
    ctx_color="$YELLOW"
  else
    ctx_color="$GREEN"
  fi
  ctx_display="${ctx_color}ctx:${ctx_int}%${RESET}"
else
  ctx_display=""
fi

# --- assemble ---
parts="${CYAN}${display_cwd}${RESET}${git_part} | ${model_part}"
if [[ -n "$ctx_display" ]]; then
  parts="${parts} | ${ctx_display}"
fi

printf '%s' "$parts"
