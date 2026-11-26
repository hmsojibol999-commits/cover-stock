# Cover Stock

**Offline Android inventory app for a mobile accessories shop.** It tracks phone covers, tempered glass and camera lens protectors; it also tracks tablet covers and tablet glass. There are no prices, photos, customer accounts, cloud database or runtime network service.

## Important: device catalogue vs fit compatibility

These are two different datasets:

1. **Model-name catalogue:** GitHub Actions fetches the selected brands' available phone and tablet records from the public [TechAPI dataset](https://github.com/GetTechAPI/TechAPI) when the APK is built. The names are bundled into the APK and copied into local SQLite the first time the app opens. Search then works with Wi-Fi and mobile data turned off. The build script takes all year folders available for the requested brand folders, normalizes and deduplicates names, and retains a release year when it can read one.
2. **Accessory compatibility:** TechAPI supplies device identity/specification records; it does not supply trustworthy Cover/Glass/Lens cross-fit mappings. This project does **not** guess that two models share a part. No compatibility groups are seeded. Groups must come from a reliable exact part/SKU compatibility list or a physical fit check, and they must be imported or entered separately.

The upstream TechAPI README says its dataset is growing and **not yet exhaustive**. Its November 2026 README reports 92,856 smartphone records and 3,373 tablet records; those are source records, not unique accessory-compatible models. Therefore this app can search every selected model represented in the fetched source snapshot, but cannot honestly promise every device ever sold worldwide. Source: [TechAPI README](https://github.com/GetTechAPI/TechAPI#data).

### Brands included in the build-time catalogue

Phones: Honor, Vivo, Oppo, Redmi, Xiaomi, Poco, Samsung, iPhone, Google Pixel, Nothing, Infinix, Tecno, OnePlus and Motorola. The iQOO sub-brand is excluded from the Vivo folder rather than silently mixed into Vivo. The script also includes selected tablets where the source has a tablet catalogue: Honor, Vivo, Oppo, Xiaomi, Samsung, iPad, Google Pixel, Infinix, Tecno, OnePlus and Motorola. Poco and Nothing tablet folders are not currently included because the source has no tablet folder for them.

Other brands/models can still be added manually in Settings or with CSV / AI Data Pack import.

## Offline behaviour

- **At build time only:** GitHub Actions needs Internet access to fetch the model-name catalogue.
- **After installation:** model search, stock editing, compatibility, order list, backup and restore run from the app's local SQLite database. The app does not fetch data in the background and does not need Internet to start or operate.
- **Updating the built-in catalogue:** push the project to GitHub and download the new APK from Actions. On app start, it merges newly bundled model names into SQLite. It does not delete models or modify existing stock counts.
- **Adding one new model without rebuilding the APK:** ask an AI assistant to research it and create a Cover Stock JSON Data Pack using [`docs/AI_CATALOG_UPDATE_PROMPT.md`](docs/AI_CATALOG_UPDATE_PROMPT.md). Save that JSON on the phone and import it in **Settings → AI Data Pack যোগ করুন**. The app itself has no built-in AI or web browser.

## Features

- Material 3 interface with four tabs: Search, Stock, Order List and Settings. Search opens first and gets keyboard focus.
- SQLite database in Android app-private storage; edits are saved immediately.
- Riverpod state management.
- Search ignores case, spaces, dots, underscores and hyphens. For example, `v20`, `V 20` and `Vivo V20` match the same model.
- Phone stock: COVER, GLASS and LENS. Tablet stock: COVER and GLASS only.
- Large Sell button, small Add button, stock count never below zero, and Undo snackbar after a sale.
- Alternative suggestions are based only on compatibility groups already stored locally. SURE sorts first; NINETY displays a check-before-giving warning. Selling an alternative reduces stock for that alternative model.
- Fit হলো upgrades one pair to SURE. WRONG permanently excludes that pair for that item type; Data Pack imports cannot revive it.
- Order List totals available stock across each compatibility group before deciding whether that group needs ordering.
- Stock screen uses a virtualized list and brand filter, so opening a brand does not build thousands of widgets at once.
- Model create/edit/delete with duplicate checks and delete confirmation; device kind can be PHONE or TABLET.
- Low-stock threshold (default 2), dark mode, JSON backup/restore, CSV bulk import and AI Data Pack merge import.
- Android launcher icon and in-app splash screen.
- GitHub Actions builds a release APK on every push and uploads it as a 30-day artifact.

## Compatibility confidence and AI Data Pack

A compatibility group is separate for each item type. Never infer Cover fit from Glass fit or Lens fit.

- `SURE`: Data Pack import requires at least two distinct HTTP(S) source domains. Use it only when the sources explicitly confirm the exact same accessory part/SKU, or documentation is backed by a recorded physical test.
- `NINETY`: Data Pack import requires at least one source URL and an explanation of the remaining uncertainty. The app displays a warning to check before giving.
- Unknown: do not add a link. Leave it out until there is evidence.

The importer checks the JSON shape, URL format, source-domain count, member models, tablet/Lens restriction, group conflicts and previously-WRONG pairs. It cannot inspect whether a cited web page genuinely proves a fit. The owner must inspect the sources and physically check uncertain parts. The in-app notice remains: **Compatibility may be wrong. Always check before giving.**

See [`docs/AI_CATALOG_UPDATE_PROMPT.md`](docs/AI_CATALOG_UPDATE_PROMPT.md) for a ready-made research prompt and exact JSON schema.

## Source data and attribution

The bundled model-name catalogue is derived from [GetTechAPI/TechAPI](https://github.com/GetTechAPI/TechAPI), licensed under **Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)**. This app credits it as **“Data from TechAPI”** in Settings and retains the source note in the generated catalogue. If you redistribute the derived catalogue, keep the attribution and share-alike terms. See [the source data license](https://github.com/GetTechAPI/TechAPI/blob/develop/data/LICENSE.md).

## Project structure

```text
cover_stock_project/
├── .env.example
├── .github/workflows/build.yml
├── assets/
│   ├── seed_data.json
│   ├── model_catalog.json       # small fallback; CI replaces it with fetched catalogue
│   └── icon/
│       ├── cover_stock.png
│       └── cover_stock_foreground.png
├── docs/
│   ├── AI_CATALOG_UPDATE_PROMPT.md
│   └── import_template.csv
├── scripts/
│   ├── build_catalog.py
│   └── test_build_catalog.py
├── lib/
│   ├── app.dart
│   ├── main.dart
│   ├── data/
│   │   ├── app_database.dart
│   │   ├── app_repository.dart
│   │   └── models.dart
│   ├── providers/app_controller.dart
│   ├── screens/
│   │   ├── orders_screen.dart
│   │   ├── search_screen.dart
│   │   ├── settings_screen.dart
│   │   └── stock_screen.dart
│   └── widgets/
│       ├── common.dart
│       └── stock_count_card.dart
├── test/models_test.dart
├── analysis_options.yaml
└── pubspec.yaml
```

Flutter generates the Android Gradle wrapper and platform boilerplate in GitHub Actions using `flutter create --platforms=android ...`. The source ZIP does not include generated Android build files.

## Build the APK through GitHub (recommended for phone-only use)

You need a GitHub account, the ZIP file and Termux. You do not need Flutter or Android Studio on your phone.

### 1. Create a repository

1. Open [github.com](https://github.com) and sign in.
2. Tap **+ → New repository**.
3. Repository name: `cover-stock`.
4. Choose Public or Private.
5. Leave **Add a README** unchecked and create the repository.
6. Copy its HTTPS URL, for example `https://github.com/YOUR_USERNAME/cover-stock.git`.

### 2. Extract and upload from Termux

Download `cover_stock_project.zip` into Android Downloads. Run:

```bash
pkg update -y
pkg install git unzip -y
termux-setup-storage
cd ~/storage/downloads
unzip cover_stock_project.zip -d ~
cd ~/cover_stock_project

git init
git branch -M main
git add .
git commit -m "Initial Cover Stock app"
git remote add origin https://github.com/YOUR_USERNAME/cover-stock.git
git push -u origin main
```

Replace `YOUR_USERNAME` with your GitHub username. If GitHub asks for a password, use a Personal Access Token (PAT), not your normal account password. Because the repository contains a workflow, the token needs repository **Contents: Read and write** and **Workflows: Write** permissions (fine-grained token), or `repo` + `workflow` scopes (classic token). Enter it only at the password prompt; never save it in this project or share it.

### 3. Download the APK

1. Open your `cover-stock` repository on GitHub.
2. Open **Actions**.
3. Open the latest **Build Android Release APK** run.
4. Wait for the job to finish successfully.
5. Scroll to **Artifacts** and tap `cover-stock-release-apk`.
6. Extract the downloaded ZIP and install `app-release.apk` on Android.

The workflow first tests the catalogue parser, then fetches/builds the selected phone/tablet name catalogue, then creates the Android project, installs Flutter packages, runs `flutter analyze` and `flutter test`, builds the release APK and uploads it. It also uploads the generated `pubspec.lock` as a separate artifact so it can be committed to the repository for repeatable dependency resolution. It runs on every push. Artifacts are retained for 30 days. If the run fails, open the failed step's log and share it for diagnosis.

### 4. Upload later changes

From Termux, inside the project directory:

```bash
git add .
git commit -m "Describe the change"
git push
```

A new Actions run builds another APK and refreshes the bundled model catalogue from the source snapshot.

## Optional local build

On a computer with Flutter stable 3.50.1 / compatible Dart 3.14 and Android SDK installed:

```bash
python3 -m unittest discover -s scripts -p 'test_*.py' -v
python3 scripts/build_catalog.py --ref develop
flutter create --platforms=android --org com.coverstock --project-name cover_stock --no-pub .
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter test
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

## CSV import format

A starter sample is in `docs/import_template.csv`.

Required columns: `brand`, `model`.

Optional columns:

- `device_kind`: `PHONE` or `TABLET`; blank defaults to PHONE.
- `release_year`: four-digit year, 1980–2100.
- `item_type`: `COVER`, `GLASS` or `LENS`. If stock is supplied and blank, COVER is used.
- `stock`: non-negative whole number. Leave blank to keep the current count.
- `group_name`: rows with the same name and item type are grouped; at least two distinct models are required.
- `confidence`: `SURE` or `NINETY`; blank means NINETY for group membership.

Example (only after physical fit confirmation):

```csv
brand,model,device_kind,release_year,item_type,stock,group_name,confidence
Honor,X9c,PHONE,2025,GLASS,0,Glass SKU ABC,NINETY
Honor,Magic 7 Lite,PHONE,2025,GLASS,4,Glass SKU ABC,NINETY
```

CSV imports run in a single transaction. A bad row/group rolls back the import. CSV is intended for owner-managed inventory and manually verified groups; use AI Data Pack when evidence URLs/notes need to travel with a researched relationship.

## Backup and data safety

- Database: app-private `cover_stock.sqlite` inside Android application documents storage.
- Restore replaces the current local database; make a backup first.
- Uninstalling the app or clearing its data removes the local database. Store backups outside the app.
- Model catalogue refreshes merge only new names; existing models, stock counts, groups and WRONG decisions are not removed by a new APK.
- Importing an AI Data Pack does not edit existing stock counts. Existing group names are skipped; previously-WRONG pairs cannot be reintroduced.
- The app contains no runtime sync. Choosing a cloud destination in Android's share UI is an owner action, not app background upload.

## Build/signing note

No private release keystore is included. GitHub Actions produces an APK for direct installation on the owner's phone, not a Play Store publishing bundle. Keep a separate, backed-up signing key if long-term public distribution is planned. Direct dependency versions are pinned in `pubspec.yaml`; after the first successful Actions run, optionally download the separate `cover-stock-pubspec-lock` artifact, place `pubspec.lock` in the repository root and push it to keep transitive dependency resolution repeatable.

## Test checklist

See `HANDOFF.md` for the owner acceptance checklist, CI checks and verification limits.
