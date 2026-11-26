import 'dart:collection';

enum ItemType { cover, glass, lens }

enum DeviceKind { phone, tablet }

enum FitConfidence { sure, ninety }

extension ItemTypeText on ItemType {
  String get key => name.toUpperCase();
  String get label => switch (this) {
        ItemType.cover => 'কভার',
        ItemType.glass => 'গ্লাস',
        ItemType.lens => 'লেন্স',
      };

  static ItemType parse(Object? value) {
    final text = value.toString().trim().toUpperCase();
    return ItemType.values.firstWhere(
      (item) => item.key == text,
      orElse: () => ItemType.cover,
    );
  }

  static ItemType parseStrict(String value) {
    final text = value.trim().toUpperCase();
    return ItemType.values.firstWhere(
      (item) => item.key == text,
      orElse: () => throw FormatException('item_type অবশ্যই COVER, GLASS বা LENS হবে: $value'),
    );
  }
}

extension DeviceKindText on DeviceKind {
  String get key => name.toUpperCase();
  String get label => this == DeviceKind.tablet ? 'ট্যাব' : 'ফোন';

  static DeviceKind parse(Object? value) =>
      value.toString().trim().toUpperCase() == 'TABLET'
          ? DeviceKind.tablet
          : DeviceKind.phone;

  static DeviceKind parseStrict(String value) => switch (value.trim().toUpperCase()) {
        'PHONE' => DeviceKind.phone,
        'TABLET' => DeviceKind.tablet,
        _ => throw FormatException('device_kind অবশ্যই PHONE বা TABLET হবে: $value'),
      };
}

extension FitConfidenceText on FitConfidence {
  String get key => name.toUpperCase();
  String get label => this == FitConfidence.sure ? 'নিশ্চিত' : '৯০% নিশ্চিত';

  static FitConfidence parse(Object? value) =>
      value.toString().toUpperCase() == 'SURE'
          ? FitConfidence.sure
          : FitConfidence.ninety;

  static FitConfidence parseStrict(String value) {
    return switch (value.trim().toUpperCase()) {
      'SURE' => FitConfidence.sure,
      'NINETY' => FitConfidence.ninety,
      _ => throw FormatException('confidence অবশ্যই SURE বা NINETY হবে: $value'),
    };
  }
}

class DeviceBrand {
  const DeviceBrand({required this.id, required this.name});

  final int id;
  final String name;
}

class DeviceModel {
  const DeviceModel({
    required this.id,
    required this.brandId,
    required this.name,
    required this.stock,
    this.deviceKind = DeviceKind.phone,
    this.releaseYear,
  });

  final int id;
  final int brandId;
  final String name;
  final Map<ItemType, int> stock;
  final DeviceKind deviceKind;
  final int? releaseYear;

  List<ItemType> get availableTypes => deviceKind == DeviceKind.tablet
      ? const [ItemType.cover, ItemType.glass]
      : ItemType.values;

  int count(ItemType type) => stock[type] ?? 0;
}

class CompatibilityMember {
  const CompatibilityMember({
    required this.modelId,
    required this.confidence,
  });

  final int modelId;
  final FitConfidence confidence;
}

class CompatibilityGroup {
  const CompatibilityGroup({
    required this.id,
    required this.type,
    required this.label,
    required this.members,
    this.evidenceUrls = const [],
    this.evidenceNote = '',
  });

  final int id;
  final ItemType type;
  final String label;
  final List<CompatibilityMember> members;
  final List<String> evidenceUrls;
  final String evidenceNote;
}

class CompatibilitySuggestion {
  const CompatibilitySuggestion({
    required this.model,
    required this.brandName,
    required this.count,
    required this.confidence,
    required this.groupLabel,
  });

  final DeviceModel model;
  final String brandName;
  final int count;
  final FitConfidence confidence;
  final String groupLabel;
}

String pairKey(ItemType type, int firstId, int secondId) {
  final low = firstId < secondId ? firstId : secondId;
  final high = firstId < secondId ? secondId : firstId;
  return '${type.key}:$low:$high';
}

String normalizeSearch(String input) =>
    input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

