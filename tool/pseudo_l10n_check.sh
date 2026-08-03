#!/usr/bin/env bash
# FL10N-T6 — pseudo-l10n gate.
#
# Fails when a user-facing string literal appears in presentation code
# instead of an AppLocalizations lookup. Scope is deliberate: domain and
# data layers keep English technical/debug messages by design (see HANDOFF
# 2026-08-02, F-L10N decisions) — only widgets and routing are scanned.
#
# Usage: tool/pseudo_l10n_check.sh [scan-root …]   (default: lib)
# Exit:  0 = clean, 1 = hardcoded strings found

set -euo pipefail

roots=("$@")
if [ ${#roots[@]} -eq 0 ]; then
  roots=(lib)
fi

# User-facing sinks whose string argument must come from l10n.
pattern="(Text\\(\\s*'[^']*[A-Za-z]|(title|label|message|tooltip|hintText|helperText|semanticLabel):\\s*'[^']*[A-Za-z])"

findings=$(
  rg --no-heading --line-number --pcre2 "$pattern" "${roots[@]}" \
    --glob '**/presentation/**' \
    --glob '**/core/widgets/**' \
    --glob '**/core/router/**' \
    --glob '**/app.dart' \
    --glob '!**/*.g.dart' \
    --glob '!**/*.freezed.dart' \
    || true
)

if [ -z "$findings" ]; then
  echo "pseudo-l10n-check: PASS — no hardcoded UI strings in presentation code"
  exit 0
fi

echo "pseudo-l10n-check: FAIL — hardcoded user-facing strings found:"
echo "$findings"
echo
echo "Move these strings into lib/l10n/app_en.arb + app_es.arb and use"
echo "AppLocalizations.of(context) instead."
exit 1
