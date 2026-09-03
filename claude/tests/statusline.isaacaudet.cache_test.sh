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
FAIL_MARKER="$STATUSLINE_CACHE_DIR/statusline-usage-fail"
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
export CURL_MARKER_SEEN="$STUB/marker-seen"
export FAIL_MARKER
cat > "$STUB/curl" <<'SH'
#!/bin/bash
echo call >> "$CURL_CALLS"
# Record whether the backoff marker was already written when the fetch
# started, which is what a concurrent redraw would see.
[ -f "$FAIL_MARKER" ] && echo seen >> "$CURL_MARKER_SEEN"
# With $CURL_FAIL set, behave as curl does with no network: nothing on
# stdout and a non-zero exit.
[ -n "$CURL_FAIL" ] && exit 6
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
    age_file "$CACHE" "$1"
    rm -f "$FAIL_MARKER"
    : > "$CURL_CALLS"
    : > "$CURL_MARKER_SEEN"
}

# Backdate $1 by $2 seconds.
age_file() {
    FILE="$1" AGE="$2" python3 -c '
import os, time
f = os.environ["FILE"]; t = time.time() - int(os.environ["AGE"])
os.utime(f, (t, t))'
}

calls() { wc -l < "$CURL_CALLS" | tr -d ' '; }

# No cached response and no backoff marker: a cold /tmp.
cold_cache() { rm -f "$CACHE" "$FAIL_MARKER"; : > "$CURL_CALLS"; : > "$CURL_MARKER_SEEN"; }

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
# The refresh is gated on the same width check as the bars themselves, so the
# two must agree at every width, 35 being RL_MIN_WIDTH -- the narrowest usable
# width the bars still fit on their own line.
echo
echo "Every width that shows the bars refreshes them:"

for u in 245 115 85 68 50 35; do
    cached_response_aged 360
    out=$(render "$u")
    if case "$out" in *"5h"*) true ;; *) false ;; esac; then
        [ "$(calls)" = "1" ] && ok "usable $u: bars shown and refreshed" \
                             || bad "usable $u: bars shown but served stale" "$out"
    else
        bad "usable $u: expected the bars to be shown" "$out"
    fi
done

# One column below RL_MIN_WIDTH the group is dropped entirely — nothing is
# shown, so nothing should be paid for either.
cached_response_aged 360
out=$(render 34)
case "$out" in *"5h"*) bad "usable 34: no bars below the group's floor" "$out" ;;
               *) ok "usable 34: no bars below the group's floor" ;; esac
[ "$(calls)" = "0" ] && ok "usable 34: no API call when no bars are shown" \
                     || bad "usable 34: no API call when no bars are shown" "$out"

# --------------------------------------------------------- offline retry backoff
# With no network, curl can burn --max-time 10 before giving up. A failed fetch
# is remembered so redraws in the next minute do not each pay for that.
echo
echo "A failed fetch backs off instead of retrying every redraw:"

export CURL_FAIL=1

cached_response_aged 360
out=$(render 245)
[ "$(calls)" = "1" ] && ok "offline: first redraw attempts the fetch" \
                     || bad "offline: first redraw attempts the fetch" "$out"
case "$out" in *"5%"*) ok "offline: falls back to the stale response" ;;
               *) bad "offline: falls back to the stale response" "$out" ;; esac
out=$(render 245)
[ "$(calls)" = "1" ] && ok "offline: the next redraw does not retry" \
                     || bad "offline: the next redraw does not retry" "$out"
case "$out" in *"5%"*) ok "offline: still shows the stale response while backed off" ;;
               *) bad "offline: still shows the stale response while backed off" "$out" ;; esac

# The marker must be the thing that ages, not be re-stamped by the redraws it
# suppresses — otherwise the backoff never lapses and the bars never return.
age_file "$FAIL_MARKER" 90
out=$(render 245)
[ "$(calls)" = "2" ] && ok "offline: retries once the backoff lapses" \
                     || bad "offline: retries once the backoff lapses" "$out"
out=$(render 245)
[ "$(calls)" = "2" ] && ok "offline: the second failure restarts the backoff" \
                     || bad "offline: the second failure restarts the backoff" "$out"

# The marker goes down before the request, not after it: a fetch is in flight
# for as long as curl takes to time out, and every redraw starting inside that
# window would otherwise launch its own. The cache dir is shared between
# sessions, so those redraws are not hypothetical. Starting from no marker at
# all, so only this attempt's own write can satisfy it.
cold_cache
out=$(render 245)
case "$(cat "$CURL_MARKER_SEEN")" in *seen*) ok "offline: the in-flight fetch marked itself before calling" ;;
                                     *) bad "offline: the in-flight fetch marked itself before calling" "$out" ;; esac

# A cold /tmp is the case a touch of the response file cannot cover: there is
# no response to touch, so every redraw would pay the timeout.
cold_cache
out=$(render 245)
[ "$(calls)" = "1" ] && ok "offline, no cache: first redraw attempts the fetch" \
                     || bad "offline, no cache: first redraw attempts the fetch" "$out"
out=$(render 245)
[ "$(calls)" = "1" ] && ok "offline, no cache: the next redraw does not retry" \
                     || bad "offline, no cache: the next redraw does not retry" "$out"
case "$out" in *"5h"*) bad "offline, no cache: no bars, having no data" "$out" ;;
               *) ok "offline, no cache: no bars, having no data" ;; esac

unset CURL_FAIL

# Back online, a marker that has lapsed must not keep suppressing fetches.
cold_cache
: > "$FAIL_MARKER"
age_file "$FAIL_MARKER" 90
out=$(render 245)
case "$out" in *"42%"*) ok "back online: fetches and renders the fresh percentage" ;;
                *) bad "back online: fetches and renders the fresh percentage" "$out" ;; esac
[ ! -f "$FAIL_MARKER" ] && ok "back online: a success clears the backoff marker" \
                        || bad "back online: a success clears the backoff marker"
cold_cache
out=$(render 245)
case "$(cat "$CURL_MARKER_SEEN")" in *seen*) ok "back online: a succeeding fetch is marked while it runs" ;;
                                     *) bad "back online: a succeeding fetch is marked while it runs" "$out" ;; esac
[ ! -f "$FAIL_MARKER" ] && ok "back online: and unmarked once it lands" \
                        || bad "back online: and unmarked once it lands" "$out"

# ------------------------------------------------------------ nothing to fetch
# No credentials is not a network failure: it costs no timeout, and the next
# redraw could succeed the instant a login lands. Backing off would hide the
# bars for a minute for nothing.
echo
echo "No credentials is not a failure to back off from:"

cat > "$STUB/security" <<'SH'
#!/bin/bash
exit 44
SH
chmod +x "$STUB/security"
NOHOME="$(mktemp -d)"

cold_cache
out=$(stdin_json "$REPO" \
      | env -u CLAUDE_CODE_OAUTH_TOKEN HOME="$NOHOME" TERM_WIDTH=$(( 245 + OVERHEAD )) \
            bash "$SCRIPT" 2>&1 | sed $'s/\033\[[0-9;]*m//g')
[ "$(calls)" = "0" ] && ok "no token: no fetch attempted" \
                     || bad "no token: no fetch attempted" "$out"
[ ! -f "$FAIL_MARKER" ] && ok "no token: no backoff marker written" \
                        || bad "no token: no backoff marker written" "$out"

rm -f "$STUB/security"
rm -rf "$NOHOME"

echo
echo "  $pass passed, $fail failed"
[ "$fail" -eq 0 ]
