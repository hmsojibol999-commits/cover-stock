import 'package:flutter_test/flutter_test.dart';
import 'package:cover_stock/data/models.dart';

AppSnapshot createTestSnapshot({
  List<CompatibilityGroup> groups = const [],
  Set<String> wrongPairs = const {},
  List<DeviceModel>? models,
}) {
  final testModels = models ?? [
    const DeviceModel(
      id: 1,
      brandId: 1,
      name: 'Galaxy S24 Ultra',
      stock: {
        ItemType.cover: 2,
        ItemType.glass: 3,
        ItemType.lens: 1,
      },
    ),
    const DeviceModel(
      id: 2,
      brandId: 1,
      name: 'Galaxy S24 Ultra 5G',
      stock: {
        ItemType.cover: 5,
        ItemType.glass: 4,
        ItemType.lens: 2,
      },
    ),
    const DeviceModel(
      id: 3,
      brandId: 1,
      name: 'Galaxy S24',
      stock: {
        ItemType.cover: 3,
        ItemType.glass: 2,
        ItemType.lens: 1,
      },
    ),
  ];

  return AppSnapshot(
    brands: const [
      DeviceBrand(id: 1, name: 'Samsung'),
    ],
    models: testModels,
    groups: groups,
    threshold: 2,
    darkMode: false,
    wrongPairs: wrongPairs,
    pairOverrides: const {},
  );
}

CompatibilityGroup createTestGroup() {
  return const CompatibilityGroup(
    id: 1,
    type: ItemType.cover,
    label: 'Verified Cover Group',
    members: [
      CompatibilityMember(
        modelId: 1,
        confidence: FitConfidence.sure,
      ),
      CompatibilityMember(
        modelId: 2,
        confidence: FitConfidence.sure,
      ),
    ],
  );
}

void main() {
  group('Offline model search', () {
    test('normalizes spaces, punctuation and uppercase letters', () {
      expect(
        normalizeSearch('Galaxy S24-Ultra'),
        'galaxys24ultra',
      );
    });

    test('ranks exact model matches before partial matches', () {
      final snapshot = createTestSnapshot();

      final results = snapshot.searchModels('GALAXY S24 ULTRA');

      expect(results, isNotEmpty);
      expect(results.first.id, 1);
      expect(results.first.name, 'Galaxy S24 Ultra');
    });
  });

  group('Compatibility safety', () {
    test('does not assume compatibility without a verified group', () {
      final snapshot = createTestSnapshot();

      expect(
        snapshot.alternativesFor(1, ItemType.cover),
        isEmpty,
      );
    });

    test('suggests models explicitly placed in the same group', () {
      final snapshot = createTestSnapshot(
        groups: [createTestGroup()],
      );

      final results = snapshot.alternativesFor(1, ItemType.cover);

      expect(results, hasLength(1));
      expect(results.single.model.id, 2);
      expect(results.single.confidence, FitConfidence.sure);
    });

    test('never suggests a pair marked as wrong', () {
      final snapshot = createTestSnapshot(
        groups: [createTestGroup()],
        wrongPairs: {
          pairKey(ItemType.cover, 1, 2),
        },
      );

      expect(
        snapshot.alternativesFor(1, ItemType.cover),
        isEmpty,
      );
    });

    test('does not suggest models with zero available stock', () {
      final models = [
        const DeviceModel(
          id: 1,
          brandId: 1,
          name: 'Galaxy S24 Ultra',
          stock: {ItemType.cover: 2},
        ),
        const DeviceModel(
          id: 2,
          brandId: 1,
          name: 'Galaxy S24 Ultra 5G',
          stock: {ItemType.cover: 0},
        ),
      ];

      final snapshot = createTestSnapshot(
        groups: [createTestGroup()],
        models: models,
      );

      expect(
        snapshot.alternativesFor(1, ItemType.cover),
        isEmpty,
      );
    });
  });
}
