#!/bin/bash
# Tests for the sustainable-burn indicator (pace + trend) in
# claude/statusline.isaacaudet.sh -- the variant symlinked from
# ~/.claude/statusline.sh. The sibling statusline.burnrate.sh, which has a
# richer sleep-aware version of the same idea, is NOT covered here.
#
# pace answers "how much of the weekly limit can I spend per WORKING day and
# still land on 100% at the reset", so every expectation below depends on
# which day of the week "now" is. SL_NOW pins it; without that the assertions
# would pass or fail according to the day the suite happened to run.
#
# TZ is pinned too: pace counts LOCAL calendar days, so the local day a UTC
# reset timestamp falls in -- and therefore how many workdays are left -- is
# otherwise a property of the machine running the tests.
export TZ=UTC

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/statusline.isaacaudet.sh"
# Widths below are USABLE widths, converted to a TERM_WIDTH here: the script
# picks its layout from USABLE_WIDTH (columns minus padding on both sides minus
# a margin), so a raw TERM_WIDTH would land on a different rung of the ladder
# the moment statusLine.padding changed -- same convention as width_test.sh.
PAD=$(jq -r '.statusLine.padding // 0' "$HOME/.claude/settings.json" 2>/dev/null || echo 0)
[ "${PAD:-0}" -ge 0 ] 2>/dev/null || PAD=0
OVERHEAD=$(( 2 * PAD + 1 ))

export STATUSLINE_CACHE_DIR="$(mktemp -d)"
CACHE="$STATUSLINE_CACHE_DIR/statusline-usage-cache.json"
REPO="$(mktemp -d)"
SHIM="$(mktemp -d)"
cleanup() { rm -rf "$STATUSLINE_CACHE_DIR" "$REPO" "$SHIM"; }
trap cleanup EXIT

git -C "$REPO" init -q 2>/dev/null
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init 2>/dev/null

# Seed the usage cache. Without a fixture the first render treats the rate
# limits as live and curls /api/oauth/usage with the real OAuth token, which
# makes the test non-hermetic and sensitive to account state.
#
# $1 = seven_day utilization, $2 = seven_day resets_at (a JSON value, so `null`
# is expressible), $3 = the limits array, $4 = the extra_usage block.
EXTRA_OFF='{"is_enabled":false}'
EXTRA_ON='{"is_enabled":true,"monthly_limit":200000,"used_credits":123456,"utilization":62.0}'
fixture() {
    cat > "$CACHE" <<JSON
{"five_hour":{"utilization":5.0,"resets_at":"2026-08-27T15:40:00+00:00"},
 "seven_day":{"utilization":$1,"resets_at":$2},
 "extra_usage":${4:-$EXTRA_OFF},
 "limits":$3}
JSON
}

# A weekly_scoped (per-model) limit: $1 = percent, $2 = resets_at JSON value.
scoped() {
    printf '[{"kind":"weekly_scoped","group":"weekly","percent":%s,"resets_at":%s,
              "scope":{"model":{"display_name":"Fable"}},"is_active":true}]' "$1" "$2"
}

at() { date -j -f '%Y-%m-%dT%H:%M:%S' "$1" +%s 2>/dev/null || date -d "$1" +%s; }

MON=$(at 2026-08-24T09:00:00)   # Monday
WED=$(at 2026-08-26T09:00:00)   # Wednesday
SAT=$(at 2026-08-29T09:00:00)   # Saturday
R_MON_ISO='"2026-08-31T02:00:00+00:00"'   # the following Monday, 2am: a fresh week at MON
R_WED_ISO='"2026-09-02T02:00:00+00:00"'   # the Wednesday after that

# $1 = SL_NOW, $2 = SL_WORK_DAYS, $3 = usable width (default 200). ANSI stripped.
render() {
    printf '%s' "{\"model\":{\"display_name\":\"Opus 5\"},\"cwd\":\"$REPO\",
        \"cost\":{\"total_cost_usd\":0.5},\"context_window\":{\"context_window_size\":200000,
        \"current_usage\":{\"input_tokens\":1000}}}" \
    | SL_NOW="$1" SL_WORK_DAYS="$2" TERM_WIDTH="$(( ${3:-200} + OVERHEAD ))" \
      PATH="$SHIM:$PATH" bash "$SCRIPT" 2>&1 | sed $'s/\033\[[0-9;]*m//g'
}

