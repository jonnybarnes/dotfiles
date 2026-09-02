#!/bin/bash
# Tests for the usage-API cache in claude/statusline.isaacaudet.sh: how long a
# cached response is reused before the 5h/7d bars are refetched, and that any
# render which SHOWS the bars is also a render that refreshes them.
#
# Widths are given in USABLE columns, as in the sibling width test: the
# script derives those from COLUMNS minus statusLine.padding on both sides
# minus a margin, so a raw TERM_WIDTH would make these assertions depend on
# the padding in the live settings.json.
#
# Sibling variants in claude/ (statusline.burnrate.sh, statusline.original.sh)
# are NOT covered by these tests.
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/statusline.isaacaudet.sh"
PAD=$(jq -r '.statusLine.padding // 0' "$HOME/.claude/settings.json" 2>/dev/null || echo 0)
OVERHEAD=$(( 2 * PAD + 1 ))

# Render into a throwaway cache directory. The live cache must not be touched:
# ~/.claude/statusline.sh is a symlink to the script under test, so a fixture
# written there is shown in the running TUI as real usage until it expires.
export STATUSLINE_CACHE_DIR="$(mktemp -d)"
CACHE="$STATUSLINE_CACHE_DIR/statusline-usage-cache.json"
REPO="$(mktemp -d)"
STUB="$(mktemp -d)"

cleanup() { rm -rf "$STATUSLINE_CACHE_DIR" "$REPO" "$STUB"; }
trap cleanup EXIT

git -C "$REPO" init -q 2>/dev/null
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init 2>/dev/null

# A curl stub, first on PATH, records each call and replies with $CURL_REPLY.
# Every refresh in this file goes through it, so no test can reach the real
# usage API. The token is faked too, so the keychain is never read.
export CLAUDE_CODE_OAUTH_TOKEN=test-token
export CURL_CALLS="$STUB/calls"
cat > "$STUB/curl" <<'SH'
#!/bin/bash
echo call >> "$CURL_CALLS"
printf '%s' "$CURL_REPLY"
SH
chmod +x "$STUB/curl"
export PATH="$STUB:$PATH"
export CURL_REPLY='{"five_hour":{"utilization":42.0,"resets_at":"2026-08-27T15:40:00+00:00"},
                    "seven_day":{"utilization":44.0,"resets_at":"2026-08-28T02:00:00+00:00"},
                    "extra_usage":{"is_enabled":false},"limits":[]}'

pass=0; fail=0
ok()   { echo "  PASS  $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL  $1"; [ -n "$2" ] && printf '%s\n' "$2" | sed 's/^/          /'; fail=$((fail+1)); }

stdin_json() {
    CWD="$1" python3 -c '
import json, os
print(json.dumps({"model": {"display_name": "Opus 5"},
                  "cwd": os.environ["CWD"],
                  "cost": {"total_cost_usd": 0.5},
                  "context_window": {"context_window_size": 200000,
                                     "current_usage": {"input_tokens": 1000}}}))'
}

# Render, with ANSI stripped. $1 = USABLE width.
render() {
    stdin_json "$REPO" | TERM_WIDTH=$(( $1 + OVERHEAD )) bash "$SCRIPT" 2>&1 \
    | sed $'s/\033\[[0-9;]*m//g'
}

# A cached response whose bars read 5% / 7%, aged $1 seconds.
cached_response_aged() {
    cat > "$CACHE" <<'JSON'
{"five_hour":{"utilization":5.0,"resets_at":"2026-08-27T15:40:00+00:00"},
 "seven_day":{"utilization":7.0,"resets_at":"2026-08-28T02:00:00+00:00"},
 "extra_usage":{"is_enabled":false},"limits":[]}
JSON
    AGE="$1" FILE="$CACHE" python3 -c '
import os, time
f = os.environ["FILE"]; t = time.time() - int(os.environ["AGE"])
os.utime(f, (t, t))'
    : > "$CURL_CALLS"
}

calls() { wc -l < "$CURL_CALLS" | tr -d ' '; }

# ------------------------------------------------------------------- 5min TTL
echo "Usage cache TTL (5 minutes):"

cached_response_aged 240
out=$(render 245)
[ "$(calls)" = "0" ] && ok "4min old: served from cache, no API call" \
                     || bad "4min old: served from cache, no API call" "$out"
case "$out" in *"5%"*) ok "4min old: renders the cached percentage" ;;
               *) bad "4min old: renders the cached percentage" "$out" ;; esac

cached_response_aged 360
out=$(render 245)
[ "$(calls)" = "1" ] && ok "6min old: refetched" || bad "6min old: refetched" "$out"
case "$out" in *"42%"*) ok "6min old: renders the fresh percentage" ;;
               *) bad "6min old: renders the fresh percentage" "$out" ;; esac
case "$(cat "$CACHE")" in *"42.0"*) ok "6min old: fresh response written back" ;;
                          *) bad "6min old: fresh response written back" "$(cat "$CACHE")" ;; esac

# Half an hour was inside the old one-hour TTL: the bars would sit unchanged.
cached_response_aged 1800
out=$(render 245)
[ "$(calls)" = "1" ] && ok "30min old: refetched, not held for the hour" \
                     || bad "30min old: refetched, not held for the hour" "$out"

# ------------------------------------------------- bars shown => bars refreshed
# The refresh is gated on the same tier check as the bars themselves, so the
# two must agree at every width: wrapped onto line two included, and 68 being
# WRAP_FLOOR, the narrowest width that still shows them.
echo
echo "Every width that shows the bars refreshes them:"

for u in 245 115 85 68; do
    cached_response_aged 360
    out=$(render "$u")
    if case "$out" in *"5h"*) true ;; *) false ;; esac; then
        [ "$(calls)" = "1" ] && ok "usable $u: bars shown and refreshed" \
                             || bad "usable $u: bars shown but served stale" "$out"
    else
        bad "usable $u: expected the bars to be shown" "$out"
    fi
done

# One column below the wrap floor the group is dropped entirely — nothing is
# shown, so nothing should be paid for either.
cached_response_aged 360
out=$(render 67)
case "$out" in *"5h"*) bad "usable 67: no bars at the narrow tier" "$out" ;;
               *) ok "usable 67: no bars at the narrow tier" ;; esac
[ "$(calls)" = "0" ] && ok "usable 67: no API call when no bars are shown" \
                     || bad "usable 67: no API call when no bars are shown" "$out"

echo
echo "  $pass passed, $fail failed"
[ "$fail" -eq 0 ]
