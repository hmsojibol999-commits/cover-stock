import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'models.dart';

class AppRepository {
  AppRepository(this.database);

  final AppDatabase database;
  Database get _db => database.db;

  Future<AppSnapshot> loadSnapshot() async {
    final brandRows = await _db.query('brands', orderBy: 'name COLLATE NOCASE');
    final modelRows = await _db.query('models', orderBy: 'name COLLATE NOCASE');
    final stockRows = await _db.query('stocks');
    final groupRows = await _db.query('compatibility_groups', orderBy: 'label COLLATE NOCASE');
    final memberRows = await _db.query('compatibility_members');
    final wrongRows = await _db.query('compatibility_wrong');
    final overrideRows = await _db.query('compatibility_pair_overrides');
    final settingRows = await _db.query('settings');

    final stockByModel = <int, Map<ItemType, int>>{};
    for (final row in stockRows) {
      final id = row['model_id'] as int;
      stockByModel.putIfAbsent(id, () => {});
      stockByModel[id]![ItemTypeText.parse(row['item_type'])] = row['count'] as int;
    }

    final models = modelRows.map((row) {
      final id = row['id'] as int;
      return DeviceModel(
        id: id,
        brandId: row['brand_id'] as int,
        name: row['name'] as String,
        deviceKind: DeviceKindText.parse(row['device_kind']),
        releaseYear: row['release_year'] as int?,
        stock: {
          for (final type in ItemType.values) type: stockByModel[id]?[type] ?? 0,
        },
      );
    }).toList(growable: false);

    final membersByGroup = <int, List<CompatibilityMember>>{};
    for (final row in memberRows) {
      final groupId = row['group_id'] as int;
      membersByGroup.putIfAbsent(groupId, () => []);
      membersByGroup[groupId]!.add(CompatibilityMember(
        modelId: row['model_id'] as int,
        confidence: FitConfidenceText.parse(row['confidence']),
      ));
    }

    final groups = groupRows.map((row) {
      final id = row['id'] as int;
      return CompatibilityGroup(
        id: id,
        type: ItemTypeText.parse(row['item_type']),
        label: row['label'] as String,
        members: membersByGroup[id] ?? const [],
        evidenceUrls: _decodeStringList(row['evidence_urls']),
        evidenceNote: row['evidence_note']?.toString() ?? '',
      );
    }).toList(growable: false);

    final settings = {for (final row in settingRows) row['key']: row['value']};
    var catalogSource = <String, dynamic>{};
    try {
      final decodedSource = jsonDecode(settings['catalog_source']?.toString() ?? '');
      if (decodedSource is Map<String, dynamic>) catalogSource = decodedSource;
    } catch (_) {
      // Older backups may not include model-catalog source metadata.
    }
    final wrongPairs = <String>{};
    for (final row in wrongRows) {
      final type = ItemTypeText.parse(row['item_type']);
      wrongPairs.add(pairKey(type, row['model_a'] as int, row['model_b'] as int));
    }
    final overrides = <String, FitConfidence>{};
    for (final row in overrideRows) {
      final type = ItemTypeText.parse(row['item_type']);
      overrides[pairKey(type, row['model_a'] as int, row['model_b'] as int)] =
          FitConfidenceText.parse(row['confidence']);
    }

    return AppSnapshot(
      brands: brandRows
          .map((row) => DeviceBrand(id: row['id'] as int, name: row['name'] as String))
          .toList(growable: false),
      models: models,
      groups: groups,
      threshold: int.tryParse(settings['threshold']?.toString() ?? '') ?? 2,
      darkMode: settings['dark_mode']?.toString() == 'true',
      wrongPairs: wrongPairs,
      pairOverrides: overrides,
      catalogSourceName: catalogSource['name']?.toString() ?? 'Starter list',
      catalogLicense: catalogSource['license']?.toString() ?? 'N/A',
      catalogAttribution: catalogSource['attribution']?.toString() ?? 'Cover Stock starter list',
      catalogNote: catalogSource['note']?.toString() ?? '',
    );
  }

  Future<void> addBrand(String name) async {
    await _db.transaction((txn) async { await _ensureBrand(txn, name); });
  }

