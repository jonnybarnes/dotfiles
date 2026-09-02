#!/bin/bash
# Claude Code Status Line
# Based on https://github.com/daniel3303/ClaudeCodeStatusLine
# Enhanced: git branch/ahead-behind, token bar, caching, improved visuals

set -f  # disable globbing

# ===== Config =====
SHOW_GIT=true           # git branch, dirty status, ahead/behind
SHOW_TOKENS=true        # token usage bar
SHOW_THINKING=true      # extended thinking indicator
SHOW_RATE_LIMITS=true   # 5h / 7d rate limit bars
SHOW_MODEL_LIMIT=true   # per-model weekly limit bar (e.g. Fable), when the API reports one
WRAP_NARROW=true        # wrap onto a second line rather than dropping segments or being clipped
WRAP_MIN_WIDTH=100      # below this, keep wide-tier line-one content (it can wrap)
BRANCH_MAX_LEN=28       # truncate branch names longer than this
CWD_MAX_LEN=20          # truncate the cwd basename longer than this
GIT_CACHE_SECS=10       # seconds to cache git status (git diff is slow on large repos)
USAGE_CACHE_SECS=300    # seconds to cache the usage API response (the 5h/7d bars)
USAGE_RETRY_SECS=60     # seconds to wait before retrying a failed usage API fetch
TOKEN_BAR_WIDTH=8       # width of token progress bar
SL_WORK_DAYS="${SL_WORK_DAYS:-12345}"   # ISO weekdays you work: Mon=1 ... Sun=7

# Where the git and usage-API caches live. Overridable via the environment so a
# test run can render into its own directory: ~/.claude/statusline.sh is a
# symlink to this script, so a fixture written to the live cache is picked up by
# the next redraw and shown as real usage until USAGE_CACHE_SECS is up.
CACHE_DIR="${STATUSLINE_CACHE_DIR:-/tmp/claude}"

# "Now", overridable so a test can pin the day of the week: the pace figure
# counts the working days left before the reset, so it moves with today's
# weekday and would otherwise be unassertable. Only the pace code reads it --
# the cache-age checks below stay on the real clock deliberately, so pinning a
# time cannot make a fresh fixture look stale and send a test to the network.
SL_NOW="${SL_NOW:-}"
now_ts() { [ -n "$SL_NOW" ] && printf '%s' "$SL_NOW" || date +%s; }

# Terminal width detection.
# Claude Code exports COLUMNS for this subprocess. There is no controlling
# terminal, so the stty fallback fails; when both fail we default to 80
# (safe/compact) rather than wide.
#
# The `padding` setting indents the status line on both sides, and Claude Code
# applies it on top of COLUMNS rather than deducting it first — measured: with
# COLUMNS=121 and padding 2, a 121-column line is clipped with an ellipsis. So
# deduct it here, plus a column of margin.
#
# To override detection entirely, set TERM_WIDTH in settings.json:
#   "command": "TERM_WIDTH=160 ~/.claude/statusline.sh"
# Only the user-level file: Claude Code also merges project .claude/settings.json,
# .claude/settings.local.json and managed policy, so a statusLine.padding set at
# project level would be applied by the renderer but missed here.
sl_padding=0
if [ -f "$HOME/.claude/settings.json" ]; then
    sl_padding=$(jq -r '.statusLine.padding // 0' "$HOME/.claude/settings.json" 2>/dev/null)
    [ "${sl_padding:-0}" -ge 0 ] 2>/dev/null || sl_padding=0
fi

if [ "${TERM_WIDTH:-0}" -le 0 ] 2>/dev/null; then
    if [ "${COLUMNS:-0}" -gt 0 ] 2>/dev/null; then
        TERM_WIDTH=$COLUMNS
    else
        _w=$(stty size </dev/tty 2>/dev/null | awk '{print $2}')
        [ "${_w:-0}" -gt 0 ] 2>/dev/null && TERM_WIDTH=$_w || TERM_WIDTH=80
        unset _w
    fi
fi

# Usable width: minus padding on both sides, minus a column of margin.
USABLE_WIDTH=$(( TERM_WIDTH - 2 * sl_padding - 1 ))
[ "$USABLE_WIDTH" -lt 20 ] && USABLE_WIDTH=20

# ${#str} counts characters only under a UTF-8 locale; under LC_ALL=C it counts
# bytes, which would mis-measure the box/block glyphs and break line wrapping.
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *UTF-8*|*utf8*|*UTF8*) ;;
    *)
        # C.UTF-8 on glibc, en_US.UTF-8 on macOS (which has no C.UTF-8).
        # Picking one that does not exist makes bash warn on every render and
        # silently fall back to byte counting, so verify before committing.
        for _loc in C.UTF-8 en_US.UTF-8; do
            if LC_ALL="$_loc" locale charmap 2>/dev/null | grep -qi utf; then
                export LC_ALL="$_loc"; break
            fi
        done
        unset _loc
        ;;
esac

input=$(cat)
[ -z "$input" ] && printf "Claude" && exit 0

mkdir -p "$CACHE_DIR"

