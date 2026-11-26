# Compatibility research — public-source batch 1

Generated: 2026-11-26

## Scope

This update uses the exact device names present in the APK catalogue built by GitHub Actions: 17,816 phones and 418 tablets (18,234 total). It does not claim that every one of those devices has been individually researched. This is the first public-evidence batch and only includes model memberships shown by inspected sources and found in the app catalogue.

## Imported coverage

- GLASS: 58 groups, 285 group memberships (including the previously bundled K34 candidate).
- COVER: 10 groups, 24 group memberships.
- LENS: 0 cross-model groups added. Accessible sources listed camera-protector product categories but did not expose exact shared camera-lens-protector fitment groups suitable for a trustworthy import.

Every new record is currently NINETY / candidate. No SURE record is added in this batch. The app should be treated as a research aid, not a substitute for checking the exact supplier SKU and physically dry-fitting stock.

## Source rules

1. A shared display size or similar model name is not enough.
2. GLASS means external tempered-glass screen protector only. It does not mean LCD combo, refurbished outer glass, touch digitizer, COVER or LENS.
3. COVER groups are tied to named case-maker/seller listings or product lines. A shared fit for one product does not mean every generic case shell will fit.
4. One-way fit claims are not imported because the current app stores symmetric groups.
5. Conflicting or style-specific cover data is labelled conditional and explains the limitation.
6. Unknown pairs are intentionally omitted; no compatibility is inferred from dimensions alone.

## GLASS source families

- MobiMatch Pro: https://www.mobimatchpro.com/ — public glass SKUs/dimensional groups, including Samsung, iPhone, Google Pixel, Redmi/POCO, OPPO/OnePlus, Vivo, Honor, Tecno/Infinix and Motorola groups. The source itself warns that glass cut type must match and that tempered-glass compatibility does not transfer to LCD, outer refurbishment glass or digitizer. These are imported as NINETY candidates because the public page is one source domain.
- TheMobileFit brand lists: https://themobilefit.com/vivo-display-compatibility-list/ ; https://themobilefit.com/samsung-display-compatibility-list/ ; https://themobilefit.com/oppo-display-compatibility-list/ ; https://themobilefit.com/redmi-display-compatibility-list/ ; https://themobilefit.com/iphone-display-compatibility-list/ ; https://themobilefit.com/oneplus-display-compatibility-list/ ; https://themobilefit.com/motorola-display-compatibility-list/ . Public pages show the most shared glass groups; the rest is behind the live finder. TheMobileFit says the lists are based on supplier lists, can contain errors and must be checked before applying the glass.

## COVER source families

- IDEAL OF SWEDEN product/warranty compatibility FAQ: https://idealofsweden.sg/faq/product-warranty — provides specific shared case families and specifies when a group applies only to certain product styles.
- TVCMALL iPhone 6/6s/7/8 compatibility article: https://www.tvcmall.com/blog/model-compatibility-comparison/iphone-6-6s-7-and-8-plus-series-compatibility-comparison-of-phone-cases-and-screen-protectors.html — explicitly separates 6/6s from 7/8 because camera placement differs.
- Keyway Designs iPhone model/case chart: https://www.keywaydesigns.com/pages/which-iphone-do-i-have-iphone-identification-case-compatibility — used only for the explicitly listed X/XS pair.
- Blanc Space iPhone 12/12 Pro cases: https://www.blancspace.com/collections/iphone-12-cases — supports a particular case shell for both; the conflicting generic-fit warning is retained in the app note.
- Target / OtterBox / Cygnett case listings: https://www.target.com/p/-/A-89182358 ; https://www.bestbuy.com/product/otterbox-commuter-series-hard-shell-case-for-apple-iphone-17e-apple-iphone-16e-iphone-15-iphone-14-iphone-13-get-your-greens/JX9SWQ647S ; https://www.harveynorman.com.au/cygnett-aeroshield-clear-protective-case-for-iphone-17e-16e-14-13.html — explicitly list iPhone 13/14/15/16e/17e on named products.
- Digitec / Flipkart product listings for specific Galaxy S24/S25 cases: https://www.digitec.ch/en/s1/product/selencia-riviera-magsafe-back-cover-with-detachable-hooks-samsung-galaxy-s24-samsung-galaxy-s25-mobi-76477972 ; https://www.flipkart.com/first-mart-back-cover-samsung-galaxy-s24-5g-s25-magsafe-compatible-magnetic-shockproof-case/p/itmf6aecbec73b65 .
- Everacs case compatibility guide (2026-09-04): https://www.everacs.com/blogs/guides/can-one-phone-case-fit-different-phone-models — explicitly cites exact product listings for Smart 8/Smart 8 Plus and Smart 9/Hot 50i/TECNO Spark Go 1.

