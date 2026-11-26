import 'package:cover_stock/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the app has separate accessory categories', () {
    expect(ItemType.values, [ItemType.cover, ItemType.glass, ItemType.lens]);
  });

  test('tablets do not expose camera lens compatibility', () {
    const tablet = DeviceModel(
      id: 1,
      brandId: 1,
      name: 'Test Tablet',
      deviceKind: DeviceKind.tablet,
      stock: {},
    );
    expect(tablet.availableTypes, [ItemType.cover, ItemType.glass]);
  });
}
