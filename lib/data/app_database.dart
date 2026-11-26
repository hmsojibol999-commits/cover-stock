import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static Future<AppDatabase> open() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'cover_stock.sqlite');
    final database = await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
    final instance = AppDatabase._(database);
    await instance._seedIfEmpty();
    await instance.mergeBundledCatalog();
    return instance;
  }

  static Future<void> _createSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE brands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL COLLATE NOCASE UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE models (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand_id INTEGER NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
        name TEXT NOT NULL COLLATE NOCASE,
        device_kind TEXT NOT NULL DEFAULT 'PHONE',
        release_year INTEGER,
        UNIQUE(brand_id, name)
      )
    ''');
    await db.execute('''
      CREATE TABLE stocks (
        model_id INTEGER NOT NULL REFERENCES models(id) ON DELETE CASCADE,
        item_type TEXT NOT NULL,
        count INTEGER NOT NULL DEFAULT 0 CHECK(count >= 0),
        PRIMARY KEY(model_id, item_type)
      )
    ''');
    await db.execute('''
      CREATE TABLE compatibility_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_type TEXT NOT NULL,
        label TEXT NOT NULL,
        evidence_urls TEXT NOT NULL DEFAULT '[]',
        evidence_note TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE compatibility_members (
        group_id INTEGER NOT NULL REFERENCES compatibility_groups(id) ON DELETE CASCADE,
        model_id INTEGER NOT NULL REFERENCES models(id) ON DELETE CASCADE,
        confidence TEXT NOT NULL DEFAULT 'NINETY',
        PRIMARY KEY(group_id, model_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE compatibility_pair_overrides (
        item_type TEXT NOT NULL,
        model_a INTEGER NOT NULL,
        model_b INTEGER NOT NULL,
        confidence TEXT NOT NULL,
        PRIMARY KEY(item_type, model_a, model_b)
      )
    ''');
    await db.execute('''
      CREATE TABLE compatibility_wrong (
        item_type TEXT NOT NULL,
        model_a INTEGER NOT NULL,
        model_b INTEGER NOT NULL,
        PRIMARY KEY(item_type, model_a, model_b)
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_models_brand ON models(brand_id)');
    await db.execute('CREATE INDEX idx_models_name ON models(name COLLATE NOCASE)');
    await db.execute('CREATE INDEX idx_members_model ON compatibility_members(model_id)');
    await db.insert('settings', {'key': 'threshold', 'value': '2'});
    await db.insert('settings', {'key': 'dark_mode', 'value': 'false'});
  }

  static Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE models ADD COLUMN device_kind TEXT NOT NULL DEFAULT 'PHONE'");
      await db.execute('ALTER TABLE models ADD COLUMN release_year INTEGER');
      await db.execute("ALTER TABLE compatibility_groups ADD COLUMN evidence_urls TEXT NOT NULL DEFAULT '[]'");
      await db.execute("ALTER TABLE compatibility_groups ADD COLUMN evidence_note TEXT NOT NULL DEFAULT ''");
      await db.execute('CREATE INDEX IF NOT EXISTS idx_models_name ON models(name COLLATE NOCASE)');
    }
  }

  Future<void> _seedIfEmpty() async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM brands')) ?? 0;
    if (count > 0) return;
    final raw = await rootBundle.loadString('assets/seed_data.json');
    final seed = jsonDecode(raw) as Map<String, dynamic>;
    await db.transaction((txn) async {
      for (final entry in (seed['brands'] as List<dynamic>)) {
        final brand = entry as Map<String, dynamic>;
        final brandId = await txn.insert('brands', {'name': brand['name']});
        for (final value in (brand['models'] as List<dynamic>)) {
          final modelId = await txn.insert('models', {
            'brand_id': brandId,
            'name': value.toString(),
            'device_kind': 'PHONE',
          });
          await _createZeroStocks(txn, modelId, DeviceKind.phone);
        }
      }
    });
  }

  Future<void> mergeBundledCatalog() async {
    final raw = await rootBundle.loadString('assets/model_catalog.json');
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['models'] is! List) return;
    final catalogVersion = decoded['catalogVersion']?.toString() ?? 'starter';
    final saved = await db.query('settings', columns: ['value'], where: 'key = ?', whereArgs: ['catalog_version'], limit: 1);
    if (saved.isNotEmpty && saved.first['value'] == catalogVersion) return;

    await db.transaction((txn) async {
      final brandRows = await txn.query('brands', columns: ['id', 'name']);
      final brandIds = <String, int>{
        for (final row in brandRows) normalizeSearch(row['name'] as String): row['id'] as int,
      };
      final existingRows = await txn.query('models', columns: ['brand_id', 'name']);
      final seen = <int, Set<String>>{};
      for (final row in existingRows) {
        final brandId = row['brand_id'] as int;
        seen.putIfAbsent(brandId, () => <String>{}).add(normalizeSearch(row['name'] as String));
      }

      final pending = <Map<String, Object?>>[];
      for (final item in decoded['models'] as List<dynamic>) {
        if (item is! Map<String, dynamic>) continue;
        final brandName = item['brand']?.toString().trim() ?? '';
        final modelName = item['name']?.toString().trim() ?? '';
        if (brandName.isEmpty || modelName.isEmpty) continue;
        final kind = DeviceKindText.parse(item['deviceKind'] ?? item['device_kind']);
        final brandKey = normalizeSearch(brandName);
        var brandId = brandIds[brandKey];
        if (brandId == null) {
          brandId = await txn.insert('brands', {'name': brandName});
          brandIds[brandKey] = brandId;
          seen[brandId] = <String>{};
        }
        final modelKey = normalizeSearch(modelName);
        if (modelKey.isEmpty || (seen[brandId]?.contains(modelKey) ?? false)) continue;
        final year = _parseYear(item['releaseYear'] ?? item['release_year']);
        pending.add({
          'brand_id': brandId,
          'name': modelName,
          'device_kind': kind.key,
          'release_year': year,
        });
        seen.putIfAbsent(brandId, () => <String>{}).add(modelKey);
      }

      // Batch inserts avoid tens of thousands of platform-channel round trips.
      if (pending.isNotEmpty) {
        final modelBatch = txn.batch();
        for (final row in pending) {
          modelBatch.insert('models', row);
        }
        await modelBatch.commit(noResult: true);

        // Fill only missing rows. Existing counts are protected by the primary key
        // and INSERT OR IGNORE, even when a newer catalogue is merged later.
        for (final type in ItemType.values) {
          final kindFilter = type == ItemType.lens ? "device_kind = 'PHONE'" : '1 = 1';
          await txn.execute('''
            INSERT OR IGNORE INTO stocks (model_id, item_type, count)
            SELECT id, ?, 0 FROM models WHERE $kindFilter
          ''', [type.key]);
        }
      }

      await txn.insert(
        'settings',
        {'key': 'catalog_version', 'value': catalogVersion},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final info = decoded['source'];
      if (info is Map<String, dynamic>) {
        await txn.insert(
          'settings',
          {'key': 'catalog_source', 'value': jsonEncode(info)},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static int? _parseYear(Object? value) {
    final year = int.tryParse(value?.toString() ?? '');
    if (year == null || year < 1980 || year > 2100) return null;
    return year;
  }

  static Future<void> _createZeroStocks(
    DatabaseExecutor txn,
    int modelId,
    DeviceKind kind,
  ) async {
    final types = kind == DeviceKind.tablet
        ? [ItemType.cover, ItemType.glass]
        : ItemType.values;
    for (final type in types) {
      await txn.insert('stocks', {
        'model_id': modelId,
        'item_type': type.key,
        'count': 0,
      });
    }
  }
}
