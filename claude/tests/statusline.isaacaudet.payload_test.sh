#!/bin/bash
# Tests for claude/statusline.isaacaudet.sh — the Isaac Audet-inspired Claude
# Code status line (the variant symlinked from ~/.claude/statusline.sh).
#
# Sibling variants in claude/ (statusline.burnrate.sh, statusline.original.sh)
# are NOT covered by these tests.
#
# Payload shapes: how the usage API's rate-limit JSON is rendered, in
# particular the per-model ("weekly_scoped") limit such as Fable, and how the
# renderer degrades when the group will not fit.
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/statusline.isaacaudet.sh"
# Render into a throwaway cache directory. The live cache must not be touched:
# ~/.claude/statusline.sh is a symlink to the script under test, so a fixture
# written there is shown in the running TUI as real usage until it expires.
export STATUSLINE_CACHE_DIR="$(mktemp -d)"
CACHE="$STATUSLINE_CACHE_DIR/statusline-usage-cache.json"
REPO="$(mktemp -d)"

cleanup() { rm -rf "$STATUSLINE_CACHE_DIR" "$REPO"; }
trap cleanup EXIT

git -C "$REPO" init -q 2>/dev/null
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init 2>/dev/null

pass=0; fail=0
ok()   { echo "  PASS  $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL  $1"; [ -n "$2" ] && printf '%s\n' "$2" | sed 's/^/          /'; fail=$((fail+1)); }

# Render, with ANSI stripped. $1 = TERM_WIDTH, $2 = cwd, $3 = model name.
render() {
    local w="$1" cwd="${2:-$REPO}" model="${3:-Opus 5}"
    stdin_json "$cwd" "$model" \
    | TERM_WIDTH="$w" bash "$SCRIPT" 2>&1 | sed $'s/\033\[[0-9;]*m//g'
}

# Build the payload in python: a backslash written into shell-constructed JSON
# is a JSON escape, so "pro\nj" would reach the script as a REAL newline rather
# than the literal characters the hostile-string tests mean to exercise.
stdin_json() {
    CWD="$1" MODEL="$2" python3 -c '
import json, os
print(json.dumps({"model": {"display_name": os.environ["MODEL"]},
                  "cwd": os.environ["CWD"],
                  "cost": {"total_cost_usd": 0.5},
                  "context_window": {"context_window_size": 200000,
                                     "current_usage": {"input_tokens": 1000}}}))'
}
nth()   { printf '%s\n' "$1" | sed -n "${2}p"; }
count() { printf '%s\n' "$1" | wc -l | tr -d ' '; }
vis()   { printf '%s' "$1" | python3 -c "
import sys,unicodedata
s=sys.stdin.read(); print(sum(2 if unicodedata.east_asian_width(c) in 'WF' else 1 for c in s))"; }

fixture() { cat > "$CACHE"; }

BASE='"five_hour":{"utilization":5.0,"resets_at":"2026-08-27T15:40:00+00:00"},
      "seven_day":{"utilization":7.0,"resets_at":"2026-08-28T02:00:00+00:00"}'

# ---------------------------------------------------------------- scoped limit
echo "Per-model (weekly_scoped) limit:"
fixture <<JSON
{$BASE,"extra_usage":{"is_enabled":false},
 "limits":[{"kind":"weekly_scoped","percent":10,"scope":{"model":{"display_name":"Fable"}},"is_active":true}]}
JSON
out=$(render 250)
# Assert the label AND its percentage together, so a bar rendered with the
# wrong number cannot pass.
case "$out" in *"Fable"*"10%"*) ok "wide: renders 'Fable' with its percentage" ;;
               *) bad "wide: renders 'Fable' with its percentage" "$out" ;; esac

# The usage group always gets a line of its own, however wide the terminal is.
for w in 250 116 90; do
    out=$(render "$w")
    [ "$(count "$out")" = "2" ] && ok "width $w: usage is on its own line" \
                                || bad "width $w: usage is on its own line" "$out"
    case "$(nth "$out" 2)" in *"Fable"*"10%"*) ok "width $w: Fable is on line two" ;;
                              *) bad "width $w: Fable is on line two" "$out" ;; esac
    case "$(nth "$out" 1)" in *"Fable"*) bad "width $w: Fable not duplicated on line one" "$out" ;;
                              *) ok "width $w: Fable not duplicated on line one" ;; esac
done

# A line of its own is what buys room for the reset times: both the 5-hour
# clock time and the 7-day date survive down to a laptop-sized terminal, where
# they used to be the first thing given up.
for w in 250 116 100; do
    out=$(render "$w")
    case "$(nth "$out" 2)" in *"↺"*"↺"*) ok "width $w: both reset times are shown" ;;
                              *) bad "width $w: both reset times are shown" "$out" ;; esac
done