pass=0; fail=0
ok()  { echo "  PASS  $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1"; [ -n "$2" ] && printf '%s\n' "$2" | sed 's/^/          /'; fail=$((fail+1)); }

# $1 = rendered output, $2 = wanted substring, $3 = label
has()   { case "$1" in *"$2"*) ok "$3";; *) bad "$3" "want '$2' in: $1";; esac; }
lacks() { case "$1" in *"$2"*) bad "$3" "unwanted '$2' in: $1";; *) ok "$3";; esac; }

# A curl that fails loudly, first on PATH for every render above. Nothing here
# should reach the network: the fixture cache is fresh, so an invocation means
# the test would otherwise be spending the user's real OAuth token.
cat > "$SHIM/curl" <<EOF
#!/bin/sh
echo "curl invoked" >&2
: > "$SHIM/curl-was-called"
exit 1
EOF
chmod +x "$SHIM/curl"

echo "Pace against the per-model limit (SL_WORK_DAYS=12345, Mon-Fri):"
# Fresh week on a Monday: the workdays left are Mon-Fri, so the whole 100
# points spread over 5 days rather than the 7-day figure of 14.
fixture 7.0 "$R_MON_ISO" "$(scoped 0 null)"
o=$(render "$MON" 12345)
has "$o" "20%/d" "fresh week on a Monday over a 5-day week paces at 20%/d, not 14"
has "$o" "Fable ░░░░░░ 0% 20%/d" "pace sits inside the per-model segment, after its percentage"

# Mid-week, overspent. Wed 09:00 with the reset the following Mon 02:00:
# workdays left = Wed, Thu, Fri = 3, so pace = (100-50)/3 = 16.7 -> "17%/d".
# Elapsed workdays = Mon, Tue = 2 of the window's 5, so expected = 40% and the
# trend is 50 - 40 = +10.
fixture 7.0 "$R_MON_ISO" "$(scoped 50 null)"
o=$(render "$WED" 12345)
has "$o" "17%/d" "mid-window Wednesday at 50% used paces at (100-50)/3 = 17%/d"

# Saturday is not a workday, so today does not count itself. Reset on the
# Wednesday: workdays left = Mon, Tue = 2.
fixture 7.0 "$R_WED_ISO" "$(scoped 40 null)"
o=$(render "$SAT" 12345)
has "$o" "30%/d" "a Saturday does not count itself: pace spreads over Mon+Tue only"

echo
echo "Trend against today's band, not against a point:"
# During workday n of m, anything between (n-1)/m and n/m of the budget is on
# track -- the whole of today's allowance is today's to spend. Comparing
# against a single point built from COMPLETE workdays only turned every Monday
# morning red as soon as 3 points had gone, which is what this replaces.
# $1 = used%, $2 = SL_NOW, $3 = reset iso, $4 = wanted token, $5 = label
trend_is() {
    fixture 7.0 "$3" "$(scoped "$1" null)"
    has "$(render "$2" 12345)" "$4" "$5"
}
# Monday of a fresh window is workday 1 of 5: the band is 0-20.
trend_is 6  "$MON" "$R_MON_ISO" "%/d ✓"   "workday 1 of 5, 6% used: inside the day's own band"
trend_is 0  "$MON" "$R_MON_ISO" "%/d ✓"   "workday 1 of 5, nothing used yet: on track"
trend_is 20 "$MON" "$R_MON_ISO" "%/d ✓"   "workday 1 of 5, the whole day's allowance spent: still on track"
trend_is 30 "$MON" "$R_MON_ISO" "▲+10"    "workday 1 of 5, 30% used: 10 points past the band top of 20"
# Wednesday with the reset the following Monday is workday 3 of 5: band 40-60.
trend_is 45 "$WED" "$R_MON_ISO" "%/d ✓"   "workday 3 of 5, 45% used: inside the 40-60 band"
trend_is 70 "$WED" "$R_MON_ISO" "▲+10"    "workday 3 of 5, 70% used: 10 points past the band top"
trend_is 30 "$WED" "$R_MON_ISO" "▼-10"    "workday 3 of 5, 30% used: 10 points short of the band floor"
# The +-3 slack sits OUTSIDE the band, so the first flagged point is 4 past it.
trend_is 63 "$WED" "$R_MON_ISO" "%/d ✓"   "3 points past the band top is still within the slack"
trend_is 64 "$WED" "$R_MON_ISO" "▲+4"     "4 points past the band top breaks the slack"
trend_is 37 "$WED" "$R_MON_ISO" "%/d ✓"   "3 points below the band floor is still within the slack"
trend_is 36 "$WED" "$R_MON_ISO" "▼-4"     "4 points below the band floor breaks the slack"
# On a non-workday no day's allowance is in play, so the band collapses to the
# point where the elapsed workdays leave it. Saturday with the reset on the
# Wednesday: Wed, Thu, Fri elapsed of 5, so the point is 60.
trend_is 40 "$SAT" "$R_WED_ISO" "▼-20"    "a non-workday collapses the band to a point and still trends"
trend_is 58 "$SAT" "$R_WED_ISO" "%/d ✓"   "a non-workday within the slack of that point is on track"