# ===== Colors =====
# Palette indices rather than RGB, so these resolve through the terminal's own
# palette and follow the ghostty tangere-light/tangere-dark swap for free. No
# appearance detection, so no cost per statusline render.
#
# The previous values were One Dark RGB: fine on dark (4.3-10.8:1) but 1.35-3.4:1
# on a light background, with 'white' effectively invisible. These clear WCAG AA
# in both modes (5.8-14.3:1 on dark, 6.3-20.6:1 on light).
blue='\033[38;5;4m'
orange='\033[38;5;3m'
amber='\033[38;5;11m'
green='\033[38;5;2m'
cyan='\033[38;5;14m'
red='\033[38;5;1m'
yellow='\033[38;5;3m'
white='\033[39m'
magenta='\033[38;5;5m'
dim='\033[2m'
reset='\033[0m'

sep=" ${dim}│${reset} "

# ===== Helpers =====

format_tokens() {
    local num=$1
    if [ "$num" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fm\", $num / 1000000}"
    elif [ "$num" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $num / 1000}"
    else
        printf "%d" "$num"
    fi
}

# Display width of a string, ignoring ANSI colour escapes. Every glyph the
# statusline uses is single-width, so a character count is the display width.
#
# The colour vars hold the escapes as literal backslash-033 text (they are
# single-quoted, and printf %b only interprets them when the line is finally
# emitted), so strip that literal form as well as a real ESC byte.
vis_len() {
    local plain
    plain=$(printf '%s' "$1" | sed -e 's/\\033\[[0-9;]*m//g' -e $'s/\033\[[0-9;]*m//g' -e 's/\\\\/\\/g')
    printf '%d' "${#plain}"
}

# printf %b interprets backslash escapes -- that is how the colour variables
# above are applied. Data from the API or the filesystem must NOT be
# interpreted: a directory or model name containing a literal \n would split
# the line, breaking both the width measurement and the two-line guarantee.
# Double the backslashes so %b renders them literally.
esc_data() {
    local v="$1"
    # Real control characters (jq decodes \n in the JSON payload into an actual
    # newline) would split the line regardless of escaping, so drop them first.
    v="${v//$'\n'/ }"; v="${v//$'\r'/ }"; v="${v//$'\t'/ }"; v="${v//$'\033'/}"
    printf '%s' "${v//\\/\\\\}"
}

truncate_str() {
    local str="$1" max="$2"
    [ "${#str}" -gt "$max" ] \
        && printf "%s…" "${str:0:$((max-1))}" \
        || printf "%s" "$str"
}

# Colored progress bar using block chars
build_bar() {
    local pct=$1 width=$2
    [ "$pct" -lt 0 ] 2>/dev/null && pct=0
    [ "$pct" -gt 100 ] 2>/dev/null && pct=100
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local bar_color
    if   [ "$pct" -ge 90 ]; then bar_color="$red"
    elif [ "$pct" -ge 70 ]; then bar_color="$yellow"
    elif [ "$pct" -ge 50 ]; then bar_color="$orange"
    else                         bar_color="$green"
    fi
    local f="" e=""
    for ((i=0; i<filled; i++)); do f+="█"; done
    for ((i=0; i<empty;  i++)); do e+="░"; done
    printf "${bar_color}${f}${dim}${e}${reset}"
}

# Colour for the sustainable %/day, measured against the window's OWN even-burn
# baseline (100 / workdays in the window) rather than a fixed number of points
# per day: on a five-day week healthy is 20%/day, so a threshold tuned to the
# 14.3%/day calendar baseline would still call 12%/day green -- by then two
# fifths of the budget has been overspent. The ratios reproduce the 12/8/5
# thresholds at a 14.3 baseline, whatever SL_WORK_DAYS is set to.
#
# A high pace means plenty of runway per working day, so it reads cool; a low
# one means the rest of the week has to be rationed. Both arguments are in
# tenths, which keeps the comparison integer.
pacecol() {
    local p=$1 base=$2
    if   [ "$p" -ge $(( base * 84 / 100 )) ]; then printf '%s' "$green"
    elif [ "$p" -ge $(( base * 56 / 100 )) ]; then printf '%s' "$yellow"
    elif [ "$p" -ge $(( base * 35 / 100 )) ]; then printf '%s' "$orange"
    else                                           printf '%s' "$red"
    fi
}

# ===== Git info with per-directory caching =====
get_git_info() {
    local dir="$1"
    [ -z "$dir" ] && return

    # Stable cache key per directory path
    local dir_hash
    dir_hash=$(printf '%s' "$dir" | cksum | awk '{print $1}')
    local cache_file="$CACHE_DIR/git-${dir_hash}"

    local needs_refresh=true
    if [ -f "$cache_file" ]; then
        local mtime now age
        mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)
        now=$(date +%s)
        age=$(( now - mtime ))
        [ "$age" -lt "$GIT_CACHE_SECS" ] && needs_refresh=false
    fi

    if $needs_refresh; then
        # Branch name (or short hash for detached HEAD)
        local branch
        branch=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null)
        if [ -z "$branch" ]; then
            branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
            if [ -z "$branch" ]; then
                : > "$cache_file"   # not a git repo — write empty cache
                return
            fi
            branch="(${branch})"
        fi

        # Dirty: any staged or unstaged changes
        local dirty=""
        [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ] && dirty="dirty"

        # Ahead / behind upstream (skip if no upstream set)
        local ahead=0 behind=0
        local upstream
        upstream=$(git -C "$dir" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null)
        if [ -n "$upstream" ]; then
            local ab
            ab=$(git -C "$dir" rev-list --left-right --count "HEAD...${upstream}" 2>/dev/null)
            ahead=$(echo "$ab"  | awk '{print $1}')
            behind=$(echo "$ab" | awk '{print $2}')
        fi

        # Tab-delimited cache (branch names can't contain tabs per git spec)
        printf '%s\t%s\t%s\t%s' "$branch" "$dirty" "${ahead:-0}" "${behind:-0}" > "$cache_file"
    fi

    cat "$cache_file" 2>/dev/null
}

