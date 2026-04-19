#!/bin/bash
# permission-analyzer.sh
# Scan recent Claude Code transcripts, extract Bash + MCP tool calls,
# filter to read-only/non-auto-allowed/non-dangerous, output ranked candidates.

set -u  # no -e, no pipefail — jq parse errors on individual lines are tolerated

PROJECTS_DIR="$HOME/.claude/projects"
SESSIONS_LIMIT="${SESSIONS_LIMIT:-50}"
MIN_COUNT="${MIN_COUNT:-3}"

tmp_files=$(mktemp)
tmp_events=$(mktemp)
trap 'rm -f "$tmp_files" "$tmp_events"' EXIT

# Find SESSIONS_LIMIT most recently modified jsonl files
find "$PROJECTS_DIR" -maxdepth 3 -name '*.jsonl' -type f -print 2>/dev/null \
  | while IFS= read -r f; do
      printf "%s %s\n" "$(stat -f '%m' "$f" 2>/dev/null || stat -c '%Y' "$f" 2>/dev/null || echo 0)" "$f"
    done \
  | sort -rn \
  | head -n "$SESSIONS_LIMIT" \
  | cut -d' ' -f2- > "$tmp_files"

scanned=0
while IFS= read -r f; do
    [ -f "$f" ] || continue
    scanned=$((scanned + 1))
    # Use jq's `?` operator + raw input to tolerate malformed lines.
    # Each line in the JSONL is parsed; failures yield empty.
    jq -c -R 'fromjson? | select((.message.role // "") == "assistant") | (.message.content // [])[]? | select(.type == "tool_use") | {name: .name, command: (.input.command // "")}' "$f" 2>/dev/null >> "$tmp_events"
done < "$tmp_files"

echo "Scanned $scanned transcripts" >&2
echo "Tool events extracted: $(wc -l < "$tmp_events" | tr -d ' ')" >&2

awk -v MIN="$MIN_COUNT" '
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

function first_token(cmd,    parts, words, head, sub_, n, m) {
    cmd = trim(cmd)
    while (match(cmd, /^[A-Z_][A-Z_0-9]*=[^ \t]+[ \t]+/)) {
        cmd = substr(cmd, RSTART + RLENGTH)
    }
    sub(/^(sudo[ \t]+|timeout[ \t]+[^ \t]+[ \t]+|nice([ \t]+-n[ \t]+[^ \t]+)?[ \t]+)/, "", cmd)
    n = split(cmd, parts, /[|&;]/)
    cmd = trim(parts[1])
    m = split(cmd, words, /[ \t]+/)
    if (m == 0 || words[1] == "") return ""
    head = words[1]
    if (head == "git" || head == "gh" || head == "glab" || head == "docker" || head == "kubectl" || head == "npm" || head == "pnpm" || head == "yarn" || head == "bun" || head == "uv" || head == "cargo" || head == "go" || head == "brew" || head == "apt" || head == "dnf") {
        if (m >= 2) return head " " words[2]
    }
    return head
}

function is_dangerous(tok,    p, head) {
    split(tok, p, " "); head = p[1]
    if (head == "python" || head == "python3" || head == "node" || head == "bun" || head == "deno" || head == "ruby" || head == "perl" || head == "php" || head == "lua") return 1
    if (head == "bash" || head == "sh" || head == "zsh" || head == "fish" || head == "eval" || head == "exec" || head == "ssh") return 1
    if (head == "npx" || head == "bunx" || head == "uvx") return 1
    if (head == "sudo") return 1
    return 0
}

