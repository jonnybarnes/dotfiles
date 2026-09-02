#!/bin/bash
# Tests for the thinking/effort segment of claude/statusline.isaacaudet.sh.
#
# The state comes from the payload Claude Code pipes in (.thinking.enabled and
# .effort.level), not from alwaysThinkingEnabled in settings.json: the Option+T
# toggle is session-only, so a settings read cannot track it. Claude Code's own
# payload builder is `thinking:{enabled: lt !== false}`, so an absent field
# means enabled -- which is why the missing-field cases below expect the filled
# diamond rather than the hollow one.
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/statusline.isaacaudet.sh"
# Widths below are USABLE widths, converted to a TERM_WIDTH here. The script
# tiers on USABLE_WIDTH (columns minus padding both sides minus a margin), so a
# raw TERM_WIDTH would land in a different tier the moment statusLine.padding
# changed -- same convention as width_test.sh.
PAD=$(jq -r '.statusLine.padding // 0' "$HOME/.claude/settings.json" 2>/dev/null || echo 0)
OVERHEAD=$(( 2 * PAD + 1 ))
export STATUSLINE_CACHE_DIR="$(mktemp -d)"
CACHE="$STATUSLINE_CACHE_DIR/statusline-usage-cache.json"
REPO="$(mktemp -d)"

cleanup() { rm -rf "$STATUSLINE_CACHE_DIR" "$REPO"; }
trap cleanup EXIT

# Seed the usage cache. Without a fixture the first render treats the rate
# limits as live and curls /api/oauth/usage with the real OAuth token, which
# makes the test non-hermetic and sensitive to account state.
cat > "$CACHE" <<'JSON'
{"five_hour":{"utilization":5.0,"resets_at":"2026-08-27T15:40:00+00:00"},
 "seven_day":{"utilization":7.0,"resets_at":"2026-08-28T02:00:00+00:00"},
 "extra_usage":{"is_enabled":false},
 "limits":[]}
JSON

git -C "$REPO" init -q 2>/dev/null
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init 2>/dev/null

pass=0; fail=0
ok()  { echo "  PASS  $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1"; [ -n "$2" ] && printf '%s\n' "$2" | sed 's/^/          /'; fail=$((fail+1)); }

# Build the payload in python so a thinking/effort block can be omitted
# entirely -- absent and false are different states here.
stdin_json() {
    CWD="$REPO" THINKING="$1" EFFORT="$2" python3 -c '
import json, os
p = {"model": {"display_name": "Opus 5"},
     "cwd": os.environ["CWD"],
     "cost": {"total_cost_usd": 0.5},
     "context_window": {"context_window_size": 200000,
                        "current_usage": {"input_tokens": 1000}}}
t = os.environ["THINKING"]
if t: p["thinking"] = {"enabled": t == "true"}
e = os.environ["EFFORT"]
if e: p["effort"] = {"level": e}
print(json.dumps(p))'
}

# $1 = thinking ("true"/"false"/"" for absent), $2 = effort level or "",
# $3 = USABLE width. ANSI stripped.
render() {
    stdin_json "$1" "$2" \
    | TERM_WIDTH="$(( ${3:-200} + OVERHEAD ))" bash "$SCRIPT" 2>&1 | sed $'s/\033\[[0-9;]*m//g'
}

has()  { case "$(render "$1" "$2" "$4")" in *"$3"*) ok "$5";; *) bad "$5" "want '$3' in: $(render "$1" "$2" "$4")";; esac; }
lacks() { case "$(render "$1" "$2" "$4")" in *"$3"*) bad "$5" "unwanted '$3' in: $(render "$1" "$2" "$4")";; *) ok "$5";; esac; }

echo "Thinking state from the payload:"
has  true  high  "◆ high" 200 "enabled + high effort renders a filled diamond and the level"
has  false low   "◇ low"  200 "disabled renders a hollow diamond"
has  ""    high  "◆ high" 200 "absent thinking field means enabled, matching Claude Code's default"

echo
echo "Effort level as the label:"
has  true  medium "◆ medium" 200 "medium is spelled out"
has  true  xhigh  "◆ xhigh"  200 "xhigh is spelled out"
has  true  max    "◆ max"    200 "max is spelled out"
lacks true  high   "thinking"  200 "the static word 'thinking' is gone when an effort level is known"

echo
echo "Fallbacks and tiers:"
has  true  ""     "◆ thinking" 200 "absent effort falls back to the old label"
has  true  garbage "◆ thinking" 200 "an unrecognised level falls back rather than widening the line"
has  true  high    "◆ high"     120 "the label survives the wide tier"
# The split tier (76-99) is unreachable while WRAP_NARROW=true -- that band is
# overridden to wide and wrapped -- so only narrow is asserted here.
lacks true  high   "◆"           60  "narrow tier hides the segment"

echo
echo "  $pass passed, $fail failed"
[ "$fail" -eq 0 ]
