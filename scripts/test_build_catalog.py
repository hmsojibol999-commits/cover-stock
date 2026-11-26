import unittest

from build_catalog import clean_model_slug, extract_models


class CatalogExtractionTests(unittest.TestCase):
    def test_extracts_old_and_recent_honor_names_from_group_and_direct_records(self):
        tree = {
            "truncated": False,
            "tree": [
                {"type": "blob", "path": "2018/honor-10/honor-10.json"},
                {"type": "blob", "path": "2025/x9c/x9c.json"},
                {"type": "blob", "path": "2026/honor-magic-8-pro.json"},
            ],
        }
        models = extract_models(tree, "honor", "smartphone", "test-ref")
        by_name = {item["name"]: item for item in models}
        self.assertEqual(set(by_name), {"10", "X9c", "Magic 8 Pro"})
        self.assertEqual(by_name["Magic 8 Pro"]["releaseYear"], 2026)
        self.assertIn("test-ref", by_name["Magic 8 Pro"]["sourceUrl"])

    def test_splits_redmi_from_xiaomi(self):
        self.assertEqual(clean_model_slug("redmi-note-12-4g", "xiaomi", "smartphone"), ("Redmi", "Note 12 4G"))
        self.assertEqual(clean_model_slug("xiaomi-13t-pro", "xiaomi", "smartphone"), ("Xiaomi", "13t Pro"))

    def test_keeps_iphone_and_ipad_in_separate_catalogs(self):
        self.assertEqual(clean_model_slug("iphone-15-pro-max", "apple", "smartphone"), ("iPhone", "15 Pro Max"))
        self.assertIsNone(clean_model_slug("ipad-pro-11", "apple", "smartphone"))
        self.assertEqual(clean_model_slug("ipad-pro-11", "apple", "tablet"), ("iPad", "Pro 11"))

    def test_filters_non_pixel_google_devices(self):
        self.assertEqual(clean_model_slug("google-pixel-8a", "google", "smartphone"), ("Google Pixel", "8a"))
        self.assertIsNone(clean_model_slug("google-nexus-6", "google", "smartphone"))

    def test_filters_iqoo_out_of_vivo_folder(self):
        self.assertIsNone(clean_model_slug("iqoo-z10", "vivo", "smartphone"))
        self.assertEqual(clean_model_slug("vivo-v30", "vivo", "smartphone"), ("Vivo", "V30"))

    def test_refuses_truncated_tree(self):
        with self.assertRaises(RuntimeError):
            extract_models({"truncated": True, "tree": []}, "honor", "smartphone")


if __name__ == "__main__":
    unittest.main()
