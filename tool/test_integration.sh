#!/usr/bin/env bash
# Runs each integration_test file in its own `flutter test` invocation.
#
# Why per-file: flutter_tools on Linux desktop closes the log reader after
# the first app process exits, so `flutter test integration_test/` fails to
# launch files 2+ (upstream flutter/flutter#101031 — tool bug, not a test
# failure). Per-file invocations are the supported workaround.
#
# Usage: tool/test_integration.sh
set -euo pipefail

status=0
for f in integration_test/*_test.dart; do
  echo "== $f"
  if ! flutter test "$f"; then
    status=1
  fi
done
exit "$status"
