import 'package:cover_stock/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('search normalization', () {
    test('ignores spaces, punctuation and case', () {
      expect(normalizeSearch('V 20'), 'v20');
      expect(normalizeSearch('VIVO-V_20'), 'vivov20');
      expect(normalizeSearch('Nothing Phone (1)'), 'nothingphone1');
      expect(normalizeSearch('Nothing Phone 1'), 'nothingphone1');
    });

    test('search matches model and brand together', () {
      final snapshot = AppSnapshot(
        brands: const [DeviceBrand(id: 1, name: 'Vivo')],
        models: const [
          DeviceModel(id: 10, brandId: 1, name: 'V20', stock: {}),
        ],
        groups: const [],
        threshold: 2,
        darkMode: false,
        wrongPairs: const {},
        pairOverrides: const {},
      );
      expect(snapshot.searchModels('v 20').single.name, 'V20');
      expect(snapshot.searchModels('vivo v20').single.id, 10);
    });
  });

  test('tablet exposes Cover and Glass, never Lens', () {
    const tablet = DeviceModel(
      id: 1,
      brandId: 1,
      name: 'Pad 9',
      deviceKind: DeviceKind.tablet,
      stock: {
        ItemType.cover: 2,
        ItemType.glass: 3,
      },
    );
    expect(tablet.availableTypes, [ItemType.cover, ItemType.glass]);
    expect(tablet.availableTypes.contains(ItemType.lens), isFalse);
  });

  test('offline search remains exact with a 20,000-model catalogue', () {
    final models = List<DeviceModel>.generate(
      20000,
      (index) => DeviceModel(
        id: index + 1,
        brandId: 1,
        name: 'Model $index',
        stock: const {},
      ),
      growable: false,
    );
    final snapshot = AppSnapshot(
      brands: const [DeviceBrand(id: 1, name: 'Honor')],
      models: models,
      groups: const [],
      threshold: 2,
      darkMode: false,
      wrongPairs: const {},
      pairOverrides: const {},
    );
    final result = snapshot.searchModels('honor model 19999');
    expect(result.length, 1);
    expect(result.single.name, 'Model 19999');
  });

  test('compatibility results are independent of inventory stock', () {
    const brands = [DeviceBrand(id: 1, name: 'Vivo')];
    const models = [
      DeviceModel(id: 1, brandId: 1, name: 'V20', stock: {ItemType.glass: 0}),
      DeviceModel(id: 2, brandId: 1, name: 'V20 SE', stock: {ItemType.glass: 0}),
      DeviceModel(id: 3, brandId: 1, name: 'Y73', stock: {ItemType.glass: 0}),
    ];
    final snapshot = AppSnapshot(
      brands: brands,
      models: models,
      groups: const [
        CompatibilityGroup(id: 1, type: ItemType.glass, label: 'Glass set', members: [
          CompatibilityMember(modelId: 1, confidence: FitConfidence.sure),
          CompatibilityMember(modelId: 2, confidence: FitConfidence.sure),
          CompatibilityMember(modelId: 3, confidence: FitConfidence.ninety),
        ]),
      ],
      threshold: 2,
      darkMode: false,
      wrongPairs: const {},
      pairOverrides: const {},
    );
    final alternatives = snapshot.alternativesFor(1, ItemType.glass);
    expect(alternatives.map((item) => item.model.name).toList(), ['V20 SE', 'Y73']);
    expect(alternatives.first.confidence, FitConfidence.sure);
    expect(alternatives.last.confidence, FitConfidence.ninety);
  });

  test('a wrong pair is never suggested', () {
    final snapshot = AppSnapshot(
      brands: const [DeviceBrand(id: 1, name: 'Vivo')],
      models: const [
        DeviceModel(id: 1, brandId: 1, name: 'V20', stock: {ItemType.lens: 0}),
        DeviceModel(id: 2, brandId: 1, name: 'V20 SE', stock: {ItemType.lens: 2}),
      ],
      groups: const [
        CompatibilityGroup(id: 1, type: ItemType.lens, label: 'Lens', members: [
          CompatibilityMember(modelId: 1, confidence: FitConfidence.sure),
          CompatibilityMember(modelId: 2, confidence: FitConfidence.sure),
        ]),
      ],
      threshold: 2,
      darkMode: false,
      wrongPairs: {pairKey(ItemType.lens, 1, 2)},
      pairOverrides: const {},
    );
    expect(snapshot.alternativesFor(1, ItemType.lens), isEmpty);
  });
}