echo
echo "Degenerate windows:"
# Saturday with the reset on Monday 02:00 leaves NO workdays at all. The
# workdays-left clamp makes pace the whole remaining budget, which is the
# honest answer (nothing constrains you) rather than a division by zero.
fixture 7.0 "$R_MON_ISO" "$(scoped 7 null)"
o=$(render "$SAT" 12345)
has "$o" "93%/d" "no workdays left: pace is everything that remains"
p=$(printf '%s' "$o" | sed -n 's/.* \([0-9.]*\)%\/d.*/\1/p')
case "$p" in
    ''|*[!0-9.]*) bad "the pace on a workday-less window is a plain number" "got '$p'" ;;
    *) awk -v p="$p" 'BEGIN{exit !(p >= 0 && p <= 100)}' \
           && ok "the pace on a workday-less window stays within 0-100" \
           || bad "the pace on a workday-less window stays within 0-100" "got '$p'" ;;
esac

# A 7-day working week is the old behaviour: 100/7 = 14.3, which the shared
# pv formatting (one decimal only below 10) renders as an integer.
fixture 7.0 "$R_MON_ISO" "$(scoped 0 null)"
o=$(render "$MON" 1234567)
has "$o" "14%/d" "SL_WORK_DAYS=1234567 reproduces the plain 100/7 figure"

# Nonsense SL_WORK_DAYS leaves no workdays in the window at all, so there is
# no baseline to pace against and nothing to render.
o=$(render "$MON" "xyz")
lacks "$o" "%/d" "an SL_WORK_DAYS with no weekdays in it renders no pace"

echo
echo "Which limit pace is computed against:"
# The per-model limit is the one that bites, so its own resets_at wins over the
# seven_day one even when the two disagree.
fixture 7.0 "\"not-a-date\"" "$(scoped 0 "$R_MON_ISO")"
o=$(render "$MON" 12345)
has "$o" "20%/d" "the scoped limit's own resets_at is used when it has one"

# No per-model limit: fall back to the 7-day figure, and put pace where the
# per-model segment would have been. 20% used over 5 workdays -> 80/5 = 16.
fixture 20.0 "$R_MON_ISO" "[]"
o=$(render "$MON" 12345)
has "$o" "16%/d" "with no per-model limit pace falls back to the 7-day figure"
lacks "$o" "Fable" "the fallback really has no per-model segment"

echo
echo "Missing and unusable reset times:"
# Every one of these must render the rest of the status line untouched: no
# pace, no trend, and no separator left dangling where they would have been.
no_pace() { # $1 = output, $2 = label
    lacks "$1" "%/d" "$2: no pace"
    lacks "$1" "│ │" "$2: no doubled separator"
    case "$1" in
        *'│') bad "$2: no trailing separator" "$1" ;;
        *)    ok  "$2: no trailing separator" ;;
    esac
}
fixture 7.0 null "$(scoped 0 null)"
no_pace "$(render "$MON" 12345)" "an absent reset time"
fixture 7.0 "\"not-a-date\"" "$(scoped 0 "\"also-not-a-date\"")"
no_pace "$(render "$MON" 12345)" "an unparseable reset time"
fixture 7.0 "$R_MON_ISO" "$(scoped 0 null)"
no_pace "$(render "$(at 2026-09-10T09:00:00)" 12345)" "a reset time already in the past"