  Future<int> _ensureBrand(Transaction txn, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) throw const FormatException('ব্র্যান্ডের নাম দিন');
    final found = await txn.query(
      'brands',
      where: 'name = ?',
      whereArgs: [clean],
      limit: 1,
    );
    if (found.isNotEmpty) return found.first['id'] as int;
    return txn.insert('brands', {'name': clean});
  }

  Future<int?> _findModelByNormalizedName(
    Transaction txn,
    int brandId,
    String modelName,
  ) async {
    final wanted = normalizeSearch(modelName);
    final rows = await txn.query(
      'models',
      columns: ['id', 'name'],
      where: 'brand_id = ?',
      whereArgs: [brandId],
    );
    for (final row in rows) {
      if (normalizeSearch(row['name'] as String) == wanted) {
        return row['id'] as int;
      }
    }
    return null;
  }

  Future<int> _ensureModel(
    Transaction txn,
    String brandName,
    String modelName, {
    DeviceKind deviceKind = DeviceKind.phone,
    int? releaseYear,
  }) async {
    final cleanModel = modelName.trim();
    if (cleanModel.isEmpty) throw const FormatException('মডেলের নাম দিন');
    final brandId = await _ensureBrand(txn, brandName);
    final foundId = await _findModelByNormalizedName(txn, brandId, cleanModel);
    if (foundId != null) {
      final found = await txn.query('models', where: 'id = ?', whereArgs: [foundId], limit: 1);
      final existingKind = DeviceKindText.parse(found.first['device_kind']);
      if (existingKind != deviceKind) {
        throw FormatException('$brandName $cleanModel আগে ${existingKind.label} হিসেবে আছে');
      }
      return foundId;
    }
    final modelId = await txn.insert('models', {
      'brand_id': brandId,
      'name': cleanModel,
      'device_kind': deviceKind.key,
      'release_year': releaseYear,
    });
    final types = deviceKind == DeviceKind.tablet
        ? [ItemType.cover, ItemType.glass]
        : ItemType.values;
    for (final type in types) {
      await txn.insert('stocks', {
        'model_id': modelId,
        'item_type': type.key,
        'count': 0,
      });
    }
    return modelId;
  }

  Future<int> addModel({
    required String brand,
    required String model,
    DeviceKind deviceKind = DeviceKind.phone,
    int? releaseYear,
  }) async {
    return _db.transaction((txn) async {
      final cleanModel = model.trim();
      if (cleanModel.isEmpty) throw const FormatException('মডেলের নাম দিন');
      final brandId = await _ensureBrand(txn, brand);
      final duplicateId = await _findModelByNormalizedName(txn, brandId, cleanModel);
      if (duplicateId != null) throw const FormatException('এই ব্র্যান্ডে একই মডেল আগে থেকেই আছে');
      return _ensureModel(
        txn, brand, cleanModel, deviceKind: deviceKind, releaseYear: releaseYear,
      );
    });
  }

  Future<void> updateModel({
    required int id,
    required String brand,
    required String model,
    DeviceKind deviceKind = DeviceKind.phone,
    int? releaseYear,
  }) async {
    final clean = model.trim();
    if (clean.isEmpty) throw const FormatException('মডেলের নাম দিন');
    await _db.transaction((txn) async {
      final brandId = await _ensureBrand(txn, brand);
      final rows = await txn.query(
        'models',
        columns: ['id', 'name'],
        where: 'brand_id = ?',
        whereArgs: [brandId],
      );
      final duplicate = rows.any((row) =>
          row['id'] != id && normalizeSearch(row['name'] as String) == normalizeSearch(clean));
      if (duplicate) throw const FormatException('এই ব্র্যান্ডে একই মডেল আগে থেকেই আছে');
      await txn.update('models', {
        'brand_id': brandId,
        'name': clean,
        'device_kind': deviceKind.key,
        'release_year': releaseYear,
      }, where: 'id = ?', whereArgs: [id]);
      if (deviceKind == DeviceKind.tablet) {
        // Keep any old Lens count hidden, not deleted, so a mistaken type edit never erases inventory.
        await txn.delete('compatibility_members', where: 'model_id = ? AND group_id IN (SELECT id FROM compatibility_groups WHERE item_type = ?)', whereArgs: [id, ItemType.lens.key]);
        await txn.delete('compatibility_groups', where: 'id IN (SELECT id FROM compatibility_groups WHERE id NOT IN (SELECT group_id FROM compatibility_members GROUP BY group_id HAVING COUNT(*) >= 2))');
      } else {
        await txn.insert('stocks', {'model_id': id, 'item_type': ItemType.lens.key, 'count': 0}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<void> deleteModel(int id) async {
    await _db.transaction((txn) async {
      await txn.delete('models', where: 'id = ?', whereArgs: [id]);
      await txn.delete(
        'compatibility_groups',
        where: 'id IN (SELECT group_id FROM compatibility_members GROUP BY group_id HAVING COUNT(*) < 2)',
      );
    });
  }

  Future<int> changeStock(int modelId, ItemType type, int delta) async {
    return _db.transaction((txn) async {
      final rows = await txn.query(
        'stocks',
        columns: ['count'],
        where: 'model_id = ? AND item_type = ?',
        whereArgs: [modelId, type.key],
        limit: 1,
      );
      final current = rows.isEmpty ? 0 : rows.first['count'] as int;
      final next = (current + delta).clamp(0, 999999).toInt();
      await txn.insert(
        'stocks',
        {'model_id': modelId, 'item_type': type.key, 'count': next},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return next;
    });
  }

  Future<void> setStock(int modelId, ItemType type, int count) async {
    await _db.insert(
      'stocks',
      {'model_id': modelId, 'item_type': type.key, 'count': count.clamp(0, 999999).toInt()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setThreshold(int value) async {
    await _db.insert(
      'settings',
      {'key': 'threshold', 'value': value.clamp(0, 99).toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setDarkMode(bool value) async {
    await _db.insert(
      'settings',
      {'key': 'dark_mode', 'value': value.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> saveGroup({
    int? id,
    required String label,
    required ItemType type,
    required List<int> modelIds,
    required FitConfidence confidence,
    List<String> evidenceUrls = const [],
    String evidenceNote = '',
  }) async {
    final cleanLabel = label.trim();
    final uniqueIds = modelIds.toSet().toList();
    if (cleanLabel.isEmpty) throw const FormatException('গ্রুপের নাম দিন');
    if (uniqueIds.length < 2) throw const FormatException('কমপক্ষে ২টি মডেল বাছাই করুন');
    return _db.transaction((txn) async {
      final duplicateLabel = await txn.query(
        'compatibility_groups',
        where: 'item_type = ? AND label = ? AND id != ?',
        whereArgs: [type.key, cleanLabel, id ?? -1],
        limit: 1,
      );
      if (duplicateLabel.isNotEmpty) {
        throw const FormatException('এই নামের compatibility group আগে থেকেই আছে');
      }
      final modelRows = await txn.query(
        'models',
        columns: ['id', 'device_kind'],
        where: 'id IN (${List.filled(uniqueIds.length, '?').join(',')})',
        whereArgs: uniqueIds,
      );
      if (modelRows.length != uniqueIds.length) throw const FormatException('কোনো মডেল পাওয়া যায়নি');
      if (type == ItemType.lens && modelRows.any((row) => DeviceKindText.parse(row['device_kind']) == DeviceKind.tablet)) {
        throw const FormatException('ট্যাবলেটের Lens compatibility group করা যাবে না');
      }
      final placeholders = List.filled(uniqueIds.length, '?').join(',');
      final wrongRows = await txn.query('compatibility_wrong', where: 'item_type = ?', whereArgs: [type.key]);
      final wrong = wrongRows.map((row) => pairKey(type, row['model_a'] as int, row['model_b'] as int)).toSet();
      for (var a = 0; a < uniqueIds.length; a++) {
        for (var b = a + 1; b < uniqueIds.length; b++) {
          if (wrong.contains(pairKey(type, uniqueIds[a], uniqueIds[b]))) {
            throw const FormatException('এই মডেল জোড়া আগে WRONG হিসেবে বাদ দেওয়া হয়েছে; নতুন গ্রুপে ফিরিয়ে আনা যাবে না।');
          }
        }
      }
      final occupied = await txn.rawQuery('''
        SELECT m.model_id, g.label FROM compatibility_members m
        JOIN compatibility_groups g ON g.id = m.group_id
        WHERE g.item_type = ? AND m.model_id IN ($placeholders)
        AND (? IS NULL OR g.id != ?)
      ''', [type.key, ...uniqueIds, id, id]);
      if (occupied.isNotEmpty) {
        throw const FormatException('একই ধরনের পার্টের জন্য কোনো মডেল অন্য গ্রুপে আছে। আগে সেটি সরান।');
      }
      final groupId = id == null
          ? await txn.insert('compatibility_groups', {
              'item_type': type.key,
              'label': cleanLabel,
              'evidence_urls': jsonEncode(evidenceUrls),
              'evidence_note': evidenceNote.trim(),
            })
          : id;
      if (id != null) {
        await txn.update(
          'compatibility_groups',
          {
            'item_type': type.key,
            'label': cleanLabel,
            'evidence_urls': jsonEncode(evidenceUrls),
            'evidence_note': evidenceNote.trim(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await txn.delete('compatibility_members', where: 'group_id = ?', whereArgs: [id]);
      }
      for (final modelId in uniqueIds) {
        await txn.insert('compatibility_members', {
          'group_id': groupId,
          'model_id': modelId,
          'confidence': confidence.key,
        });
      }
      return groupId;
    });
  }

  Future<void> deleteGroup(int id) async {
    await _db.delete('compatibility_groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markPairSure(int sourceId, int otherId, ItemType type) async {
    final low = sourceId < otherId ? sourceId : otherId;
    final high = sourceId < otherId ? otherId : sourceId;
    await _db.insert(
      'compatibility_pair_overrides',
      {
        'item_type': type.key,
        'model_a': low,
        'model_b': high,
        'confidence': FitConfidence.sure.key,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markPairWrong(int sourceId, int otherId, ItemType type) async {
    final low = sourceId < otherId ? sourceId : otherId;
    final high = sourceId < otherId ? otherId : sourceId;
    await _db.transaction((txn) async {
      await txn.delete(
        'compatibility_pair_overrides',
        where: 'item_type = ? AND model_a = ? AND model_b = ?',
        whereArgs: [type.key, low, high],
      );
      await txn.insert(
        'compatibility_wrong',
        {'item_type': type.key, 'model_a': low, 'model_b': high},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
  }

  Future<String> exportBackup() async {
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in [
      'brands',
      'models',
      'stocks',
      'compatibility_groups',
      'compatibility_members',
      'compatibility_pair_overrides',
      'compatibility_wrong',
      'settings',
    ]) {
      tables[table] = await _db.query(table);
    }
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'Cover Stock',
      'schemaVersion': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': tables,
    });
  }

  Future<void> restoreBackup(String source) async {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        decoded['app'] != 'Cover Stock' ||
        !(decoded['schemaVersion'] == 1 || decoded['schemaVersion'] == 2) ||
        decoded['tables'] is! Map<String, dynamic>) {
      throw const FormatException('এই Backup ফাইলটি সঠিক Cover Stock ফাইল নয়');
    }
    final tables = decoded['tables'] as Map<String, dynamic>;
    const names = [
      'brands',
      'models',
      'stocks',
      'compatibility_groups',
      'compatibility_members',
      'compatibility_pair_overrides',
      'compatibility_wrong',
      'settings',
    ];
    for (final name in names) {
      if (tables[name] is! List) throw FormatException('Backup-এ $name নেই');
    }

    await _db.transaction((txn) async {
      for (final table in [
        'compatibility_wrong',
        'compatibility_pair_overrides',
        'compatibility_members',
        'compatibility_groups',
        'stocks',
        'models',
        'brands',
        'settings',
      ]) {
        await txn.delete(table);
      }
      for (final table in names) {
        final rows = tables[table] as List<dynamic>;
        for (final row in rows) {
          if (row is! Map<String, dynamic>) throw FormatException('Backup-এ $table row ভুল');
          await txn.insert(table, row);
        }
      }
      final threshold = await txn.query('settings', where: 'key = ?', whereArgs: ['threshold']);
      if (threshold.isEmpty) await txn.insert('settings', {'key': 'threshold', 'value': '2'});
      final dark = await txn.query('settings', where: 'key = ?', whereArgs: ['dark_mode']);
      if (dark.isEmpty) await txn.insert('settings', {'key': 'dark_mode', 'value': 'false'});
    });
    // Older backups may not contain models from the current bundled catalogue.
    // Merge them after restore without overwriting stock or compatibility data.
    await database.mergeBundledCatalog();
  }


  static List<String> _decodeStringList(Object? raw) {
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is List) {
        return decoded.map((value) => value.toString().trim()).where((value) => value.isNotEmpty).toList();
      }
    } catch (_) {
      // Malformed metadata must not hide the owner's stock.
    }
    return const [];
  }

  static String _hostOf(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty || !['http', 'https'].contains(uri.scheme)) {
      throw FormatException('Evidence URL সঠিক নয়: $url');
    }
    return uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  }

  Future<int> importCatalogUpdate(String source) async {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> || !(decoded['schemaVersion'] == 1 || decoded['schemaVersion'] == 2) ||
        decoded['models'] is! List || decoded['compatibilityGroups'] is! List) {
      throw const FormatException('Data Pack ফাইলের schema সঠিক নয়');
    }

    final modelItems = decoded['models'] as List<dynamic>;
    final groupItems = decoded['compatibilityGroups'] as List<dynamic>;
    var addedModels = 0;
    var addedGroups = 0;

    await _db.transaction((txn) async {
      for (var i = 0; i < modelItems.length; i++) {
        final item = modelItems[i];
        if (item is! Map<String, dynamic>) throw FormatException('models[$i] সঠিক object নয়');
        final brand = item['brand']?.toString().trim() ?? '';
        final name = item['name']?.toString().trim() ?? '';
        if (brand.isEmpty || name.isEmpty) throw FormatException('models[$i]-এ brand/name লাগবে');
        final kind = DeviceKindText.parseStrict((item['deviceKind'] ?? item['device_kind'] ?? 'PHONE').toString());
        final yearRaw = item['releaseYear'] ?? item['release_year'];
        final year = yearRaw == null ? null : int.tryParse(yearRaw.toString());
        if (yearRaw != null && (year == null || year < 1980 || year > 2100)) {
          throw FormatException('models[$i]-এর releaseYear ভুল');
        }
        final brandId = await _ensureBrand(txn, brand);
        final existing = await _findModelByNormalizedName(txn, brandId, name);
        if (existing == null) {
          await _ensureModel(txn, brand, name, deviceKind: kind, releaseYear: year);
          addedModels++;
        } else {
          final rows = await txn.query('models', columns: ['device_kind'], where: 'id = ?', whereArgs: [existing], limit: 1);
          if (DeviceKindText.parse(rows.first['device_kind']) != kind) {
            throw FormatException('$brand $name-এর deviceKind আগের তথ্যের সঙ্গে মেলে না');
          }
        }
      }

      for (var i = 0; i < groupItems.length; i++) {
        final item = groupItems[i];
        if (item is! Map<String, dynamic>) throw FormatException('compatibilityGroups[$i] সঠিক object নয়');
        final typeRaw = item['itemType'] ?? item['item_type'] ?? '';
        final type = ItemTypeText.parseStrict(typeRaw.toString());
        final label = item['label']?.toString().trim() ?? '';
        if (label.isEmpty) throw FormatException('compatibilityGroups[$i]-এ label লাগবে');
        final confidence = FitConfidenceText.parseStrict(item['confidence']?.toString() ?? '');
        final urlsRaw = item['evidenceUrls'] ?? item['evidence_urls'];
        if (urlsRaw is! List || urlsRaw.isEmpty) throw FormatException('Compatibility \"$label\"-এর evidenceUrls দিতে হবে');
        final urls = urlsRaw.map((value) => value.toString().trim()).where((value) => value.isNotEmpty).toSet().toList();
        final hosts = urls.map(_hostOf).toSet();
        if (confidence == FitConfidence.sure && hosts.length < 2) {
          throw FormatException('SURE \"$label\"-এর জন্য অন্তত ২টি আলাদা source domain লাগবে');
        }
        if (confidence == FitConfidence.ninety && hosts.isEmpty) {
          throw FormatException('NINETY \"$label\"-এর জন্য অন্তত ১টি source লাগবে');
        }
        final note = item['evidenceNote']?.toString() ?? item['evidence_note']?.toString() ?? '';
        if (note.trim().length < 12) throw FormatException('\"$label\"-এর evidenceNote-এ যাচাইয়ের কারণ লিখুন');
        final membersRaw = item['members'];
        if (membersRaw is! List || membersRaw.length < 2) throw FormatException('\"$label\"-এ কমপক্ষে ২টি member লাগবে');

        final memberIds = <int>{};
        for (final member in membersRaw) {
          if (member is! Map<String, dynamic>) throw FormatException('\"$label\"-এর member ভুল');
          final brand = member['brand']?.toString().trim() ?? '';
          final model = member['model']?.toString().trim() ?? '';
          if (brand.isEmpty || model.isEmpty) throw FormatException('\"$label\"-এর member-এ brand/model লাগবে');
          final brandRows = await txn.query('brands', columns: ['id'], where: 'name = ? COLLATE NOCASE', whereArgs: [brand], limit: 1);
          if (brandRows.isEmpty) throw FormatException('\"$label\": Brand পাওয়া যায়নি: $brand');
          final modelId = await _findModelByNormalizedName(txn, brandRows.first['id'] as int, model);
          if (modelId == null) throw FormatException('\"$label\": Model আগে models তালিকায় যোগ করুন: $brand $model');
          final modelRows = await txn.query('models', columns: ['device_kind'], where: 'id = ?', whereArgs: [modelId], limit: 1);
          if (type == ItemType.lens && DeviceKindText.parse(modelRows.first['device_kind']) == DeviceKind.tablet) {
            throw FormatException('\"$label\": ট্যাবলেটের Lens link অনুমোদিত নয়');
          }
          memberIds.add(modelId);
        }
        if (memberIds.length < 2) throw FormatException('\"$label\"-এ ২টি আলাদা model লাগবে');

        final exists = await txn.query('compatibility_groups', where: 'item_type = ? AND label = ?', whereArgs: [type.key, label], limit: 1);
        if (exists.isNotEmpty) continue; // Re-importing the same pack is idempotent.

        final placeholders = List.filled(memberIds.length, '?').join(',');
        final occupied = await txn.rawQuery(
          'SELECT m.model_id FROM compatibility_members m JOIN compatibility_groups g ON g.id = m.group_id WHERE g.item_type = ? AND m.model_id IN ($placeholders)',
          [type.key, ...memberIds],
        );
        if (occupied.isNotEmpty) throw FormatException('\"$label\": কোনো model এই ধরনের অন্য compatibility group-এ আগে থেকেই আছে');

        final wrongRows = await txn.query('compatibility_wrong', where: 'item_type = ?', whereArgs: [type.key]);
        final wrong = wrongRows.map((row) => pairKey(type, row['model_a'] as int, row['model_b'] as int)).toSet();
        final ids = memberIds.toList();
        for (var a = 0; a < ids.length; a++) {
          for (var b = a + 1; b < ids.length; b++) {
            if (wrong.contains(pairKey(type, ids[a], ids[b]))) {
              throw FormatException('\"$label\": এই model pair আগে WRONG হিসেবে বাদ দেওয়া হয়েছে; Data Pack দিয়ে ফিরিয়ে আনা যাবে না');
            }
          }
        }

        final groupId = await txn.insert('compatibility_groups', {
          'item_type': type.key,
          'label': label,
          'evidence_urls': jsonEncode(urls),
          'evidence_note': note.trim(),
        });
        for (final modelId in memberIds) {
          await txn.insert('compatibility_members', {
            'group_id': groupId,
            'model_id': modelId,
            'confidence': confidence.key,
          });
        }
        addedGroups++;
      }
    });
    return addedModels + addedGroups;
  }

  Future<int> importCsv(String csvText) async {
    final rows = const CsvToListConverter(eol: '\n').convert(csvText);
    if (rows.length < 2) throw const FormatException('CSV-তে কোনো ডেটা পাওয়া যায়নি');
    final headers = rows.first
        .map((value) => value.toString().trim().toLowerCase())
        .toList(growable: false);
    final brandColumn = headers.indexOf('brand');
    final modelColumn = headers.indexOf('model');
    if (brandColumn < 0 || modelColumn < 0) {
      throw const FormatException('CSV header-এ brand ও model থাকতে হবে');
    }
    final typeColumn = headers.indexOf('item_type');
    final stockColumn = headers.indexOf('stock');
    final groupColumn = headers.indexOf('group_name');
    final confidenceColumn = headers.indexOf('confidence');
    final kindColumn = headers.indexOf('device_kind');
    final yearColumn = headers.indexOf('release_year');
    final groupRows = <String, Map<String, dynamic>>{};
    var addedModels = 0;

    await _db.transaction((txn) async {
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.every((value) => value.toString().trim().isEmpty)) continue;
        String cell(int column) => column < 0 || column >= row.length
            ? ''
            : row[column].toString().trim();
        final brand = cell(brandColumn);
        final model = cell(modelColumn);
        if (brand.isEmpty || model.isEmpty) {
          throw FormatException('CSV row ${i + 1}: brand/model খালি');
        }
        final kind = kindColumn >= 0 && cell(kindColumn).isNotEmpty
            ? DeviceKindText.parseStrict(cell(kindColumn))
            : DeviceKind.phone;
        final year = yearColumn >= 0 && cell(yearColumn).isNotEmpty
            ? int.tryParse(cell(yearColumn))
            : null;
        if (yearColumn >= 0 && cell(yearColumn).isNotEmpty && (year == null || year < 1980 || year > 2100)) {
          throw FormatException('CSV row ${i + 1}: release_year 1980-2100 হতে হবে');
        }
        final brandId = await _ensureBrand(txn, brand);
        final beforeId = await _findModelByNormalizedName(txn, brandId, model);
        final modelId = await _ensureModel(txn, brand, model, deviceKind: kind, releaseYear: year);
        if (beforeId == null) addedModels++;

        if (stockColumn >= 0 && cell(stockColumn).isNotEmpty) {
          final count = int.tryParse(cell(stockColumn));
          if (count == null || count < 0) {
            throw FormatException('CSV row ${i + 1}: stock ০ বা তার বেশি সংখ্যা হতে হবে');
          }
          final itemType = typeColumn >= 0 && cell(typeColumn).isNotEmpty
              ? ItemTypeText.parseStrict(cell(typeColumn))
              : ItemType.cover;
          if (itemType == ItemType.lens && kind == DeviceKind.tablet) {
            throw FormatException('CSV row ${i + 1}: ট্যাবলেটের Lens stock দেওয়া যাবে না');
          }
          await txn.insert(
            'stocks',
            {'model_id': modelId, 'item_type': itemType.key, 'count': count},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        final groupName = cell(groupColumn);
        if (groupName.isNotEmpty) {
          if (typeColumn < 0 || cell(typeColumn).isEmpty) {
            throw FormatException('CSV row ${i + 1}: group_name দিলে item_type দিতে হবে');
          }
          final type = ItemTypeText.parseStrict(cell(typeColumn));
          if (type == ItemType.lens && kind == DeviceKind.tablet) {
            throw FormatException('CSV row ${i + 1}: ট্যাবলেটকে Lens group-এ রাখা যাবে না');
          }
          final groupKey = '${type.key}:${groupName.toLowerCase()}';
          final confidence = FitConfidenceText.parseStrict(
            confidenceColumn >= 0 && cell(confidenceColumn).isNotEmpty
                ? cell(confidenceColumn)
                : 'NINETY',
          );
          final record = groupRows.putIfAbsent(groupKey, () => {
                'label': groupName,
                'type': type,
                'members': <int, FitConfidence>{},
              });
          (record['members'] as Map<int, FitConfidence>)[modelId] = confidence;
        }
      }

      for (final record in groupRows.values) {
        final members = record['members'] as Map<int, FitConfidence>;
        if (members.length < 2) {
          throw FormatException('Compatibility group ${record['label']} কমপক্ষে ২টি আলাদা মডেল চাই');
        }
        final type = record['type'] as ItemType;
        final label = record['label'] as String;
        final existing = await txn.query(
          'compatibility_groups',
          where: 'item_type = ? AND label = ?',
          whereArgs: [type.key, label],
          limit: 1,
        );
        final groupId = existing.isNotEmpty
            ? existing.first['id'] as int
            : await txn.insert('compatibility_groups', {
                'item_type': type.key,
                'label': label,
              });
        for (final entry in members.entries) {
          final occupied = await txn.rawQuery('''
            SELECT m.group_id FROM compatibility_members m
            JOIN compatibility_groups g ON g.id = m.group_id
            WHERE m.model_id = ? AND g.item_type = ? AND m.group_id != ?
          ''', [entry.key, type.key, groupId]);
          if (occupied.isNotEmpty) {
            throw FormatException('CSV compatibility group conflict: $label');
          }
          await txn.insert('compatibility_members', {
            'group_id': groupId,
            'model_id': entry.key,
            'confidence': entry.value.key,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
    return addedModels;
  }
}