# ===== OAuth token resolution =====
get_oauth_token() {
    [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ] && echo "$CLAUDE_CODE_OAUTH_TOKEN" && return 0

    if command -v security >/dev/null 2>&1; then
        local blob token
        blob=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
        if [ -n "$blob" ]; then
            token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
            [ -n "$token" ] && [ "$token" != "null" ] && echo "$token" && return 0
        fi
    fi

    local creds_file="${HOME}/.claude/.credentials.json"
    if [ -f "$creds_file" ]; then
        local token
        token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds_file" 2>/dev/null)
        [ -n "$token" ] && [ "$token" != "null" ] && echo "$token" && return 0
    fi

    if command -v secret-tool >/dev/null 2>&1; then
        local blob token
        blob=$(timeout 2 secret-tool lookup service "Claude Code-credentials" 2>/dev/null)
        if [ -n "$blob" ]; then
            token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
            [ -n "$token" ] && [ "$token" != "null" ] && echo "$token" && return 0
        fi
    fi

    echo ""
}

# ===== ISO 8601 → epoch (cross-platform) =====
iso_to_epoch() {
    local iso_str="$1"
    local epoch

    epoch=$(date -d "${iso_str}" +%s 2>/dev/null)
    [ -n "$epoch" ] && echo "$epoch" && return 0

    local stripped="${iso_str%%.*}"
    stripped="${stripped%%Z}"
    stripped="${stripped%%+*}"
    stripped="${stripped%%-[0-9][0-9]:[0-9][0-9]}"

    if [[ "$iso_str" == *"Z"* ]] || [[ "$iso_str" == *"+00:00"* ]] || [[ "$iso_str" == *"-00:00"* ]]; then
        epoch=$(env TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    else
        epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    fi

    [ -n "$epoch" ] && echo "$epoch" && return 0
    return 1
}

# Local midnight of the day an epoch falls in, plus that day's ISO weekday
# (1 = Monday), as "<epoch> <weekday>". BSD date first -- it is the hot path
# here -- then GNU date, which has no -v.
day_start_dow() {
    date -j -r "$1" -v0H -v0M -v0S +'%s %u' 2>/dev/null && return 0
    local d
    d=$(date -d "@$1" +%F 2>/dev/null) || return 1
    date -d "$d 00:00:00" +'%s %u' 2>/dev/null
}

format_reset_time() {
    local iso_str="$1" style="$2"
    [ -z "$iso_str" ] || [ "$iso_str" = "null" ] && return
    local epoch
    epoch=$(iso_to_epoch "$iso_str")
    [ -z "$epoch" ] && return
    case "$style" in
        time)
            date -j -r "$epoch" +"%l:%M%p" 2>/dev/null | sed 's/^ //' | tr '[:upper:]' '[:lower:]' ||
            date -d "@$epoch"   +"%l:%M%P"  2>/dev/null | sed 's/^ //'
            ;;
        datetime)
            date -j -r "$epoch" +"%b %-d, %l:%M%p" 2>/dev/null | sed 's/  / /g; s/^ //' | tr '[:upper:]' '[:lower:]' ||
            date -d "@$epoch"   +"%b %-d, %l:%M%P"  2>/dev/null | sed 's/  / /g; s/^ //'
            ;;
    esac
}

# ===== Extract JSON =====
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input"        | jq -r '.cwd // empty')
cost_usd=$(echo "$input"   | jq -r '.cost.total_cost_usd // empty')
# Formatted here rather than where it is rendered: the wrap-mode branch budget
# needs its width, and it is not fixed ("$4.61" vs "$1234.56").
cost_fmt=""
[ -n "$cost_usd" ] && cost_fmt=$(printf '%.2f' "$cost_usd" 2>/dev/null)

size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
[ "$size" -eq 0 ] 2>/dev/null && size=200000

input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input"   | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
current=$(( input_tokens + cache_create + cache_read ))

used_tokens=$(format_tokens $current)
total_tokens=$(format_tokens $size)
pct_used=$(( size > 0 ? current * 100 / size : 0 ))

