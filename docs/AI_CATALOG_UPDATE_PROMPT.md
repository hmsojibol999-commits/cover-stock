# Prompt for future AI model / compatibility updates

Use this prompt in ChatGPT when a new phone/tablet model or a newly confirmed accessory fit needs to be added to Cover Stock.

---

You are preparing an offline data update for the Flutter Android app **Cover Stock**.

Research the requested phone/tablet model names and accessory compatibility using current web sources. Return exactly one valid JSON object and no Markdown fences.

The object must use this schema:

```json
{
  "schemaVersion": 1,
  "models": [
    {
      "brand": "Honor",
      "name": "X9c",
      "deviceKind": "PHONE",
      "releaseYear": 2025
    }
  ],
  "compatibilityGroups": [
    {
      "itemType": "GLASS",
      "label": "Exact supplier part / SKU name",
      "confidence": "NINETY",
      "evidenceUrls": [
        "https://source-one.example/product-or-spec-page"
      ],
      "evidenceNote": "Explain what the source confirms and what still needs a physical check.",
      "members": [
        { "brand": "Honor", "model": "X9c" },
        { "brand": "Honor", "model": "Another exact model" }
      ]
    }
  ]
}
```

## Research and safety rules

1. Add every requested new phone or tablet to `models`, even when no accessory fit is known. `deviceKind` must be `PHONE` or `TABLET`; use a four-digit `releaseYear` when known, otherwise `null`.
2. The supported brand names are Honor, Vivo, Oppo, Redmi, Xiaomi, Poco, Samsung, iPhone, iPad, Google Pixel, Nothing, Infinix, Tecno, OnePlus and Motorola. Keep model names in English exactly enough to identify the retail model. Do not combine separate brands (for example, Redmi and Xiaomi).
3. Never infer compatibility from a shared screen diagonal, similar model name, same processor, or a marketing family name.
4. `COVER` fit needs the same body shape, exact dimensions, button/port positions and camera cutout. `GLASS` needs the actual front-glass outline, curvature, border, notch/punch-hole and sensor cutouts. `LENS` needs the exact camera island, lens spacing and flash openings. Treat these as three independent compatibility types.
5. Mark a group `SURE` only when at least two independent reliable domains explicitly support the same exact accessory part/SKU for all member models. A documented physical fit test is useful extra evidence, but the importer still requires two distinct source domains for `SURE`. Put the supporting URLs in `evidenceUrls`.
6. Mark a group `NINETY` only when at least one reliable source supports a plausible physical match but exact fit is not proven. State the uncertainty in `evidenceNote`. The app will show a warning to check before giving.
7. If the evidence is weak or unknown, do not create a compatibility group. Do not invent, fill gaps, or silently upgrade confidence.
8. Each compatibility group must contain at least two distinct model members, all included in `models` or already present in the app. A tablet must never be included in a `LENS` group.
9. The app import checks that URLs are valid HTTP(S), that a `SURE` group contains at least two distinct domains, and that a `NINETY` group has at least one URL. These checks do not prove that a web page genuinely supports the fit. The owner must inspect evidence and physically check uncertain parts.
10. Do not include stock counts, prices, pictures, API keys, user data, or any other fields.

Output valid JSON only. Do not invent sources or claim to have physically tested a part.

---

## How to use the generated file

1. Save the JSON response as a `.json` file on the phone.
2. In Cover Stock open **Settings → AI Data Pack যোগ করুন**.
3. Select the JSON file.
4. The app merges new models and compatibility groups into SQLite. It does not change existing stock counts, does not overwrite an existing group with the same label, and will reject any model pair previously marked WRONG.
5. Back up the database after a successful import.
