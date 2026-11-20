#!/bin/bash

set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

bash -n tools/check.sh tests/calendar-test.sh tests/helpers.sh
bash tests/calendar-test.sh
node --test tests/*.test.cjs
omarchy plugin validate .

# Use Qt 6, not the incompatible Qt 5 command on PATH.
qml_lint=""
for candidate in /usr/lib/qt6/bin/qmllint /usr/lib/qt6/qmllint; do
  if [[ -x $candidate ]]; then
    qml_lint=$candidate
    break
  fi
done
if [[ -z $qml_lint ]]; then
  printf 'Qt 6 qmllint is required for the local release check.\n' >&2
  exit 1
fi

# Quickshell maps qs.* to its shell directory at runtime. Give qmllint the
# same module layout, using the real Omarchy files rather than stub types.
imports=$(mktemp -d)
trap 'rm -- "$imports/qs"; rmdir -- "$imports"' EXIT
ln -s "$OMARCHY_PATH/shell" "$imports/qs"

QT_FORCE_STDERR_LOGGING=1 "$qml_lint" --ignore-settings --max-warnings 0 -I "$imports" \
  BarWidget.qml Panel.qml CalendarContext.qml CalendarFormatter.qml \
  PluginTranslations.qml WallClock.qml YearProgress.qml
