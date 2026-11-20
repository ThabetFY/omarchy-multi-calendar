# Release verification

Checked on 20 November 2026, using Omarchy 4.5.0-3.

## Live checks

| Check | Result |
| --- | --- |
| Weekday, time and both calendars | Pass |
| Gregorian only, English | Pass |
| Hijri only, Arabic | Pass |
| Arabic Hijri with English Gregorian | Pass |
| Time above both dates | Pass; both lines fit |
| Time and two dates in a sidebar | Pass |
| Switching between one and two calendars | Pass |
| Third calendar | Rejected; the two accepted calendars remain |
| Restore the user's original settings | Pass; the complete settings match the backup |

Fresh images were inspected for clipping, overlap and missing text. Only widget crops are included, not personal windows or full desktop screenshots.

The main preview follows Prayer Times' bilingual showcase style, using these actual widget crops. The original dual-calendar preview is preserved in the screenshot gallery.

The live checks found and fixed a stale-selection binding during calendar changes and a clipped second line in stacked Arabic text. Both were rechecked after reloading the shell. The final run also verified that the popup actually opens in every layout, and had no calendar `TypeError` or `ReferenceError` messages.

## Automated checks

`bash tools/check.sh` passed: calendar tests, Qt formatting comparisons, manifest validation, translation checks and plain-text guards.

QML lint now passes with zero warnings and errors. The check loads the real Omarchy modules and uses `--ignore-settings --max-warnings 0`; no warning categories are disabled. A test file containing a known warning was correctly rejected.

Existing shell/custom-bar messages can still appear when the entire bar moves between screen edges. Those are separate from this package's QML lint results.

The installed preview and release package use the same runtime code.
