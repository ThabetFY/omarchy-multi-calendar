# Releasing

1. Update `manifest.json` and `CHANGELOG.md` with the version and release date.
2. Run `bash tools/check.sh` on Omarchy. QML lint must have zero warnings and errors.
3. Check single, dual, mixed-language, stacked and sidebar layouts. Verify that the popup opens, live selection changes work and a third calendar is rejected.
4. Restore the original bar, settings and workspace. Update [verification results](verification.md).
5. Review the README, screenshots, licenses and credits.
6. Commit and push, tag `v<version>`, and publish the GitHub release.

Do not include personal settings, full desktop captures, logs or symlinks. Crop screenshots to the widget.
