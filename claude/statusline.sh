#!/bin/bash

# Status line command for Claude Code
# Two-line display:
# Line 1: [Opus 4.6]  📁 project-name  |  🌿 branch
# Line 2: █████░░░░░ 42%  |  19.8k tok  |  ✅ Max  |  ⏱️ 7m 3s  (API thinking time, not wall-clock)

# Read JSON input from Claude Code
input=$(cat)

# Debug mode: set CLAUDE_STATUSLINE_DEBUG=1 to dump JSON input
if [ -n "$CLAUDE_STATUSLINE_DEBUG" ]; then
    echo "$input" | jq '.' > /tmp/claude-statusline-debug.json 2>/dev/null
fi

# Extract data from JSON (single jq call for performance)
eval "$(echo "$input" | jq -r '
    @sh "cwd=\(.workspace.current_dir)",
    @sh "model_display=\(.model.display_name)",
    @sh "model_id=\(.model.id)",
    @sh "used_pct_raw=\(.context_window.used_percentage // 0)",
    @sh "total_input=\(.context_window.total_input_tokens // 0)",
    @sh "total_output=\(.context_window.total_output_tokens // 0)",
    @sh "duration_ms=\(.cost.total_api_duration_ms // 0)",
    @sh "total_cost=\(.cost.total_cost_usd // 0)"
')"

dir_name=$(basename "$cwd")

# Truncate percentage to integer
used_pct=${used_pct_raw%%.*}
: "${used_pct:=0}"

# Use display_name directly — it already includes the version (e.g. "Opus 4.6")
# Only extract from model_id as fallback if display_name has no version
if [[ "$model_display" =~ [0-9] ]]; then
    model_full="$model_display"
else
    version=""
    if [[ "$model_id" =~ claude-[a-z]+-([0-9]+)-([0-9]+) ]]; then
        version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    fi
    if [ -n "$version" ]; then
        model_full="$model_display $version"
    else
        model_full="$model_display"
    fi
fi

# Git branch with caching (5 second TTL)
git_branch=""
cache_dir="/tmp/claude-statusline"
cache_file="${cache_dir}/git-branch-$(echo "$cwd" | md5 -q)"
cache_ttl=5

if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    now=$(date +%s)
    file_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)
    cache_age=$((now - file_mtime))
    if [ -f "$cache_file" ] && [ "$cache_age" -lt "$cache_ttl" ]; then
        git_branch=$(cat "$cache_file")
    else
        git_branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo 'detached')
        mkdir -p "$cache_dir" && echo "$git_branch" > "$cache_file"
    fi
fi

# Format tokens (pure bash integer math)
total_tokens=$(( ${total_input%%.*} + ${total_output%%.*} ))
if [ "$total_tokens" -ge 1000000 ]; then
    whole=$((total_tokens / 1000000))
    frac=$(( (total_tokens % 1000000) / 100000 ))
    token_display="${whole}.${frac}M tok"
elif [ "$total_tokens" -ge 1000 ]; then
    whole=$((total_tokens / 1000))
    frac=$(( (total_tokens % 1000) / 100 ))
    if [ "$whole" -ge 100 ]; then
        token_display="${whole}k tok"
    else
        token_display="${whole}.${frac}k tok"
    fi
else
    token_display="${total_tokens} tok"
fi

# Billing mode detection (cached 60s)
billing_cache="/tmp/.claude-statusline-billing-cache"
billing_ttl=60
billing_mode=""

now_bill=$(date +%s)
bill_mtime=$(stat -c %Y "$billing_cache" 2>/dev/null || stat -f %m "$billing_cache" 2>/dev/null || echo 0)
bill_age=$((now_bill - bill_mtime))

if [ -f "$billing_cache" ] && [ "$bill_age" -lt "$billing_ttl" ]; then
    billing_mode=$(cat "$billing_cache")
else
    if security find-generic-password -s "Claude Code-credentials" >/dev/null 2>&1; then
        billing_mode="max"
    elif [ -n "$ANTHROPIC_API_KEY" ]; then
        billing_mode="api"
    else
        billing_mode="unknown"
    fi
    echo "$billing_mode" > "$billing_cache"
fi

if [ "$billing_mode" = "max" ]; then
    billing_display='\e[32m✅ Max\e[0m'
elif [ "$billing_mode" = "api" ]; then
    billing_display='\e[1;31m⚠️ API\e[0m'
else
    billing_display='\e[33m? Auth\e[0m'
fi

# Format cost
cost_display=$(printf '$%.2f' "$total_cost")

# Format duration from milliseconds
duration_sec=$((${duration_ms%%.*} / 1000))
duration_min=$((duration_sec / 60))
duration_rem=$((duration_sec % 60))

# Build progress bar (10 chars wide)
filled=$((used_pct * 10 / 100))
empty=$((10 - filled))

# Color-code based on usage
if [ "$used_pct" -lt 70 ]; then
    bar_color='\e[32m'  # Green
elif [ "$used_pct" -lt 90 ]; then
    bar_color='\e[33m'  # Yellow
else
    bar_color='\e[31m'  # Red
fi

bar=""
for ((i=0; i<filled; i++)); do bar="${bar}█"; done
for ((i=0; i<empty; i++)); do bar="${bar}░"; done

# Line 1: [Opus 4.6]  📁 project-name  |  🌿 branch
printf '\e[36m[%s]\e[0m  📁 %s' "$model_full" "$dir_name"
if [ -n "$git_branch" ]; then
    printf '  \e[2m|\e[0m  🌿 %s' "$git_branch"
fi
printf '\n'

# Line 2: █████░░░░░ 42%  |  19.8k tok  |  $1.23  |  ✅ Max  |  ⏱️ 7m 3s
printf '%b%s\e[0m %d%%  \e[2m|\e[0m  \e[36m%s\e[0m  \e[2m|\e[0m  \e[33m%s\e[0m  \e[2m|\e[0m  %b  \e[2m|\e[0m  ⏱️  %dm %ds' \
    "$bar_color" "$bar" "$used_pct" "$token_display" "$cost_display" "$billing_display" "$duration_min" "$duration_rem"