## Limitations and next research pass

- TheMobileFit exposes only its 12 most-shared glass groups per public brand page; its full finder is account-limited (10 free lookups/month according to its FAQ). The remaining groups cannot be safely reconstructed from public snippets.
- Mobile Parts Finder advertises thousands of screen-guard and back-cover groups, but its pages returned HTTP 402 to the research browser, so no uninspected records were imported.
- The current database importer allows one compatibility group per model per category. When public sources assign one model to multiple different groups, conflicting groups are excluded rather than silently forcing a false merge.
- COVER entries only reflect the specific case types/listings in the evidence note. The source data does not prove that every supplier cover is interchangeable.
- LENS remains empty until an exact camera-lens-protector fitment list or matching supplier SKU is found.

## Imported groups

### GLASS

- **K34 — Tempered Glass (conditional candidate)** — 5 models. Sources: https://www.mobimatchpro.com/
- **GLS-001 — Samsung A16 6.7-inch shared glass** — 5 models. Sources: https://www.mobimatchpro.com/
- **GLS-002 — Samsung A56 6.7-inch shared glass** — 5 models. Sources: https://www.mobimatchpro.com/
- **GLS-003 — Samsung S25/S24 6.2-inch shared glass** — 2 models. Sources: https://www.mobimatchpro.com/
- **GLS-005 — iPhone 17 Pro/16 Pro/17 6.3-inch glass** — 3 models. Sources: https://www.mobimatchpro.com/
- **GLS-006 — iPhone 17 Pro Max/16 Pro Max glass** — 2 models. Sources: https://www.mobimatchpro.com/
- **GLS-007 — Pixel 9/10 6.3-inch glass** — 4 models. Sources: https://www.mobimatchpro.com/
- **GLS-008 — Redmi Note 13 / POCO X6 shared glass** — 4 models. Sources: https://www.mobimatchpro.com/
- **GLS-009 — OPPO/OnePlus BBK shared glass** — 8 models. Sources: https://www.mobimatchpro.com/
- **GLS-010 — Vivo Y-series / OPPO A-series shared glass** — 11 models. Sources: https://www.mobimatchpro.com/
- **Boko — Vivo V50/V60 shared curved glass** — 6 models. Sources: https://www.mobimatchpro.com/
- **Boko — Vivo V27/V29e glass group** — 12 models. Sources: https://www.mobimatchpro.com/
- **VV-G02 — Vivo Y11/Y12/Y15/Y17 shared glass** — 4 models. Sources: https://www.mobimatchpro.com/
- **VV-G06 — Vivo T3/Y300/Y200 glass group** — 2 models. Sources: https://www.mobimatchpro.com/
- **HN-G05 — Honor 60/70 glass group** — 2 models. Sources: https://www.mobimatchpro.com/
- **HN-G06 — Honor 90/100 glass group** — 2 models. Sources: https://www.mobimatchpro.com/
- **HN-G07 — Honor 200/300 glass group** — 2 models. Sources: https://www.mobimatchpro.com/
- **TR-G01 — Tecno/Infinix shared large glass group** — 8 models. Sources: https://www.mobimatchpro.com/
- **TR-G02 — Tecno/Infinix entry glass group** — 5 models. Sources: https://www.mobimatchpro.com/
- **TR — Tecno Camon 20 generation glass** — 3 models. Sources: https://www.mobimatchpro.com/
- **TR — Tecno Camon 30/40 shared glass** — 2 models. Sources: https://www.mobimatchpro.com/
- **TR — Infinix Note 40/50 shared glass** — 2 models. Sources: https://www.mobimatchpro.com/
- **MOT-G03 — Motorola Edge 40 curved glass** — 2 models. Sources: https://www.mobimatchpro.com/
- **MOT-G04 — Motorola Edge 50 curved glass** — 3 models. Sources: https://www.mobimatchpro.com/
- **MOT-G05 — Motorola G53/G54/G73 glass** — 3 models. Sources: https://www.mobimatchpro.com/
- **TechFix G19 — Samsung A21s / OPPO A53 glass** — 2 models. Sources: https://www.mobimatchpro.com/
- **TechFix G21 — Samsung A05s / M14 / F14 glass** — 3 models. Sources: https://www.mobimatchpro.com/
- **TechFix G26 — Honor X6 glass family** — 4 models. Sources: https://www.mobimatchpro.com/
- **TechFix G28 — Redmi Note 10/11/12S glass family** — 4 models. Sources: https://www.mobimatchpro.com/
- **TechFix G30 — Infinix Note 12 family** — 4 models. Sources: https://www.mobimatchpro.com/
- **TheMobileFit — Vivo T3x/T4x shared glass** — 10 models. Sources: https://themobilefit.com/vivo-display-compatibility-list/
- **TheMobileFit — Vivo V21 shared glass** — 7 models. Sources: https://themobilefit.com/vivo-display-compatibility-list/
- **TheMobileFit — Samsung A14 4G glass** — 5 models. Sources: https://themobilefit.com/samsung-display-compatibility-list/
- **TheMobileFit — Samsung A15 4G glass** — 8 models. Sources: https://themobilefit.com/samsung-display-compatibility-list/
- **TheMobileFit — Samsung A30 glass** — 14 models. Sources: https://themobilefit.com/samsung-display-compatibility-list/
- **TheMobileFit — Samsung A31 glass** — 2 models. Sources: https://themobilefit.com/samsung-display-compatibility-list/
- **TheMobileFit — Samsung A51 glass** — 9 models. Sources: https://themobilefit.com/samsung-display-compatibility-list/
- **TheMobileFit — Samsung A71 glass** — 11 models. Sources: https://themobilefit.com/samsung-display-compatibility-list/
- **TheMobileFit — OPPO A53 glass** — 7 models. Sources: https://themobilefit.com/oppo-display-compatibility-list/
- **TheMobileFit — Redmi 9A glass** — 4 models. Sources: https://themobilefit.com/redmi-display-compatibility-list/
- **TheMobileFit — Redmi 10C/10 Prime glass** — 10 models. Sources: https://themobilefit.com/redmi-display-compatibility-list/
- **TheMobileFit — Redmi 12 4G glass** — 6 models. Sources: https://themobilefit.com/redmi-display-compatibility-list/
- **TheMobileFit — Redmi 14C glass** — 3 models. Sources: https://themobilefit.com/redmi-display-compatibility-list/
- **TheMobileFit — Redmi 15C glass** — 4 models. Sources: https://themobilefit.com/redmi-display-compatibility-list/
- **TheMobileFit — Redmi K30 glass** — 8 models. Sources: https://themobilefit.com/redmi-display-compatibility-list/
- **TheMobileFit — iPhone 13 glass** — 5 models. Sources: https://themobilefit.com/iphone-display-compatibility-list/
- **TheMobileFit — iPhone 15 glass** — 2 models. Sources: https://themobilefit.com/iphone-display-compatibility-list/
- **TheMobileFit — iPhone 15 Plus glass** — 2 models. Sources: https://themobilefit.com/iphone-display-compatibility-list/
- **TheMobileFit — iPhone 11 Pro/X/XS glass** — 3 models. Sources: https://themobilefit.com/iphone-display-compatibility-list/
- **TheMobileFit — iPhone 11/XR glass** — 2 models. Sources: https://themobilefit.com/iphone-display-compatibility-list/
- **TheMobileFit — OnePlus 8T/9/9R glass** — 3 models. Sources: https://themobilefit.com/oneplus-display-compatibility-list/
- **TheMobileFit — OnePlus 9 Pro/10 Pro/11 glass** — 5 models. Sources: https://themobilefit.com/oneplus-display-compatibility-list/
- **TheMobileFit — OnePlus 12R/Ace 3 glass** — 3 models. Sources: https://themobilefit.com/oneplus-display-compatibility-list/
- **TheMobileFit — OnePlus Nord 2 glass** — 3 models. Sources: https://themobilefit.com/oneplus-display-compatibility-list/
- **TheMobileFit — OnePlus Nord 3 glass** — 7 models. Sources: https://themobilefit.com/oneplus-display-compatibility-list/
- **TheMobileFit — Motorola G13 glass** — 9 models. Sources: https://themobilefit.com/motorola-display-compatibility-list/
- **TheMobileFit — Motorola G31 glass** — 4 models. Sources: https://themobilefit.com/motorola-display-compatibility-list/
- **TheMobileFit — Motorola G52 glass** — 5 models. Sources: https://themobilefit.com/motorola-display-compatibility-list/

