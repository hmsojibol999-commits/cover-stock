# Cover Stock — Engineering Handoff

## Product intent

Single-owner Android inventory app for mobile accessories. It works offline after installation. The model-name catalogue is bundled at APK build time; Cover/Glass/Lens compatibility is separate and must never be guessed from device specifications alone.

## Implemented application structure

- Flutter Material 3, Riverpod state management, SQLite (`sqflite`).
- Four tabs: Search, Stock, Order List and Settings; Search opens first and requests keyboard focus.
- Search normalization removes spaces and punctuation and ignores case. Model/brand search is in-memory over the local catalogue.
- Stock and search use `DeviceModel.availableTypes`: phones expose COVER/GLASS/LENS; tablets expose COVER/GLASS.
- Stock page uses `ListView.builder` and a brand filter; it avoids eagerly constructing thousands of rows inside expandable brand tiles.
- Stock edits save through SQLite transactions; stock count is clamped at zero; Search and Stock sales have Undo snackbars.
- Compatibility group data is typed by item type and stores evidence URLs/note. Pair-level SURE override and permanent WRONG table are separate.
- NINETY alternatives warn the owner. SURE alternatives are sorted first. An alternative sale decrements that alternative model's stock.
- Order list sums shared-group stock and does not create an individual duplicate order row for grouped members.
- Model create/edit/delete; brand and model duplicate checks; explicit delete confirmation. Tablet conversion removes Lens compatibility memberships but deliberately keeps any old Lens stock row hidden, to avoid erasing inventory if the owner changes the device kind by mistake.
- Threshold, dark mode, JSON backup/restore (schema v1/v2), CSV import, AI Data Pack import.
- Android launcher icon source images and in-app launch screen.

## Model catalogue pipeline

`assets/model_catalog.json` in the source ZIP is a small fallback. CI overwrites it before Flutter build:

1. `scripts/test_build_catalog.py` tests parsing and brand mapping.
2. `scripts/build_catalog.py --ref develop` calls the public GetTechAPI/TechAPI GitHub Contents + Git Trees endpoints for the requested phone/tablet brand folders.
3. It collects model folder/file slugs across all year directories, humanizes names, separates Redmi/Xiaomi/Poco and iPhone/iPad/Pixel, removes duplicate normalized names within a brand+device kind, and keeps the latest release year seen.
4. It writes `assets/model_catalog.json` with source repository, ref, counts, version hash, CC BY-SA 4.0 attribution and a warning that the source is not exhaustive and contains no accessory compatibility map.
5. `AppDatabase._mergeBundledCatalog()` compares the catalogue version in SQLite and batch-inserts new models and zero stock rows. It does not delete old names or overwrite existing stock counts/groups/wrong-pair exclusions.

Included phone brand folders: Honor, Vivo, Oppo, Xiaomi (Redmi split out by slug), Poco, Samsung, Apple (iPhone subset), Google (Pixel subset), Nothing, Infinix, Tecno, OnePlus and Motorola. iQOO is excluded from the Vivo folder. Tablet folders are included where upstream data exists: Honor, Vivo, Oppo, Xiaomi, Samsung, Apple (iPad), Google (Pixel), Infinix, Tecno, OnePlus and Motorola. There is no Poco or Nothing tablet folder in this source snapshot.

**Important source limit:** upstream TechAPI says its catalogue is growing and not exhaustive. Its headline counts are record counts, not unique models. We must not promise that every phone ever released is represented. The source has specs/identity but not cross-compatible accessory SKUs.

## Compatibility policy and Data Pack contract

TechAPI doesn't supply verified cross-fit compatibility for covers, screen protectors or camera protectors. Seed groups are intentionally empty. Do not generate mappings by screen diagonal or model-family similarity alone.

`AppRepository.importCatalogUpdate()` accepts:

```json
{
  "schemaVersion": 1,
  "models": [
    {"brand":"Honor","name":"X9c","deviceKind":"PHONE","releaseYear":2025}
  ],
  "compatibilityGroups": [
    {
      "itemType":"GLASS",
      "label":"Exact supplier part/SKU",
      "confidence":"NINETY",
      "evidenceUrls":["https://supplier.example/sku"],
      "evidenceNote":"Explain the source and uncertainty.",
      "members":[
        {"brand":"Honor","model":"X9c"},
        {"brand":"Honor","model":"Magic 7 Lite"}
      ]
    }
  ]
}
```

Validation performed by the app:

- Validates schema/model/device kind/item type/confidence and member references.
- Validates HTTP(S) URLs.
- NINETY requires at least one distinct source URL. SURE requires at least two distinct source domains.
- Requires a non-empty evidence note of at least 12 characters.
- Requires at least two distinct models per group; Tablet may not be a member of a LENS group.
- Rejects a model already assigned to another group for the same item type.
- Re-importing an existing group with the same item type + label is skipped, not overwritten.
- Pairwise WRONG decisions are persistent and block Data Pack reintroduction.
- The entire Data Pack import is transactional and does not change stock counts.