function is_auto_allowed(tok,    p, head, sub_) {
    split(tok, p, " "); head = p[1]; sub_ = (length(p) > 1) ? p[2] : ""
    if (index(" cal uptime cat head tail wc stat strings hexdump od nl id uname free df du locale groups nproc basename dirname realpath cut paste tr column tac rev fold expand unexpand fmt comm cmp numfmt readlink diff true false sleep which type expr test getconf seq tsort pr echo printf ls cd find ", " " head " ")) return 1
    if (index(" xargs file sed sort man help netstat ps base64 grep egrep fgrep sha256sum sha1sum md5sum tree date hostname info lsof pgrep tput ss fd fdfind aki rg jq uniq history arch ifconfig pyright ", " " head " ")) return 1
    if ((head == "pwd" || head == "whoami" || head == "alias") && sub_ == "") return 1
    if (head == "git" && index(" status log diff show blame branch tag remote ls-files ls-remote rev-parse describe reflog shortlog cat-file for-each-ref ", " " sub_ " ")) return 1
    if (head == "gh" && (sub_ == "pr" || sub_ == "issue" || sub_ == "run" || sub_ == "workflow" || sub_ == "repo" || sub_ == "release" || sub_ == "auth")) return 1
    if (head == "docker" && (sub_ == "ps" || sub_ == "images" || sub_ == "logs" || sub_ == "inspect")) return 1
    return 0
}

function is_mutating(tok,    p, head, sub_) {
    split(tok, p, " "); head = p[1]; sub_ = (length(p) > 1) ? p[2] : ""
    if (index(" rm mv cp mkdir chmod chown touch dd wget curl rsync scp ln tar zip unzip make meson cmake ninja pip poetry systemctl launchctl service reboot shutdown kill killall xkill ", " " head " ")) return 1
    if (head == "git" && index(" add commit push pull fetch merge rebase reset checkout stash restore rm mv clone init submodule clean am cherry-pick revert worktree config ", " " sub_ " ")) return 1
    return 0
}

{
    name = ""
    cmd = ""
    if (match($0, /"name":"[^"]*"/)) {
        name = substr($0, RSTART + 8, RLENGTH - 9)
    }
    if (match($0, /"command":"/)) {
        rest = substr($0, RSTART + 11)
        out = ""
        i = 1
        L = length(rest)
        while (i <= L) {
            c = substr(rest, i, 1)
            if (c == "\\") {
                nxt = substr(rest, i+1, 1)
                if (nxt == "n" || nxt == "t" || nxt == "r") out = out " "
                else out = out nxt
                i += 2
                continue
            }
            if (c == "\"") break
            out = out c
            i++
        }
        cmd = out
    }
    if (name == "Bash") {
        tok = first_token(cmd)
        if (tok == "") next
        bash_count[tok]++
    } else if (name ~ /^mcp__/) {
        mcp_count[name]++
    }
}

END {
    bn = 0
    for (t in bash_count) {
        if (bash_count[t] < MIN) continue
        if (is_dangerous(t)) continue
        if (is_auto_allowed(t)) continue
        if (is_mutating(t)) continue
        bash_keys[++bn] = t
    }
    # sort bash by count desc
    for (i = 1; i <= bn; i++) for (j = i+1; j <= bn; j++) {
        if (bash_count[bash_keys[j]] > bash_count[bash_keys[i]]) {
            t = bash_keys[i]; bash_keys[i] = bash_keys[j]; bash_keys[j] = t
        }
    }
    print "=== Bash candidates ==="
    for (i = 1; i <= bn; i++) printf "%5d\t%s\n", bash_count[bash_keys[i]], bash_keys[i]

    mn = 0
    for (m in mcp_count) {
        if (mcp_count[m] < MIN) continue
        lm = tolower(m)
        if (lm ~ /(write|create|update|delete|send|post|push|merge|close|reopen|comment|edit)/) continue
        mcp_keys[++mn] = m
    }
    for (i = 1; i <= mn; i++) for (j = i+1; j <= mn; j++) {
        if (mcp_count[mcp_keys[j]] > mcp_count[mcp_keys[i]]) {
            t = mcp_keys[i]; mcp_keys[i] = mcp_keys[j]; mcp_keys[j] = t
        }
    }
    print "=== MCP candidates ==="
    for (i = 1; i <= mn; i++) printf "%5d\t%s\n", mcp_count[mcp_keys[i]], mcp_keys[i]
}
' "$tmp_events"
