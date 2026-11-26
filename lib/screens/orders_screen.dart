import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../providers/app_controller.dart';
import '../widgets/common.dart';

class _OrderRow {
  const _OrderRow({
    required this.type,
    required this.label,
    required this.brandLabel,
    required this.stock,
    required this.models,
  });

  final ItemType type;
  final String label;
  final String brandLabel;
  final int stock;
  final List<String> models;
}

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  List<_OrderRow> _buildRows(AppSnapshot snapshot) {
    final rows = <_OrderRow>[];
    for (final type in ItemType.values) {
      final groupedModelIds = <int>{};
      for (final group in snapshot.groups.where((item) => item.type == type)) {
        final members = group.members
            .map((member) => snapshot.modelFor(member.modelId))
            .whereType<DeviceModel>()
            .where((model) => model.availableTypes.contains(type))
            .toList();
        if (members.isEmpty) continue;
        groupedModelIds.addAll(members.map((item) => item.id));
        final total = members.fold<int>(0, (sum, item) => sum + item.count(type));
        if (total <= snapshot.threshold) {
          final brands = members
              .map((item) => snapshot.brandFor(item.brandId)?.name ?? '')
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          rows.add(_OrderRow(
            type: type,
            label: group.label,
            brandLabel: brands.join(' + '),
            stock: total,
            models: members.map((item) => item.name).toList()..sort(),
          ));
        }
      }

      for (final model in snapshot.models) {
        if (groupedModelIds.contains(model.id) || !model.availableTypes.contains(type)) continue;
        final count = model.count(type);
        if (count <= snapshot.threshold) {
          rows.add(_OrderRow(
            type: type,
            label: model.name,
            brandLabel: snapshot.brandFor(model.brandId)?.name ?? 'অন্যান্য',
            stock: count,
            models: [model.name],
          ));
        }
      }
    }
    rows.sort((a, b) {
      final brand = a.brandLabel.toLowerCase().compareTo(b.brandLabel.toLowerCase());
      if (brand != 0) return brand;
      final type = a.type.index.compareTo(b.type.index);
      if (type != 0) return type;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return rows;
  }

  String _copyText(List<_OrderRow> rows, int threshold) {
    final buffer = StringBuffer()
      ..writeln('Cover Stock — অর্ডার লিস্ট')
      ..writeln('Low stock limit: $threshold')
      ..writeln();
    if (rows.isEmpty) return '$buffer\nএখন অর্ডার করার মতো কিছু নেই।';
    final byBrand = <String, List<_OrderRow>>{};
    for (final row in rows) {
      byBrand.putIfAbsent(row.brandLabel, () => []).add(row);
    }
    for (final entry in byBrand.entries) {
      buffer.writeln(entry.key);
      for (final row in entry.value) {
        final models = row.models.join(', ');
        buffer.writeln('- ${row.type.label}: ${row.label} ($models) — মোট স্টক ${row.stock}');
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(appControllerProvider).value;
    if (snapshot == null) return const Center(child: CircularProgressIndicator());
    final rows = _buildRows(snapshot);
    final byBrand = <String, List<_OrderRow>>{};
    for (final row in rows) {
      byBrand.putIfAbsent(row.brandLabel, () => []).add(row);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('অর্ডার লিস্ট'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonalIcon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _copyText(rows, snapshot.threshold)));
                if (context.mounted) showAppMessage(context, 'অর্ডার লিস্ট কপি হয়েছে');
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('কপি করুন'),
            ),
          ),
        ],
      ),
      body: rows.isEmpty
          ? emptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'এখন অর্ডার করার দরকার নেই',
              subtitle: 'সব মডেলের স্টক নির্ধারিত সীমার ওপরে আছে।',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 2),
                  child: Text(
                    'স্টক ${snapshot.threshold} বা তার কম হলে এখানে দেখাবে। একই compatibility group-এর স্টক একসাথে যোগ করা হয়।',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ),
                ...byBrand.entries.map((entry) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 10),
                          ...entry.value.map((row) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(row.type.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(row.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(row.models.join(' · '), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  ])),
                                  Text('${row.stock}', style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: stockColor(context, row.stock, snapshot.threshold),
                                  )),
                                ]),
                              )),
                        ]),
                      ),
                    )),
              ],
            ),
    );
  }
}