These checks are structural only. The app cannot fetch or judge source pages, and two domains do not automatically mean two reliable sources. AI instructions live in `docs/AI_CATALOG_UPDATE_PROMPT.md`; owner must inspect evidence and physically test uncertain parts.

## SQLite schema

- `brands`
- `models` (`device_kind`, `release_year` added in schema v2)
- `stocks`
- `compatibility_groups` (`evidence_urls`, `evidence_note` added in schema v2)
- `compatibility_members`
- `compatibility_pair_overrides`
- `compatibility_wrong`
- `settings`

Database migration v1 → v2 adds columns with safe defaults. Model catalog is merged separately from migration. Existing user stock data is not part of the model catalogue merge.

## CI / APK build

`.github/workflows/build.yml` runs on every push and manual dispatch. It:

1. Runs Python stdlib tests for the catalogue parser.
2. Fetches the selected device model names from the public TechAPI GitHub API (`develop` ref). No token or secret is required.
3. Sets Java 17 and Flutter stable 3.50.1.
4. Generates Android project scaffolding with `flutter create --platforms=android`.
5. Runs `flutter pub get`, launcher icon generation, `flutter analyze`, `flutter test`, `flutter build apk --release`.
6. Uploads `app-release.apk` in the `cover-stock-release-apk` artifact and the generated `pubspec.lock` in `cover-stock-pubspec-lock`; both are retained for 30 days.

The app does not need Internet at runtime. Internet is used by the GitHub build job to fetch the catalogue from public GitHub API endpoints. No personal token/API key is required or stored in the repository.

## Test status in source-building environment

Verified locally in the container:

- `python3 -m py_compile scripts/build_catalog.py scripts/test_build_catalog.py` passes.
- `python3 -m unittest discover -s scripts -p 'test_*.py' -v` passes (6 tests).
- JSON/YAML/CSV and ZIP integrity should be checked again before delivery.

Not verified here:

- Flutter SDK/Dart SDK/Android SDK are not installed in the container. I could not run `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`, `flutter build apk`, or install on a real Android phone.
- The live catalogue fetch in GitHub Actions has not been run from this environment. First workflow run is the actual integration check and must be inspected.
- Android file picker, share sheet, SQLite startup import time and 20k-row interactions need owner-device testing.

Do not claim this source ZIP contains a locally compiled APK. The build artifact appears only after a successful GitHub Actions run.

## Owner acceptance checklist

- [ ] First install completes the bundled model import and then opens Search.
- [ ] Search `v20`, `V 20` and `Vivo V20`; same model is found.
- [ ] Search an old and new model from each supported brand; search works with Wi-Fi and mobile data off.
- [ ] Search model names from the tablet catalogue; result is labelled ট্যাব.
- [ ] Tablet selected screen shows only Cover and Glass, never Lens.
- [ ] Select a brand in Stock; virtualized list remains responsive when scrolling through a large brand.
- [ ] Add stock for Cover/Glass/Lens (phone) and Cover/Glass (tablet).
- [ ] Sell once; stock decreases by one; Undo restores it.
- [ ] Selling at zero never creates a negative count.
- [ ] Create a physically tested GLASS group; only models with the same exact part go inside it.
- [ ] NINETY alternative displays the check-before-giving warning.
- [ ] Fit হলো changes the selected pair to SURE.
- [ ] WRONG permanently hides the pair in both search directions.
- [ ] Import an AI Data Pack with valid evidence; new models/groups appear and existing stock stays unchanged.
- [ ] Try importing a SURE group with one domain; importer rejects it.
- [ ] Try importing a pair already marked WRONG; importer rejects it.
- [ ] Re-import the same pack; it does not duplicate models/groups.
- [ ] Order List totals stock across a compatibility group and does not list grouped items twice.
- [ ] Check All / Low / Out filters and low-stock threshold.
- [ ] Add/edit/delete a model and brand; confirm delete first.
- [ ] Export JSON backup, restore it, and compare stock/groups/wrong pairs.
- [ ] Import CSV with phone and tablet rows.
- [ ] Force close/reopen; data persists.
- [ ] Turn dark mode on/off.
- [ ] Make sure no Internet connection and verify search/stock/compatibility/backup still work.

## Remaining known limits

- Upstream model catalogue is broad but not exhaustive. A model omitted by the upstream snapshot can be added manually or with an AI Data Pack.
- No accessory compatibility map is bundled because no source in this project reliably proves general cross-model Cover/Glass/Lens equivalence. Compatibility is evidence-based and owner-reviewed.
- The model-name normalizer removes punctuation/spaces and may collapse alternate spellings; duplicate check is per brand and device-kind data must match.
- CSV is owner-managed and does not carry pair WRONG overrides or full backup state; use JSON backup for complete transfer.
- Release signing is not configured. The APK artifact is for direct sideload installation, not Play Store publishing.
- The workflow uploads the resolved `pubspec.lock` separately; the owner can add it to the repository after the first successful build for reproducible transitive package versions.
