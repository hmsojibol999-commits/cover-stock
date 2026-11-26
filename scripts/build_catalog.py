#!/usr/bin/env python3
"""Build Cover Stock's offline phone/tablet name catalogue from TechAPI.

Only model names and release years are copied. No compatibility is inferred.
Uses GitHub's public tree API, so it does not download the full 90k-record dataset.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

REPOSITORY = "GetTechAPI/TechAPI"
DEFAULT_REF = "develop"
API_ROOT = f"https://api.github.com/repos/{REPOSITORY}"
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "model_catalog.json"

# These are the brands the shop owner requested. Apple and Google are narrowed
# to iPhone and Pixel respectively; Xiaomi's Redmi models are split by prefix.
PHONE_BRANDS = {
    "honor": "Honor",
    "vivo": "Vivo",
    "oppo": "Oppo",
    "xiaomi": "Xiaomi",
    "poco": "Poco",
    "samsung": "Samsung",
    "apple": "iPhone",
    "google": "Google Pixel",
    "nothing": "Nothing",
    "infinix": "Infinix",
    "tecno": "Tecno",
    "oneplus": "OnePlus",
    "motorola": "Motorola",
}

TABLET_BRANDS = {
    "honor": "Honor",
    "vivo": "Vivo",
    "oppo": "Oppo",
    "xiaomi": "Xiaomi",
    "samsung": "Samsung",
    "apple": "iPad",
    "google": "Google Pixel",
    "infinix": "Infinix",
    "tecno": "Tecno",
    "oneplus": "OnePlus",
    "motorola": "Motorola",
}


def _headers() -> dict[str, str]:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "CoverStock-Offline-Catalog/1.0",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def fetch_json(url: str) -> dict[str, Any] | list[Any] | None:
    request = urllib.request.Request(url, headers=_headers())
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return None
        body = error.read().decode("utf-8", errors="replace")[:500]
        raise RuntimeError(f"GitHub API returned HTTP {error.code} for {url}: {body}") from error
    except (urllib.error.URLError, TimeoutError) as error:
        raise RuntimeError(f"Could not reach the model catalogue source: {error}") from error


def normalize(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.casefold())


def _display_words(slug: str) -> str:
    replacements = {
        "5g": "5G", "4g": "4G", "3g": "3G", "2g": "2G",
        "lte": "LTE", "nfc": "NFC", "uhd": "UHD", "hd": "HD",
        "pro": "Pro", "plus": "Plus", "ultra": "Ultra", "max": "Max",
        "mini": "Mini", "lite": "Lite", "neo": "Neo", "fe": "FE",
        "rsr": "RSR", "gt": "GT", "se": "SE", "xr": "XR",
        "xs": "XS", "xr": "XR", "xl": "XL", "ii": "II", "iii": "III",
    }
    words = [word for word in re.split(r"[-_\s]+", slug) if word]
    return " ".join(replacements.get(word.casefold(), word[:1].upper() + word[1:]) for word in words)


def clean_model_slug(slug: str, data_brand: str, category: str) -> tuple[str, str] | None:
    """Return display brand + model name. None means outside requested range."""
    value = slug.casefold().strip("-_")
    if not value:
        return None

    if data_brand == "apple":
        if category == "smartphone":
            if "iphone" not in value:
                return None
            value = re.sub(r"^(?:apple-)?iphone-?", "", value)
            brand = "iPhone"
        else:
            if "ipad" not in value:
                return None
            value = re.sub(r"^(?:apple-)?ipad-?", "", value)
            brand = "iPad"
    elif data_brand == "google":
        if "pixel" not in value:
            return None
        value = re.sub(r"^google-", "", value)
        value = re.sub(r"^pixel-?", "", value)
        brand = "Google Pixel"
    elif data_brand == "xiaomi" and (value.startswith("redmi-") or value.startswith("xiaomi-redmi-")):
        value = re.sub(r"^xiaomi-", "", value)
        value = re.sub(r"^redmi-?", "", value)
        brand = "Redmi"
    else:
        brand = (TABLET_BRANDS if category == "tablet" else PHONE_BRANDS).get(data_brand, data_brand.title())
        prefixes = {
            "honor": ("honor-",),
            "vivo": ("bbk-vivo-", "vivo-"),
            "oppo": ("oppo-",),
            "xiaomi": ("xiaomi-",),
            "poco": ("poco-",),
            "samsung": ("samsung-",),
            "nothing": ("nothing-",),
            "infinix": ("infinix-",),
            "tecno": ("tecno-mobile-", "tecno-"),
            "oneplus": ("oneplus-",),
            "motorola": ("motorola-",),
        }.get(data_brand, ())
        for prefix in prefixes:
            if value.startswith(prefix):
                value = value[len(prefix):]
                break

    # The source tree's folder is usually the base model. A few records still
    # carry RAM/storage suffixes, which should not become separate shop models.
    value = re.sub(r"-(?:\d+gb-ram-)?\d+gb(?:-\d+gb)?$", "", value)
    value = re.sub(r"-(?:\d+gb-ram|\d+gb-storage)$", "", value)
    value = value.strip("-_")
    if not value:
        return None

    # Exclude the iQOO sub-brand from Vivo; it has its own brand folder.
    if data_brand == "vivo" and (value.startswith("iqoo-") or value == "iqoo"):
        return None

    return brand, _display_words(value)


def extract_models(
    tree: dict[str, Any], data_brand: str, category: str, ref: str = DEFAULT_REF
) -> list[dict[str, Any]]:
    if tree.get("truncated"):
        raise RuntimeError(f"Git tree for {data_brand}/{category} was truncated; refusing partial catalogue")

    # A path is either YEAR/model-slug.json or YEAR/base-model-slug/record.json.
    # In the latter form the first directory is TechAPI's base-model grouping.
    chosen: dict[tuple[str, str, str], dict[str, Any]] = {}
    for entry in tree.get("tree", []):
        if entry.get("type") != "blob":
            continue
        path = str(entry.get("path", ""))
        if not path.endswith(".json"):
            continue
        parts = path.split("/")
        if len(parts) < 2:
            continue
        year = int(parts[0]) if re.fullmatch(r"19\d{2}|20\d{2}", parts[0]) else None
        model_slug = Path(parts[1]).stem if len(parts) == 2 else parts[1]
        result = clean_model_slug(model_slug, data_brand, category)
        if result is None:
            continue
        display_brand, model_name = result
        key = (display_brand.casefold(), normalize(model_name), category)
        if not key[1]:
            continue
        candidate = {
            "brand": display_brand,
            "name": model_name,
            "deviceKind": "TABLET" if category == "tablet" else "PHONE",
            "releaseYear": year,
            "sourceUrl": f"https://github.com/{REPOSITORY}/tree/{ref}/data/{category}/{data_brand}/{parts[0]}",
        }
        previous = chosen.get(key)
        if previous is None or (year or 0) > (previous.get("releaseYear") or 0):
            chosen[key] = candidate

    return list(chosen.values())


def build_catalog(ref: str = DEFAULT_REF) -> dict[str, Any]:
    all_models: dict[tuple[str, str, str], dict[str, Any]] = {}
    source_trees: list[tuple[str, str, str]] = []

    for category, brand_map in (("smartphone", PHONE_BRANDS), ("tablet", TABLET_BRANDS)):
        root = fetch_json(f"{API_ROOT}/contents/data/{category}?ref={ref}")
        if not isinstance(root, list):
            raise RuntimeError(f"Could not read TechAPI {category} brand index")
        by_name = {entry.get("name"): entry for entry in root if isinstance(entry, dict)}
        for brand_slug in brand_map:
            brand_entry = by_name.get(brand_slug)
            if not brand_entry:
                # Some requested brands have no tablet records; this is normal.
                if category == "tablet":
                    continue
                raise RuntimeError(f"TechAPI has no {category} folder for requested brand: {brand_slug}")
            tree = fetch_json(f"{API_ROOT}/git/trees/{brand_entry['sha']}?recursive=1")
            if not isinstance(tree, dict):
                if category == "tablet":
                    continue
                raise RuntimeError(f"Could not read TechAPI tree for {category}/{brand_slug}")
            source_trees.append((category, brand_slug, str(brand_entry["sha"])))
            for model in extract_models(tree, brand_slug, category, ref):
                key = (model["brand"].casefold(), normalize(model["name"]), model["deviceKind"])
                previous = all_models.get(key)
                if previous is None or (model.get("releaseYear") or 0) > (previous.get("releaseYear") or 0):
                    all_models[key] = model

    models = sorted(
        all_models.values(),
        key=lambda item: (
            item["brand"].casefold(),
            item["deviceKind"],
            item["name"].casefold(),
        ),
    )
    model_bytes = json.dumps(models, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    version = hashlib.sha256(model_bytes).hexdigest()[:16]
    return {
        "schemaVersion": 1,
        "catalogVersion": version,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "source": {
            "name": "TechAPI",
            "repository": f"https://github.com/{REPOSITORY}",
            "ref": ref,
            "license": "CC BY-SA 4.0",
            "attribution": "Data from TechAPI",
            "shareAlike": True,
            "note": "Model-name discovery catalogue only. TechAPI is not an exhaustive list. It does not provide accessory-fit compatibility; no Cover/Glass/Lens links are inferred from specifications.",
        },
        "counts": {
            "phones": sum(1 for item in models if item["deviceKind"] == "PHONE"),
            "tablets": sum(1 for item in models if item["deviceKind"] == "TABLET"),
            "brands": len({item["brand"] for item in models}),
        },
        "models": models,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ref", default=os.environ.get("TECHAPI_REF", DEFAULT_REF))
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    catalog = build_catalog(args.ref)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        f"Built offline catalogue: {catalog['counts']['phones']} phones, "
        f"{catalog['counts']['tablets']} tablets, {catalog['counts']['brands']} brands; "
        f"version {catalog['catalogVersion']} -> {args.output}"
    )
    print("Compatibility groups were not generated; model names/specs cannot prove an accessory fit.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:  # Fail the APK build rather than silently ship an incomplete catalogue.
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