class AppSnapshot {
  AppSnapshot({
    required this.brands,
    required this.models,
    required this.groups,
    required this.threshold,
    required this.darkMode,
    required this.wrongPairs,
    required this.pairOverrides,
    this.catalogSourceName = 'Starter list',
    this.catalogLicense = 'N/A',
    this.catalogAttribution = 'Cover Stock starter list',
    this.catalogNote = '',
  })  : _brandById = {for (final item in brands) item.id: item},
        _modelById = {for (final item in models) item.id: item};

  final List<DeviceBrand> brands;
  final List<DeviceModel> models;
  final List<CompatibilityGroup> groups;
  final int threshold;
  final bool darkMode;
  final Set<String> wrongPairs;
  final Map<String, FitConfidence> pairOverrides;
  final String catalogSourceName;
  final String catalogLicense;
  final String catalogAttribution;
  final String catalogNote;
  final Map<int, DeviceBrand> _brandById;
  final Map<int, DeviceModel> _modelById;

  DeviceBrand? brandFor(int brandId) => _brandById[brandId];
  DeviceModel? modelFor(int modelId) => _modelById[modelId];

  List<DeviceModel> searchModels(String query) {
    final needle = normalizeSearch(query.trim());
    if (needle.isEmpty) return const [];
    final matches = <({DeviceModel model, int rank})>[];
    for (final model in models) {
      final brand = brandFor(model.brandId)?.name ?? '';
      final modelKey = normalizeSearch(model.name);
      final joined = normalizeSearch('$brand ${model.name}');
      if (modelKey == needle) {
        matches.add((model: model, rank: 0));
      } else if (joined == needle) {
        matches.add((model: model, rank: 1));
      } else if (modelKey.startsWith(needle)) {
        matches.add((model: model, rank: 2));
      } else if (modelKey.contains(needle)) {
        matches.add((model: model, rank: 3));
      } else if (joined.contains(needle)) {
        matches.add((model: model, rank: 4));
      }
    }
    matches.sort((a, b) {
      final rank = a.rank.compareTo(b.rank);
      if (rank != 0) return rank;
      final brand = (brandFor(a.model.brandId)?.name ?? '').compareTo(
        brandFor(b.model.brandId)?.name ?? '',
      );
      if (brand != 0) return brand;
      return a.model.name.compareTo(b.model.name);
    });
    return matches.map((entry) => entry.model).toList(growable: false);
  }

  List<CompatibilitySuggestion> alternativesFor(
    int sourceModelId,
    ItemType type,
  ) {
    final source = modelFor(sourceModelId);
    if (source == null) return const [];
    final found = <int, CompatibilitySuggestion>{};

    for (final group in groups.where((item) => item.type == type)) {
      final sourceMember = group.members.where((m) => m.modelId == sourceModelId);
      if (sourceMember.isEmpty) continue;
      for (final member in group.members) {
        if (member.modelId == sourceModelId) continue;
        final other = modelFor(member.modelId);
        if (other == null) continue;
        final key = pairKey(type, sourceModelId, member.modelId);
        if (wrongPairs.contains(key)) continue;

        final override = pairOverrides[key];
        final baseSure = sourceMember.first.confidence == FitConfidence.sure &&
            member.confidence == FitConfidence.sure;
        final confidence = override ??
            (baseSure ? FitConfidence.sure : FitConfidence.ninety);
        final brandName = brandFor(other.brandId)?.name ?? 'Unknown';
        final suggestion = CompatibilitySuggestion(
          model: other,
          brandName: brandName,
          count: other.count(type),
          confidence: confidence,
          groupLabel: group.label,
        );
        final previous = found[other.id];
        if (previous == null ||
            (previous.confidence == FitConfidence.ninety &&
                confidence == FitConfidence.sure)) {
          found[other.id] = suggestion;
        }
      }
    }

    final result = found.values.toList();
    result.sort((a, b) {
      final rank = a.confidence.index.compareTo(b.confidence.index);
      if (rank != 0) return rank;
      return a.model.name.toLowerCase().compareTo(b.model.name.toLowerCase());
    });
    return result;
  }

  List<DeviceModel> modelsForBrand(int brandId) =>
      UnmodifiableListView(models.where((item) => item.brandId == brandId).toList());
}