# The per-model bar is the reason the group exists on a Fable-capable account,
# so it must survive by wrapping and never be dropped to squeeze the group onto
# one line. Regression: on a ~110-column laptop it vanished silently.
echo "Mid widths keep the per-model bar (wrapping if need be):"
for w in 105 110 116 120; do
    out=$(render "$w" "$REPO" "Opus 5 (1M context)")
    case "$out" in *"Fable"*"10%"*) ok "width $w: Fable still shown" ;;
                   *) bad "width $w: Fable still shown" "$out" ;; esac
done

# The label must come from the payload, not be hardcoded.
fixture <<JSON
{$BASE,"extra_usage":{"is_enabled":false},
 "limits":[{"kind":"weekly_scoped","percent":42,"scope":{"model":{"display_name":"Nimbus"}},"is_active":false}]}
JSON
out=$(render 250)
case "$out" in *"Nimbus"*"42%"*) ok "label comes from scope.model.display_name" ;;
               *) bad "label comes from scope.model.display_name" "$out" ;; esac
case "$out" in *Fable*) bad "no hardcoded 'Fable'" "$out" ;; *) ok "no hardcoded 'Fable'" ;; esac

# ------------------------------------------------------------- malformed input
echo "Malformed / legacy payloads still render the 5h and 7d bars:"
for desc in "no limits key:{$BASE,\"extra_usage\":{\"is_enabled\":false}}" \
            "limits is a string:{$BASE,\"extra_usage\":{\"is_enabled\":false},\"limits\":\"nope\"}" \
            "limits has no scoped:{$BASE,\"extra_usage\":{\"is_enabled\":false},\"limits\":[{\"kind\":\"weekly_all\",\"percent\":7}]}" \
            "percent as string:{$BASE,\"extra_usage\":{\"is_enabled\":false},\"limits\":[{\"kind\":\"weekly_scoped\",\"percent\":\"42.7\",\"scope\":{\"model\":{\"display_name\":\"Str\"}},\"is_active\":true}]}"; do
    name="${desc%%:*}"; json="${desc#*:}"
    printf '%s' "$json" | fixture
    out=$(render 250)
    if [ "$(count "$out")" = "2" ] && case "$(nth "$out" 2)" in *"5h"*"7d"*) true;; *) false;; esac \
       && case "$out" in *error*|*null*|*"jq:"*|*"line "*) false;; *) true;; esac; then
        ok "$name"
    else bad "$name" "$out"; fi
done
# a string percentage should round, not become 0
case "$out" in *"Str"*"43%"*) ok "percent given as a string rounds to 43%" ;;
               *) bad "percent given as a string rounds to 43%" "$out" ;; esac

# ------------------------------------------------- extra usage (regression §1)
echo "Extra-usage credits must not overflow line two:"
fixture <<JSON
{$BASE,
 "extra_usage":{"is_enabled":true,"monthly_limit":200000,"used_credits":123456,"utilization":62.0},
 "limits":[{"kind":"weekly_scoped","percent":10,"scope":{"model":{"display_name":"Fable"}},"is_active":true}]}
JSON
out=$(render 250)
case "$out" in *"extra"*) ok "wide: extra-usage segment is shown" ;;
               *) bad "wide: extra-usage segment is shown" "$out" ;; esac
for w in 73 80 95; do
    out=$(render "$w"); u=$(( w - 5 )); worst=0
    while IFS= read -r l; do c=$(vis "$l"); [ "$c" -gt "$worst" ] && worst=$c; done <<< "$out"
    [ "$worst" -le "$u" ] \
        && ok "width $w: no line exceeds usable $u (worst $worst)" \
        || bad "width $w: no line exceeds usable $u (worst $worst)" "$out"
done

# ------------------------------------------ hostile strings (regression §9)
echo "Control characters and backslashes in payload data:"
fixture <<JSON
{$BASE,"extra_usage":{"is_enabled":false},
 "limits":[{"kind":"weekly_scoped","percent":10,"scope":{"model":{"display_name":"A\nB"}},"is_active":true}]}
JSON
out=$(render 250)
[ "$(count "$out")" = "2" ] && ok "newline in display_name does not split the line" \
                            || bad "newline in display_name does not split the line" "$out"
fixture <<JSON
{$BASE,"extra_usage":{"is_enabled":false},"limits":[]}
JSON
mkdir -p "$REPO/sub"
out=$(render 250 "$REPO/pro\\nj")
[ "$(count "$out")" = "2" ] && ok "literal backslash-n in cwd does not split the line" \
                            || bad "literal backslash-n in cwd does not split the line" "$out"
out=$(render 250 "$REPO" 'Opus\n5')
[ "$(count "$out")" = "2" ] && ok "literal backslash-n in model name does not split the line" \
                            || bad "literal backslash-n in model name does not split the line" "$out"

echo; echo "pass=$pass fail=$fail"; [ "$fail" -eq 0 ]