### COVER

- **COVER — iPhone 6 / 6s case shell** — 2 models. Sources: https://idealofsweden.sg/faq/product-warranty, https://www.tvcmall.com/blog/model-compatibility-comparison/iphone-6-6s-7-and-8-plus-series-compatibility-comparison-of-phone-cases-and-screen-protectors.html
- **COVER — iPhone 7 / 8 case shell** — 2 models. Sources: https://idealofsweden.sg/faq/product-warranty, https://www.tvcmall.com/blog/model-compatibility-comparison/iphone-6-6s-7-and-8-plus-series-compatibility-comparison-of-phone-cases-and-screen-protectors.html
- **COVER — iPhone 6 Plus / 6s Plus case shell** — 2 models. Sources: https://idealofsweden.sg/faq/product-warranty, https://www.tvcmall.com/blog/model-compatibility-comparison/iphone-6-6s-7-and-8-plus-series-compatibility-comparison-of-phone-cases-and-screen-protectors.html
- **COVER — iPhone 7 Plus / 8 Plus case shell** — 2 models. Sources: https://idealofsweden.sg/faq/product-warranty, https://www.tvcmall.com/blog/model-compatibility-comparison/iphone-6-6s-7-and-8-plus-series-compatibility-comparison-of-phone-cases-and-screen-protectors.html
- **COVER — iPhone X / XS case (listed shell only)** — 2 models. Sources: https://www.keywaydesigns.com/pages/which-iphone-do-i-have-iphone-identification-case-compatibility
- **COVER — iPhone 12 / 12 Pro (selected wide-cut cases)** — 2 models. Sources: https://idealofsweden.sg/faq/product-warranty, https://www.blancspace.com/collections/iphone-12-cases, https://www.keywaydesigns.com/pages/which-iphone-do-i-have-iphone-identification-case-compatibility
- **COVER — iPhone 13 / 14 / 15 / 16e / 17e (specific case designs)** — 5 models. Sources: https://idealofsweden.sg/faq/product-warranty, https://www.target.com/p/-/A-89182358, https://www.bestbuy.com/product/otterbox-commuter-series-hard-shell-case-for-apple-iphone-17e-apple-iphone-16e-iphone-15-iphone-14-iphone-13-get-your-greens/JX9SWQ647S, https://www.harveynorman.com.au/cygnett-aeroshield-clear-protective-case-for-iphone-17e-16e-14-13.html
- **COVER — Samsung Galaxy S24 / S25 (specific case designs)** — 2 models. Sources: https://idealofsweden.sg/faq/product-warranty, https://www.digitec.ch/en/s1/product/selencia-riviera-magsafe-back-cover-with-detachable-hooks-samsung-galaxy-s24-samsung-galaxy-s25-mobi-76477972, https://www.flipkart.com/first-mart-back-cover-samsung-galaxy-s24-5g-s25-magsafe-compatible-magnetic-shockproof-case/p/itmf6aecbec73b65
- **COVER — Infinix Smart 8 / Smart 8 Plus (Everacs case listing)** — 2 models. Sources: https://www.everacs.com/blogs/guides/can-one-phone-case-fit-different-phone-models
- **COVER — Infinix Smart 9 / Hot 50i / TECNO Spark Go 1 (Everacs case listing)** — 3 models. Sources: https://www.everacs.com/blogs/guides/can-one-phone-case-fit-different-phone-models
