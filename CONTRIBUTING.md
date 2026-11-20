# Contributing

Keep changes small and preserve the original clock behavior.

Run `bash tools/check.sh` on Omarchy before sending a change. The tests are offline and do not change your bar.

The local check must pass without QML warnings. It uses the real Omarchy modules, not type stubs. Our popups and content have explicit types; only Omarchy's anonymous style objects and scoped bar facade remain dynamic.

After changing popup loading, check that `omarchy-shell thabetfy.multi-calendar open` opens it and that `status` reports `"opened": true`. Close it when done.

Keep Arabic and English translation keys and placeholders in sync. Render dynamic text as plain text. Do not add network requests, downloaded code or new dependencies without explaining why they are needed.

For a new calendar type, follow [the provider guide](docs/configuration.md#implementing-a-new-calendar-type).

When reporting a bug, include your Omarchy version, the selected calendars and the format that caused it. Do not post your full `shell.json` or private desktop screenshots.

Keep the Omarchy and `hijridate` credits and licenses.
