#!/usr/bin/env python3
"""Exhaustive overflow sweep for claude/statusline.isaacaudet.sh.

Covers the Isaac Audet-inspired status line (the variant symlinked from
~/.claude/statusline.sh); the sibling statusline.burnrate.sh and
statusline.original.sh are not covered.

Asserts the two hard invariants across a grid of terminal widths, branch-name
lengths and model-name lengths:
  1. no rendered line exceeds the usable width
  2. never more than two lines

Catches the case tier-based sizing missed: content whose width depends on
session state (branch, cwd, model display name) rather than on the terminal.
"""
import subprocess, re, unicodedata, sys, os, itertools, tempfile, shutil

SCRIPT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                      "statusline.isaacaudet.sh")
BRANCHES = ["main", "feature/some-longer-branch-name",
            "feature/an-extremely-long-branch-name-that-keeps-going-and-going"]
MODELS = ["Opus 5", "Opus 5 (1M context)"]
# Starts at the narrowest terminal line ONE fits on with the longest branch
# below (measured: 44 usable columns, i.e. 49 with padding 2) -- the pre-existing
# narrow-tier floor, which width_test.sh marks XFAIL. Everything above it is
# fair game, and that now includes the band from RL_MIN_WIDTH up, where the
# usage group is shown but has few columns to spare.
WIDTHS = range(49, 245, 10)
# The cwd basename is rendered at the widest layouts and is capped by
# CWD_MAX_LEN; vary it, since a long project directory was one of the ways
# line one used to overflow.
CWDS = ["proj", "a-really-quite-long-project-directory-name-that-someone-might-have"]
# Extra-usage credits add ~30 columns and used to overflow line two on their own.
EXTRA = {
    "off": '"extra_usage":{"is_enabled":false}',
    "on":  '"extra_usage":{"is_enabled":true,"monthly_limit":200000,'
           '"used_credits":123456,"utilization":62.0}',
}
# Throwaway cache directory, inherited by every rendered subprocess: the live
# cache belongs to the running status line (~/.claude/statusline.sh symlinks to
# the script under test) and a fixture written there would be shown as real
# usage until it expired.
CACHE_DIR = tempfile.mkdtemp()
os.environ["STATUSLINE_CACHE_DIR"] = CACHE_DIR
CACHE = os.path.join(CACHE_DIR, "statusline-usage-cache.json")
FIXTURE = ('{"five_hour":{"utilization":5.0,"resets_at":"2026-08-27T15:40:00+00:00"},'
           '"seven_day":{"utilization":7.0,"resets_at":"2026-08-28T02:00:00+00:00"},%s,'
           '"limits":[{"kind":"weekly_scoped","percent":10,'
           '"scope":{"model":{"display_name":"Fable"}},"is_active":true}]}')

def width_of(s):
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1
               for c in re.sub(r"\033\[[0-9;]*m", "", s))

def main():
    pad = int(subprocess.run(
        ["jq", "-r", ".statusLine.padding // 0", os.path.expanduser("~/.claude/settings.json")],
        capture_output=True, text=True).stdout.strip() or 0)
    root = tempfile.mkdtemp()
    fails, checked = [], 0
    try:
      for cwd_name, extra_name in itertools.product(CWDS, EXTRA):
        with open(CACHE, "w") as fh:
            fh.write(FIXTURE % EXTRA[extra_name])
        repo = os.path.join(root, cwd_name)
        os.makedirs(repo, exist_ok=True)
        subprocess.run(["git", "-C", repo, "init", "-q"], check=True)
        subprocess.run(["git", "-C", repo, "-c", "user.email=t@t", "-c", "user.name=t",
                        "commit", "-q", "--allow-empty", "-m", "i"], check=True)
        for br in BRANCHES:
              subprocess.run(["git", "-C", repo, "checkout", "-q", "-B", br], capture_output=True)
              for f in os.listdir(CACHE_DIR):
                  if f.startswith("git-"):
                      os.remove(os.path.join(CACHE_DIR, f))
              for model, cols in itertools.product(MODELS, WIDTHS):
                  stdin = ('{"model":{"display_name":"%s"},"cwd":"%s",'
                           '"cost":{"total_cost_usd":8.31},"context_window":'
                           '{"context_window_size":1000000,"current_usage":'
                           '{"input_tokens":137000,"cache_read_input_tokens":34000}}}' % (model, repo))
                  out = subprocess.run(["bash", SCRIPT], input=stdin, capture_output=True,
                                       text=True, env=dict(os.environ, TERM_WIDTH=str(cols))).stdout
                  usable = max(20, cols - 2 * pad - 1)
                  lines = out.rstrip("\n").split("\n")
                  checked += 1
                  tag = (br, model, cols, cwd_name, extra_name)
                  if len(lines) > 2:
                      fails.append(tag + ("more than two lines",))
                      continue
                  if not any(l.strip() for l in lines):
                      fails.append(tag + ("rendered nothing",))
                      continue
                  mx = max(width_of(l) for l in lines)
                  if mx > usable:
                      fails.append(tag + (f"max {mx} > usable {usable}",))
    finally:
        shutil.rmtree(root, ignore_errors=True)
        shutil.rmtree(CACHE_DIR, ignore_errors=True)

    print(f"checked {checked} combinations "
          f"(widths {WIDTHS.start}-{WIDTHS.stop - 1}, {len(BRANCHES)} branches, "
          f"{len(MODELS)} models, {len(CWDS)} cwds, extra-usage on and off)")
    if fails:
        print(f"FAIL: {len(fails)} overflow(s)")
        for f in fails[:10]:
            print("   ", f)
        return 1
    print("PASS: no line exceeded the usable width")
    return 0

if __name__ == "__main__":
    sys.exit(main())