# Thinking and effort come from the payload, not from alwaysThinkingEnabled in
# settings.json: Option+T toggles thinking for the session only and never
# writes the file, so a settings read reports the wrong state for the rest of
# the session. Absent means enabled, mirroring Claude Code's own
# `thinking:{enabled: lt !== false}`.
# Both in one jq pass: the status line re-renders on every redraw, so a
# process per field is the dominant cost (see the rate-limit section below).
# `== false` rather than `// false`, which jq's falsy `//` would flip to true.
{ IFS= read -r sl_thinking; IFS= read -r effort; } <<EOF
$(echo "$input" | jq -r '(if .thinking.enabled == false then "false" else "true" end), (.effort.level // "")')
EOF
thinking_on=true
[ "$sl_thinking" = "false" ] && thinking_on=false

# The effort level replaces the static "thinking" label. Whitelisted rather
# than printed as-is: an unrecognised value would escape the width budget that
# the wrap branch computes from this string.
case "$effort" in
    low|medium|high|xhigh|max) thinking_label="$effort" ;;
    *)                         thinking_label="thinking" ;;
esac

# ===== Adaptive width tiers =====
#
# Tiers now choose only how much of LINE ONE to show. What the rate-limit
# group contains, and whether it wraps, is decided by measurement at the end of
# the script, not here -- tiers cannot see how long the branch, cwd or model
# name is, which is how content used to end up clipped.
#
#  full    (≥150): CWD, ahead/behind, "◆ high" effort, cost
#  wide    (100–149): ahead/behind, "◆ high" effort, cost
#  split   (76–99):  short model, ahead/behind, "◆" symbol
#                    (reachable only with WRAP_NARROW=false; otherwise the wrap
#                     band below overrides this range to wide)
#  narrow  (<76):  short model + branch + token only; no rate limits at all
#
if   [ "$USABLE_WIDTH" -ge 150 ] 2>/dev/null; then width_tier="full"
elif [ "$USABLE_WIDTH" -ge 100 ] 2>/dev/null; then width_tier="wide"
elif [ "$USABLE_WIDTH" -ge 76  ] 2>/dev/null; then width_tier="split"
else                                              width_tier="narrow"
fi

# Two-line mode. Between WRAP_FLOOR and WRAP_MIN_WIDTH there isn't room for
# everything on one line, but there IS room across two — so instead of dropping
# the rate-limit group we break before it and render the wide-tier content.
# Below WRAP_FLOOR the narrow tier applies instead, which drops the rate-limit
# group entirely -- so there is nothing to wrap and no second line to put it on.
WRAP_FLOOR=68
wrap_mode=false
if $WRAP_NARROW \
   && [ "$USABLE_WIDTH" -lt "$WRAP_MIN_WIDTH" ] 2>/dev/null \
   && [ "$USABLE_WIDTH" -ge "$WRAP_FLOOR" ] 2>/dev/null; then
    wrap_mode=true
    width_tier="wide"
fi

# Shorten model name for tight spaces
short_model() {
    case "$1" in
        *Opus*)   echo "Opus" ;;
        *Sonnet*) echo "Sonnet" ;;
        *Haiku*)  echo "Haiku" ;;
        *)        echo "$1" | awk '{print $NF}' ;;   # last word
    esac
}

# ===== Build output =====
# Explicitly empty: bash imports same-named environment variables, and a
# stray $rl_lean would otherwise leak into the rendered line.
out=""
rl_bare=""
rl_lean=""
rl_pace=""
rl_mid=""
rl_rich=""

# Model — color by family
model_color="$blue"
case "$model_name" in
    *Opus*)  model_color="$amber" ;;
    *Haiku*) model_color="$cyan"  ;;
esac

display_model="$model_name"
# split/narrow: shorten so the 5h + 7d bars still fit on one line.
# wrap mode too: it renders wide-tier content at a split-tier width, and a long
# display name ("Opus 5 (1M context)" is 19 cols) would overflow line one.
if [ "$width_tier" = "split" -o "$width_tier" = "narrow" ] || $wrap_mode; then
    display_model=$(short_model "$model_name")
fi
out+="${model_color}$(esc_data "$display_model")${reset}"

# CWD — full tier only (branch name gives enough context below that)
if [ "$width_tier" = "full" ] && [ -n "$cwd" ]; then
    # Capped like the branch name: nothing else shortens line one, so an
    # unusually long project directory would push it past the terminal edge.
    display_dir=$(truncate_str "${cwd##*/}" "$CWD_MAX_LEN")
    out+="${sep}${dim}$(esc_data "$display_dir")${reset}"
fi

bar_w="$TOKEN_BAR_WIDTH"
[ "$width_tier" = "wide"   ] && bar_w=6
[ "$width_tier" = "split"  ] && bar_w=5
[ "$width_tier" = "narrow" ] && bar_w=4

