#!/bin/bash
# Run every test for claude/statusline.isaacaudet.sh.
#
# Usage: claude/tests/run.sh
#
# The tests render the status line directly, so they need the same tools it
# does (bash, jq, git, python3). They briefly replace the cached usage-API
# response in /tmp/claude with fixtures and restore it on exit.
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

status=0
for t in statusline.isaacaudet.payload_test.sh \
         statusline.isaacaudet.width_test.sh; do
    echo "== $t"
    bash "$t" || status=1
    echo
done

echo "== statusline.isaacaudet.overflow_test.py"
python3 statusline.isaacaudet.overflow_test.py || status=1

echo
[ "$status" -eq 0 ] && echo "ALL TESTS PASSED" || echo "SOME TESTS FAILED"
exit "$status"
