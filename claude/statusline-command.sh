#!/usr/bin/env bash
# Claude Code status line: cwd | branch | model[ctx] | ctx% | 5h remaining (reset) | worktree

input=$(cat)

# --- ANSI colors ---
RESET=$'\033[0m'
CYAN=$'\033[36m'
PASTEL_CYAN=$'\033[38;2;152;232;251m'
GREEN=$'\033[38;2;152;251;152m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
GRAY=$'\033[90m'
MAGENTA=$'\033[35m'

# --- cwd: shorten home to ~ ---
raw_cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
home_prefix="$HOME"
if [[ "$raw_cwd" == "$home_prefix"* ]]; then
  display_cwd="~${raw_cwd#$home_prefix}"
else
  display_cwd="$raw_cwd"
fi

# --- git branch + dirty indicator + worktree detection ---
git_part=""
worktree_part=""
if git -C "$raw_cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$raw_cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$raw_cwd" rev-parse --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    if [[ -n "$(git -C "$raw_cwd" status --porcelain 2>/dev/null)" ]]; then
      git_part="${PASTEL_CYAN}${branch}${YELLOW}*${RESET}"
    else
      git_part="${PASTEL_CYAN}${branch}${RESET}"
    fi
  fi
  # Detect worktree: git-dir differs from git-common-dir
  git_dir=$(git -C "$raw_cwd" rev-parse --git-dir 2>/dev/null)
  git_common=$(git -C "$raw_cwd" rev-parse --git-common-dir 2>/dev/null)
  if [[ -n "$git_dir" && -n "$git_common" && "$git_dir" != "$git_common" ]]; then
    worktree_part="${MAGENTA}worktree${RESET}"
  fi
fi

# --- compact model name with context window size ---
display_name=$(echo "$input" | jq -r '.model.display_name // ""')
compact_model=$(echo "$display_name" | sed 's/^Claude //i; s/ *(.*)//')
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
ctx_display=""
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
  ctx_display="${ctx_color}ctx: ${ctx_int}%${RESET}"
fi

# --- 5-hour rate limit remaining % with reset countdown ---
five_display=""
five_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [[ -n "$five_used" ]]; then
  five_int=$(printf '%.0f' "$five_used")
  five_remaining=$((100 - five_int))
  if [[ "$five_remaining" -le 20 ]]; then
    five_color="$RED"
  elif [[ "$five_remaining" -le 50 ]]; then
    five_color="$YELLOW"
  else
    five_color="$GREEN"
  fi
  # Reset countdown
  resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
  reset_label=""
  if [[ -n "$resets_at" ]]; then
    now=$(date +%s)
    diff=$((resets_at - now))
    if [[ "$diff" -gt 0 ]]; then
      hours=$((diff / 3600))
      mins=$(( (diff % 3600) / 60 ))
      if [[ "$hours" -gt 0 ]]; then
        reset_label=" resets ${hours}h${mins}m"
      else
        reset_label=" resets ${mins}m"
      fi
    fi
  fi
  five_display="${five_color}⏳ ${five_remaining}% remaining (5h)${reset_label}${RESET}"
fi

# --- assemble: all left-aligned with pipe separators ---
parts=()
parts+=("${CYAN}${display_cwd}${RESET}")
[[ -n "$git_part" ]] && parts+=("$git_part")
[[ -n "$worktree_part" ]] && parts+=("$worktree_part")
parts+=("$model_part")
[[ -n "$ctx_display" ]] && parts+=("$ctx_display")
[[ -n "$five_display" ]] && parts+=("$five_display")

output=""
for i in "${!parts[@]}"; do
  if [[ "$i" -gt 0 ]]; then
    output="${output} | "
  fi
  output="${output}${parts[$i]}"
done

printf '%s' "$output"
