import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/app_repository.dart';
import '../data/models.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('AppDatabase must be provided before the app starts');
});

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository(ref.watch(appDatabaseProvider));
});

final appControllerProvider =
    AsyncNotifierProvider<AppController, AppSnapshot>(AppController.new);

class AppController extends AsyncNotifier<AppSnapshot> {
  AppRepository get _repository => ref.read(appRepositoryProvider);

  @override
  Future<AppSnapshot> build() => _repository.loadSnapshot();

  Future<void> _refresh() async {
    state = AsyncData(await _repository.loadSnapshot());
  }

  Future<int> changeStock(int modelId, ItemType type, int delta) async {
    final result = await _repository.changeStock(modelId, type, delta);
    await _refresh();
    return result;
  }

  Future<void> addBrand(String name) async {
    await _repository.addBrand(name);
    await _refresh();
  }

  Future<void> addModel({
    required String brand,
    required String model,
    DeviceKind deviceKind = DeviceKind.phone,
    int? releaseYear,
  }) async {
    await _repository.addModel(brand: brand, model: model, deviceKind: deviceKind, releaseYear: releaseYear);
    await _refresh();
  }

  Future<void> updateModel({
    required int id,
    required String brand,
    required String model,
    DeviceKind deviceKind = DeviceKind.phone,
    int? releaseYear,
  }) async {
    await _repository.updateModel(id: id, brand: brand, model: model, deviceKind: deviceKind, releaseYear: releaseYear);
    await _refresh();
  }

  Future<void> deleteModel(int id) async {
    await _repository.deleteModel(id);
    await _refresh();
  }

  Future<void> setThreshold(int value) async {
    await _repository.setThreshold(value);
    await _refresh();
  }

  Future<void> setDarkMode(bool value) async {
    await _repository.setDarkMode(value);
    await _refresh();
  }

  Future<void> saveGroup({
    int? id,
    required String label,
    required ItemType type,
    required List<int> modelIds,
    required FitConfidence confidence,
    List<String> evidenceUrls = const [],
    String evidenceNote = '',
  }) async {
    await _repository.saveGroup(
      id: id,
      label: label,
      type: type,
      modelIds: modelIds,
      confidence: confidence,
      evidenceUrls: evidenceUrls,
      evidenceNote: evidenceNote,
    );
    await _refresh();
  }

  Future<void> deleteGroup(int id) async {
    await _repository.deleteGroup(id);
    await _refresh();
  }

  Future<void> markPairSure(int sourceId, int otherId, ItemType type) async {
    await _repository.markPairSure(sourceId, otherId, type);
    await _refresh();
  }

  Future<void> markPairWrong(int sourceId, int otherId, ItemType type) async {
    await _repository.markPairWrong(sourceId, otherId, type);
    await _refresh();
  }

  Future<String> exportBackup() => _repository.exportBackup();

  Future<void> restoreBackup(String source) async {
    await _repository.restoreBackup(source);
    await _refresh();
  }

  Future<int> importCsv(String source) async {
    final count = await _repository.importCsv(source);
    await _refresh();
    return count;
  }

  Future<int> importCatalogUpdate(String source) async {
    final count = await _repository.importCatalogUpdate(source);
    await _refresh();
    return count;
  }
}