echo
echo "Width ladder (pace must never be the reason a line overflows):"
fixture 7.0 "$R_MON_ISO" "$(scoped 0 null)"
widths() { python3 -c "
import sys,re,unicodedata
for ln in sys.stdin.read().rstrip('\n').split('\n'):
    p=re.sub(r'\033\[[0-9;]*m','',ln)
    print(sum(2 if unicodedata.east_asian_width(c) in 'WF' else 1 for c in p))"; }
over=0; toomany=0; orphan=0; dropped=0; shown=0; missing_wide=0
for u in 200 180 160 155 150 145 140 135 130 125 120 116 110 105 100 95 90 85 80 75 70 68 60 55 50 45 40; do
    o=$(render "$MON" 12345 "$u")
    ws=$(printf '%s' "$o" | widths)
    while read -r c; do [ "$c" -gt "$u" ] && over=1; done <<< "$ws"
    [ "$(printf '%s\n' "$ws" | wc -l | tr -d ' ')" -gt 2 ] && toomany=1
    # pace is given up BEFORE the per-model bar it annotates, so it can never
    # be the last thing standing.
    case "$o" in
        *"%/d"*) shown=1; case "$o" in *Fable*) ;; *) orphan=1 ;; esac ;;
        *)       case "$o" in *Fable*) dropped=1 ;; esac
                 [ "$u" -ge 68 ] && missing_wide=1 ;;
    esac
done
[ "$over"    = 0 ] && ok "no line exceeds the usable width at any width" || bad "no line exceeds the usable width at any width"
[ "$toomany" = 0 ] && ok "never more than two lines"                     || bad "never more than two lines"
[ "$orphan"  = 0 ] && ok "pace never outlives the per-model bar"         || bad "pace never outlives the per-model bar"
[ "$shown"   = 1 ] && ok "pace is actually rendered somewhere in the sweep" || bad "pace is actually rendered somewhere in the sweep"
# Line two is the group's own, so pace survives every width that fits a normal
# status line -- it is only given up on a genuinely tiny terminal.
[ "$missing_wide" = 0 ] && ok "pace is kept at every width from 68 columns up" \
                        || bad "pace is kept at every width from 68 columns up"
[ "$dropped" = 1 ] && ok "the pace rung is reachable: some width keeps the bar but drops pace" \
                   || bad "the pace rung is reachable: some width keeps the bar but drops pace"

# Pace outranks the extra-usage credits: the credits are ~30 columns of dollar
# readout, pace is the number this segment exists for, so the credits go first.
fixture 7.0 "$R_MON_ISO" "$(scoped 0 null)" "$EXTRA_ON"
pace_alone=0; credits_alone=0
for u in 200 180 160 155 150 145 140 135 130 125 120 116 110 105 100 95 90 85 80 75 70 68 60 55 50 45 40; do
    o=$(render "$MON" 12345 "$u")
    case "$o" in
        *"%/d"*) case "$o" in *extra*) ;; *) pace_alone=1 ;; esac ;;
        *)       case "$o" in *extra*) credits_alone=1 ;; esac ;;
    esac
done
[ "$credits_alone" = 0 ] && ok "the extra-usage credits never outlive pace" \
                         || bad "the extra-usage credits never outlive pace"
[ "$pace_alone"    = 1 ] && ok "some width keeps pace but drops the credits" \
                         || bad "some width keeps pace but drops the credits"

echo
echo "Hermeticity:"
[ -f "$SHIM/curl-was-called" ] \
    && bad "curl is never invoked (the fixture cache is fresh)" \
    || ok  "curl is never invoked (the fixture cache is fresh)"

echo
echo "  $pass passed, $fail failed"
[ "$fail" -eq 0 ]
