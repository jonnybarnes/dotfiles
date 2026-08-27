#!/bin/bash
# Tests for claude/statusline.isaacaudet.sh — the Isaac Audet-inspired Claude
# Code status line (the variant symlinked from ~/.claude/statusline.sh).
#
# Sibling variants in claude/ (statusline.burnrate.sh, statusline.original.sh)
# are NOT covered by these tests.
#
# Width invariants.
#
# Expressed in USABLE width (what the renderer actually has: COLUMNS minus
# padding on both sides minus a margin), since that is what the script wraps on.
# Asserting invariants rather than fixed line counts keeps these from rotting
# every time a segment's content changes.
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/statusline.isaacaudet.sh"
CACHE="/tmp/claude/statusline-usage-cache.json"
PAD=$(jq -r '.statusLine.padding // 0' "$HOME/.claude/settings.json" 2>/dev/null || echo 0)
OVERHEAD=$(( 2 * PAD + 1 ))
BACKUP=$(mktemp); [ -f "$CACHE" ] && cp "$CACHE" "$BACKUP"
REPO=$(mktemp -d)
# If there was no cache to begin with, REMOVE the fixture rather than leaving
# it: the status line would treat it as a fresh response for up to an hour.
cleanup() {
    if [ -s "$BACKUP" ]; then cp "$BACKUP" "$CACHE"; else rm -f "$CACHE"; fi
    rm -f "$BACKUP"; rm -rf "$REPO"
}
trap cleanup EXIT

cat > "$CACHE" <<'JSON'
{"five_hour":{"utilization":5.0,"resets_at":"2026-08-27T15:40:00+00:00"},
 "seven_day":{"utilization":7.0,"resets_at":"2026-08-28T02:00:00+00:00"},
 "extra_usage":{"is_enabled":false},
 "limits":[{"kind":"weekly_scoped","group":"weekly","percent":10,"resets_at":"2026-08-28T02:00:00+00:00","scope":{"model":{"display_name":"Fable"}},"is_active":true}]}
JSON
git -C "$REPO" init -q 2>/dev/null
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init 2>/dev/null

widths() { python3 -c "
import sys,re,unicodedata
for ln in sys.stdin.read().rstrip('\n').split('\n'):
    p=re.sub(r'\033\[[0-9;]*m','',ln)
    print(sum(2 if unicodedata.east_asian_width(c) in 'WF' else 1 for c in p))"; }

pass=0; fail=0
check() { # usable, branch, model, cost, [xfail-reason]
    local u="$1" branch="$2" model="$3" cost="$4" xfail="${5:-}"
    local w=$(( u + OVERHEAD ))
    git -C "$REPO" checkout -q -B "$branch" 2>/dev/null; rm -f /tmp/claude/git-*
    local stdin="{\"model\":{\"display_name\":\"$model\"},\"cwd\":\"$REPO\",\"cost\":{\"total_cost_usd\":$cost},\"context_window\":{\"context_window_size\":200000,\"current_usage\":{\"input_tokens\":45000,\"cache_read_input_tokens\":30000}}}"
    local out ws n mx=0 over=0
    out=$(TERM_WIDTH=$w bash "$SCRIPT" <<<"$stdin")
    ws=$(printf '%s' "$out" | widths)
    n=$(printf '%s\n' "$ws" | wc -l | tr -d ' ')
    while read -r c; do [ "$c" -gt "$u" ] && over=1; [ "$c" -gt "$mx" ] && mx=$c; done <<< "$ws"

    local why=""
    # INVARIANT 1: never exceed the usable width
    [ "$over" = "1" ] && why="line exceeds usable width"
    # INVARIANT 2: at most two lines
    [ "$n" -gt 2 ] && why="${why:-more than two lines}"
    # INVARIANT 3: only wrap when it was actually necessary
    if [ -z "$why" ] && [ "$n" = "2" ]; then
        local l1 l2; l1=$(printf '%s\n' "$ws" | sed -n 1p); l2=$(printf '%s\n' "$ws" | sed -n 2p)
        [ $(( l1 + 3 + l2 )) -le "$u" ] && why="wrapped unnecessarily (would have fit on one line)"
    fi

    local label="usable=$u branch=${#branch}ch model='${model:0:12}' lines=$n max=$mx"
    if [ -n "$xfail" ] && [ -n "$why" ]; then
        echo "  XFAIL $label -- $why (known, pre-existing: $xfail)"; pass=$((pass+1)); return
    fi
    if [ -z "$why" ]; then echo "  PASS  $label"; pass=$((pass+1))
    else echo "  FAIL  $label -- $why"
         printf '%s\n' "$out" | sed $'s/\033\[[0-9;]*m//g' | sed 's/^/          /'; fail=$((fail+1)); fi
}

SHORT=main
LONG=feature/some-really-long-branch-name-here
M1="Opus 5"
M2="Opus 5 (1M context)"

echo "Sweep of usable widths, short branch:"
for u in 200 155 150 130 116 110 100 95 85 75 68 67 60 40; do check "$u" "$SHORT" "$M1" 0.50; done
# Narrow tier has a ~35-col floor; nothing can fit below that. Verified byte-identical
# on the pre-change script, so not a regression.
check 25 "$SHORT" "$M1" 0.50 "narrow tier floor ~35 cols"
echo "Sweep with the real long model name:"
for u in 200 150 116 100 85 68 40; do check "$u" "$SHORT" "$M2" 4.61; done
echo "Sweep with a long branch name:"
for u in 200 150 116 100 85 68; do check "$u" "$LONG" "$M2" 4.61; done
check 40 "$LONG" "$M2" 4.61 "narrow tier floor ~43 cols with a long branch"
echo "Large cost figure:"
for u in 116 85 68; do check "$u" "$SHORT" "$M1" 1234.56; done

echo; echo "pass=$pass fail=$fail"; [ "$fail" -eq 0 ]