# Git branch + dirty + ahead/behind
if $SHOW_GIT && [ -n "$cwd" ]; then
    git_info=$(get_git_info "$cwd")
    if [ -n "$git_info" ]; then
        IFS=$'\t' read -r g_branch g_dirty g_ahead g_behind <<< "$git_info"

        # Progressively tighten branch truncation
        local_max="$BRANCH_MAX_LEN"
        [ "$width_tier" = "wide"   ] && local_max=24
        [ "$width_tier" = "split"  ] && local_max=18
        [ "$width_tier" = "narrow" ] && local_max=12
        # In wrap mode line one is
        #   model │ ⎇ branch ✔ ↑1 │ <bar> used/total pct% │ ◇ high │ $cost
        # and the branch gets whatever the rest of it leaves. Everything after
        # the branch is appended below, so its width is added up here rather
        # than assumed: a flat 56 columns was three short of a four-digit cost,
        # which pushed line one past the edge to be clipped by the renderer.
        if $wrap_mode; then
            tail_len=$(( 5 + 2 ))                  # "│ ⎇ " and the dirty mark
            [ "${g_ahead:-0}"  -gt 0 ] && tail_len=$(( tail_len + 2 + ${#g_ahead} ))
            [ "${g_behind:-0}" -gt 0 ] && tail_len=$(( tail_len + 2 + ${#g_behind} ))
            $SHOW_TOKENS && tail_len=$(( tail_len + 3 + bar_w + 1 \
                + ${#used_tokens} + 1 + ${#total_tokens} + 1 + ${#pct_used} + 1 ))
            $SHOW_THINKING && tail_len=$(( tail_len + 3 + 2 + ${#thinking_label} ))
            [ -n "$cost_fmt" ] && tail_len=$(( tail_len + 3 + 1 + ${#cost_fmt} ))
            local_max=$(( USABLE_WIDTH - $(vis_len "$out") - tail_len ))
            [ "$local_max" -lt 8  ] && local_max=8
            [ "$local_max" -gt 24 ] && local_max=24
        fi
        g_branch_display=$(truncate_str "$g_branch" "$local_max")

        out+="${sep}${dim}⎇${reset} ${magenta}$(esc_data "$g_branch_display")${reset}"

        if [ "$g_dirty" = "dirty" ]; then
            out+=" ${red}✗${reset}"
        else
            out+=" ${green}✔${reset}"
        fi

        # Ahead/behind: shown in all tiers except narrow (only if non-zero)
        if [ "$width_tier" != "narrow" ]; then
            [ "${g_ahead:-0}"  -gt 0 ] && out+=" ${green}↑${g_ahead}${reset}"
            [ "${g_behind:-0}" -gt 0 ] && out+=" ${orange}↓${g_behind}${reset}"
        fi
    fi
fi

# Token bar
if $SHOW_TOKENS; then
    token_bar=$(build_bar "$pct_used" "$bar_w")
    out+="${sep}${token_bar} ${orange}${used_tokens}${dim}/${reset}${white}${total_tokens}${reset} ${dim}${pct_used}%${reset}"
fi

# Thinking and effort. The diamond is thinking state, the label is the effort
# level ("thinking" only when the payload reports no level):
#   full/wide  → "◆ high" / "◇ high"  (label)
#   split      → "◆" / "◇"            (symbol only, saves the label's columns)
#   narrow     → hidden
if $SHOW_THINKING && [ "$width_tier" != "narrow" ]; then
    out+="${sep}"
    if $thinking_on; then
        if [ "$width_tier" = "split" ]; then out+="${amber}◆${reset}"
        else out+="${amber}◆ ${thinking_label}${reset}"; fi
    else
        if [ "$width_tier" = "split" ]; then out+="${dim}◇${reset}"
        else out+="${dim}◇ ${thinking_label}${reset}"; fi
    fi
fi

# Session cost — wide/full only
if [ -n "$cost_fmt" ] && [ "$width_tier" = "wide" -o "$width_tier" = "full" ]; then
    out+="${sep}${dim}\$${cost_fmt}${reset}"
fi

# ===== Rate limits (API, cached USAGE_CACHE_SECS) =====
# Built at every tier except narrow. Which variant is actually emitted,
# and on how many lines, is decided by the measured ladder at the end.
if $SHOW_RATE_LIMITS && [ "$width_tier" != "narrow" ]; then
    api_cache="$CACHE_DIR/statusline-usage-cache.json"
    fail_marker="$CACHE_DIR/statusline-usage-fail"
    needs_refresh=true
    usage_data=""

    if [ -f "$api_cache" ]; then
        cache_mtime=$(stat -c %Y "$api_cache" 2>/dev/null || stat -f %m "$api_cache" 2>/dev/null)
        now=$(date +%s)
        cache_age=$(( now - cache_mtime ))
        if [ "$cache_age" -lt "$USAGE_CACHE_SECS" ]; then
            cached_content=$(cat "$api_cache" 2>/dev/null)
            # Only use cache if it's valid data (not an error response)
            if [ -n "$cached_content" ] && ! echo "$cached_content" | jq -e '.error' >/dev/null 2>&1; then
                needs_refresh=false
                usage_data="$cached_content"
            fi
        fi
    fi

    if $needs_refresh; then
        # Hold off after a failed fetch. With no network curl can burn its
        # --max-time before giving up, and a redraw happens on every keystroke,
        # so retrying each time would stall the whole status line. The marker is
        # separate from the cached response, rather than a touch of it: a cold
        # /tmp has no response to touch, which is exactly when there is also no
        # stale data to fall back on and the timeout is paid in full.
        attempt=true
        if [ -f "$fail_marker" ]; then
            fail_mtime=$(stat -c %Y "$fail_marker" 2>/dev/null || stat -f %m "$fail_marker" 2>/dev/null)
            [ $(( $(date +%s) - fail_mtime )) -lt "$USAGE_RETRY_SECS" ] && attempt=false
        fi

        if $attempt; then
            token=$(get_oauth_token)
            if [ -n "$token" ] && [ "$token" != "null" ]; then
                # Marked before the call, cleared when it lands. A fetch is in
                # flight for as long as curl takes to time out, and this cache
                # dir is shared by every session, so redraws that start inside
                # that window are real: they now serve stale data instead of
                # each launching their own doomed request. Written on every
                # attempt, so a repeated failure restarts the backoff, and only
                # by an attempt, so the redraws it suppresses cannot keep
                # re-stamping it and it always lapses.
                #
                # No credentials is not a failure worth suppressing: it costs no
                # timeout, and the next redraw after a login should show the
                # bars rather than wait out a retry window. Hence inside the
                # token check.
                : > "$fail_marker"
                response=$(curl -s --max-time 10 \
                    -H "Accept: application/json" \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer $token" \
                    -H "anthropic-beta: oauth-2025-04-20" \
                    -H "User-Agent: claude-code/2.1.34" \
                    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
                if [ -n "$response" ] && echo "$response" | jq . >/dev/null 2>&1; then
                    # Only cache successful (non-error) responses
                    if ! echo "$response" | jq -e '.error' >/dev/null 2>&1; then
                        usage_data="$response"
                        echo "$response" > "$api_cache"
                        rm -f "$fail_marker"
                    fi
                fi
            fi
        fi

        # Fall back to stale cache if refresh failed — skip if it's an error response
        if [ -z "$usage_data" ] && [ -f "$api_cache" ]; then
            stale=$(cat "$api_cache" 2>/dev/null)
            ! echo "$stale" | jq -e '.error' >/dev/null 2>&1 && usage_data="$stale"
        fi
    fi

    if [ -n "$usage_data" ] && echo "$usage_data" | jq -e . >/dev/null 2>&1; then
        bar_width=6
        [ "$width_tier" = "split" ] && bar_width=4

        # One jq pass for the whole payload. Parsing it field by field meant
        # ~10 jq processes per render on the same JSON; the status line runs on
        # every redraw, so that was the dominant cost. Rounding happens in jq
        # too, which removes the per-field awk calls.
        #
        # The per-model weekly limit (e.g. Fable) lives in .limits[] under kind
        # "weekly_scoped" -- the legacy seven_day_opus / seven_day_sonnet fields
        # are always null now. Prefer an is_active entry, else take the first.
        # `.limits[]?` tolerates limits being absent or not an array, and
        # `tonumber? // 0` tolerates a percentage arriving as a string.
        # One field per line, not @tsv: tab is IFS whitespace, so `read` collapses
        # runs of it and an empty field (no scoped limit -> empty display name)
        # would silently shift every later field along by one.
        {
            IFS= read -r five_hour_pct
            IFS= read -r seven_day_pct
            IFS= read -r five_hour_reset_iso
            IFS= read -r seven_day_reset_iso
            IFS= read -r scoped_name
            IFS= read -r scoped_pct
            IFS= read -r scoped_reset_iso
            IFS= read -r extra_enabled
            IFS= read -r extra_pct
            IFS= read -r extra_used
            IFS= read -r extra_limit
        } <<EOF
$(echo "$usage_data" | jq -r '
    def num: (tonumber? // 0);
    ([.limits[]? | select(.kind == "weekly_scoped")]
       | (map(select(.is_active)) + .) | first) as $scoped
    | [ (.five_hour.utilization  | num | round),
        (.seven_day.utilization  | num | round),
        (.five_hour.resets_at // ""),
        (.seven_day.resets_at // ""),
        (($scoped.scope.model.display_name // "") | gsub("[\\n\\r\\t]"; " ")),
        ($scoped.percent | num | round),
        ($scoped.resets_at // ""),
        (.extra_usage.is_enabled // false),
        (.extra_usage.utilization | num | round),
        ((.extra_usage.used_credits  | num) / 100 * 100 | round / 100),
        ((.extra_usage.monthly_limit | num) / 100 * 100 | round / 100)
      ] | .[] | tostring' 2>/dev/null)
EOF

        # ===== Sustainable burn: pace + trend =====
        # pace = the limit's remaining points divided by the WORKING days left
        # before it resets, i.e. what can be spent per working day and still
        # land on 100% exactly at the reset. A five-day week spreads 100 points
        # over 5 days, so a fresh window paces at 20%/day; the 14.3%/day
        # calendar figure quietly assumes the weekend is worked too.
        # trend compares used% against a BAND rather than a point: during
        # workday n of m, anything from (n-1)/m to n/m of the budget is on
        # track, because the whole of today's allowance is today's to spend. A
        # point built from complete workdays only made every Monday morning red
        # the moment 3 points had gone. Ahead of the band means the limit will
        # cap before the week is out, behind it means part of the subscription
        # goes unused; a +-3 slack outside the band stops it flickering at the
        # edges. On a non-workday no allowance is in play, so the band
        # collapses to its floor.
        #
        # Whole workdays only, no time-of-day interpolation: the percentages
        # arrive as integers anyway, and "three working days left" is the
        # granularity the decision actually gets made at.
        #
        # Measured against the per-model limit whenever one is being shown --
        # that is the limit that runs out first, and the bar this annotates.
        # Same gate as seg_scoped below, so pace always describes the bar it is
        # printed next to. Its own resets_at wins, falling back to the 7-day
        # timestamp (the two reset together) when the payload omits it.
        seg_pace=""
        if $SHOW_MODEL_LIMIT && [ -n "$scoped_name" ]; then
            pace_used="${scoped_pct:-0}"
            pace_reset_iso="$scoped_reset_iso"
        else
            pace_used="${seven_day_pct:-0}"
            pace_reset_iso=""
        fi
        case "$pace_reset_iso" in ''|null) pace_reset_iso="$seven_day_reset_iso" ;; esac

        pace_epoch=""
        case "$pace_reset_iso" in ''|null) ;; *) pace_epoch=$(iso_to_epoch "$pace_reset_iso") ;; esac
        if [ -n "$pace_epoch" ]; then
            ds_now=$(day_start_dow "$(now_ts)")
            ds_reset=$(day_start_dow "$pace_epoch")
            # Whole local days from today to the reset's day. Rounded rather
            # than divided: a DST change makes one of those days 23 or 25 hours
            # long, and truncation would lose a day either side of it.
            pace_days=""
            if [ -n "$ds_now" ] && [ -n "$ds_reset" ]; then
                pace_days=$(( (${ds_reset%% *} - ${ds_now%% *} + 43200) / 86400 ))
            fi

            # No strftime in macOS awk, so the weekday of each day in the
            # window is derived from today's, which bash passes in.
            pace_tv=""
            [ -n "$pace_days" ] && pace_tv=$(awk \
                -v used="$pace_used" -v dtr="$pace_days" \
                -v dow0="${ds_now##* }" -v wd=",${SL_WORK_DAYS}," 'BEGIN{
                # Day indices, 0 = today. The reset is 7 days after the
                # previous one, so the window is [dtr-7, dtr) and today has to
                # lie inside it; anything else is stale or nonsense data.
                if (dtr < 0 || dtr > 7 || dow0 < 1 || dow0 > 7) exit 1
                for (i = dtr - 7; i < dtr; i++) {
                    dow = ((dow0 - 1 + i) % 7 + 7) % 7 + 1
                    if (index(wd, dow) == 0) continue
                    total++
                    if (i < 0) elapsed++; else left++   # today counts as left
                }
                if (total <= 0) exit 1                  # no workdays: no baseline
                rem = 100 - used; if (rem < 0) rem = 0
                d = (left < 1) ? 1 : left   # nothing but today: all that remains
                pr = rem / d
                # Today is workday elapsed+1 of total, so its band runs from
                # elapsed/total to (elapsed+1)/total. Only its distance is
                # reported, signed: + past the top, - short of the floor, 0
                # anywhere inside the band or its slack. Comparing here rather
                # than in bash keeps the band edges off a second rounding.
                lo = elapsed / total * 100
                hi = (index(wd, dow0) > 0) ? (elapsed + 1) / total * 100 : lo
                dv = (used > hi + 3) ? used - hi : (used < lo - 3) ? used - lo : 0
                # One decimal below 10, where rounding starts to matter. The
                # last two fields are pace and the baseline in tenths, for
                # the integer comparison in pacecol.
                printf "%s %.0f %.0f %.0f\n", \
                    (pr < 10) ? sprintf("%.1f", pr) : sprintf("%.0f", pr), \
                    dv, pr * 10, 1000 / total
            }' 2>/dev/null)

            if [ -n "$pace_tv" ]; then
                read -r pace_val pace_trend pace_tenths pace_base <<< "$pace_tv"
                seg_pace=" $(pacecol "$pace_tenths" "$pace_base")${pace_val}%/d${reset}"
                if   [ "$pace_trend" -gt 0 ] 2>/dev/null; then seg_pace+=" ${red}▲+${pace_trend}${reset}"
                elif [ "$pace_trend" -lt 0 ] 2>/dev/null; then seg_pace+=" ${cyan}▼${pace_trend}${reset}"
                else                                           seg_pace+=" ${green}✓${reset}"
                fi
            fi
        fi

        # Four variants of the rate-limit group, richest first:
        #   rl_rich  bars + reset times + pace + extra usage
        #   rl_mid   bars + pace + extra usage
        #   rl_pace  bars + pace
        #   rl_lean  bars only
        # The ladder at the end emits the richest one that fits the space it
        # has. Keeping a lean variant matters: extra-usage credits add ~30
        # columns, which can overflow line two on its own.
        seg_5h="${dim}5h${reset} $(build_bar "${five_hour_pct:-0}" "$bar_width") ${cyan}${five_hour_pct:-0}%${reset}"
        seg_7d="${sep}${dim}7d${reset} $(build_bar "${seven_day_pct:-0}" "$bar_width") ${cyan}${seven_day_pct:-0}%${reset}"

        # Rendered inside the 7d segment rather than as its own: both are weekly
        # limits resetting at the same time, so one shared reset label covers
        # the pair and saves a separator plus a second timestamp.
        seg_scoped=""
        if $SHOW_MODEL_LIMIT && [ -n "$scoped_name" ]; then
            seg_scoped=" ${dim}$(esc_data "$(truncate_str "$scoped_name" 8)")${reset} $(build_bar "${scoped_pct:-0}" "$bar_width") ${cyan}${scoped_pct:-0}%${reset}"
        fi

        # Extra usage, when the account has it enabled.
        seg_extra=""
        if [ "$extra_enabled" = "true" ]; then
            seg_extra="${sep}${dim}extra${reset} $(build_bar "${extra_pct:-0}" "$bar_width") ${cyan}\$$(printf '%.2f' "${extra_used:-0}")${dim}/\$$(printf '%.2f' "${extra_limit:-0}")${reset}"
        fi

        # rl_bare drops the per-model bar too: the last thing worth giving up,
        # and the only way to fit at all when wrapping is disabled and the
        # terminal is narrow.
        #
        # rl_pace is its own rung so pace is given up BEFORE the per-model bar
        # it annotates: a bar with no pace still says something, a pace with no
        # bar does not. seg_pace lands after the per-model percentage, or after
        # the 7d one on an account with no per-model limit (seg_scoped empty).
        rl_bare="${seg_5h}${seg_7d}"
        rl_lean="${rl_bare}${seg_scoped}"
        rl_pace="${rl_lean}${seg_pace}"
        rl_mid="${rl_pace}${seg_extra}"
        rl_rich="$rl_mid"

        # Formatting the two reset timestamps costs ~10 subprocesses (date has
        # no portable one-shot form here), so only pay for it when there is a
        # chance they will be shown: appended to line one, or alone on line two.
        # RESET_COST is the combined width of " reset 4:40p.m." and
        # " reset aug 28, 3:00a.m.".
        line1_len=$(vis_len "$out")
        mid_len=$(vis_len "$rl_mid")
        RESET_COST=30
        if [ $(( line1_len + 3 + mid_len + RESET_COST )) -le "$USABLE_WIDTH" ] \
           || { $WRAP_NARROW && [ $(( mid_len + RESET_COST )) -le "$USABLE_WIDTH" ]; }; then
            five_hour_reset=$(format_reset_time "$five_hour_reset_iso" "time")
            seven_day_reset=$(format_reset_time "$seven_day_reset_iso" "datetime")
            r5=""; [ -n "$five_hour_reset" ]  && r5=" ${dim}↺ ${five_hour_reset}${reset}"
            r7=""; [ -n "$seven_day_reset" ] && r7=" ${dim}↺ ${seven_day_reset}${reset}"
            rl_rich="${seg_5h}${r5}${seg_7d}${seg_scoped}${seg_pace}${r7}${seg_extra}"
        fi
    fi
fi

# Attach the rate-limit group, emitting the richest layout that fits.
#
# A second line is worth it for the per-model bar and nothing else: rl_bare is
# the only variant that drops that bar, and it is the whole reason the group is
# worth showing on an account that has one. Reset times and extra-usage credits
# are given up instead of wrapped for, so content is NOT monotone in width -- at
# one column narrower, rung 3 stops fitting and the wrap that follows has room
# for the timestamps as well. Only wrapping being switched off makes rl_bare the
# answer.
#   1-4. one line:  with resets / with extra usage / with pace / bars + per-model
#   5-8. two lines: same order, line two having room the single line lacked
#   9.   one line, bars only -- WRAP_NARROW=false, the least-bad single line
# Every branch is fit-checked, so no layout is chosen that would be clipped by
# the renderer, whatever the branch name, cwd, model name or extra-usage width.
if [ -n "$rl_bare" ]; then
    rich_len=$(vis_len "$rl_rich")
    pace_len=$(vis_len "$rl_pace")
    lean_len=$(vis_len "$rl_lean")
    if   [ $(( line1_len + 3 + rich_len )) -le "$USABLE_WIDTH" ]; then out+="${sep}${rl_rich}"
    elif [ $(( line1_len + 3 + mid_len  )) -le "$USABLE_WIDTH" ]; then out+="${sep}${rl_mid}"
    elif [ $(( line1_len + 3 + pace_len )) -le "$USABLE_WIDTH" ]; then out+="${sep}${rl_pace}"
    elif [ $(( line1_len + 3 + lean_len )) -le "$USABLE_WIDTH" ]; then out+="${sep}${rl_lean}"
    elif $WRAP_NARROW; then
        if   [ "$rich_len" -le "$USABLE_WIDTH" ]; then out+=$'\n'"$rl_rich"
        elif [ "$mid_len"  -le "$USABLE_WIDTH" ]; then out+=$'\n'"$rl_mid"
        elif [ "$pace_len" -le "$USABLE_WIDTH" ]; then out+=$'\n'"$rl_pace"
        elif [ "$lean_len" -le "$USABLE_WIDTH" ]; then out+=$'\n'"$rl_lean"
        else                                          out+=$'\n'"$rl_bare"
        fi
    else
        out+="${sep}${rl_bare}"
    fi
fi

printf "%b" "$out"
exit 0
