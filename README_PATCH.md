# Cover Stock — Compatibility UI Patch

This patch separates the **Compatibility Check** screen from **Stock**.

## Changes

- Search tab becomes a read-only compatibility checker.
- Stock tab remains the only place to add, remove, and inspect stock.
- COVER, GLASS and LENS are displayed as independent categories.
- Compatibility suggestions no longer disappear just because the other model has zero stock.
- Bundled compatibility data is merged into SQLite automatically on app startup.
- Existing stock values and existing compatibility decisions are not overwritten.
- Tablets continue to show COVER and GLASS only.
- Replaces Flutter's generated `MyApp` placeholder test with a real project smoke test, avoiding the previous CI test error.

## Initial Vivo V20 reference

The first bundled candidate is the MobiMatch Pro K34 tempered-glass group: OPPO Reno3, Vivo S1 Pro, Vivo V20, Vivo V20 SE and Vivo V23e.

This is **conditional**, not a physically verified fit. The public source does not expose the exact supplier SKU or cutout dimensions for K34. The app therefore labels it as a candidate and tells the user to check the glass outline and cutouts.

No COVER or camera LENS cross-model match is included for V20 because a trustworthy public source was not found. The screen will say that data is unavailable rather than invent matches.

Source: https://www.mobimatchpro.com/

## Apply in Termux

Extract this ZIP into your existing Cover Stock project root. Then run:

```bash
python3 patch_cover_stock.py .
git diff --check
```

Termux does not need a local Flutter SDK. GitHub Actions runs `flutter test`, `flutter analyze`, and builds the APK after you push.

Then commit and push:

```bash
git add .
git commit -m "Separate compatibility and stock screens"
git push
```

GitHub Actions will build a new APK. Install the APK from the successful workflow artifact.

The patch script creates a timestamped backup folder before changing existing files. It uses only Python's standard library.

## Important scope

This patch does not create a complete worldwide accessory-fitment database. Some commercial catalogues restrict bulk copying, and device specifications alone do not establish exact accessory fit. More groups should only be added when an identifiable source supports the exact category and candidate relationship. GLASS evidence must not be reused for COVER or LENS.
