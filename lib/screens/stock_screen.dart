import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../providers/app_controller.dart';
import '../widgets/common.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

enum _StockFilter { all, low, out }

class _StockScreenState extends ConsumerState<StockScreen> {
  final _search = TextEditingController();
  _StockFilter _filter = _StockFilter.all;
  int? _selectedBrandId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(DeviceModel model, AppSnapshot snapshot) {
    if (_selectedBrandId != null && model.brandId != _selectedBrandId) return false;
    final query = normalizeSearch(_search.text);
    final brand = snapshot.brandFor(model.brandId)?.name ?? '';
    final textMatches = query.isEmpty || normalizeSearch('$brand ${model.name}').contains(query);
    if (!textMatches) return false;
    final counts = model.availableTypes.map(model.count);
    return switch (_filter) {
      _StockFilter.all => true,
      _StockFilter.low => counts.any((count) => count > 0 && count <= snapshot.threshold),
      _StockFilter.out => counts.any((count) => count == 0),
    };
  }

  Future<void> _change(int modelId, ItemType type, int delta) async {
    try {
      await ref.read(appControllerProvider.notifier).changeStock(modelId, type, delta);
      if (delta < 0 && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: const Text('১টি স্টক কমানো হয়েছে'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                ref.read(appControllerProvider.notifier).changeStock(modelId, type, 1);
              },
            ),
          ));
      }
    } catch (error) {
      if (mounted) showAppMessage(context, error.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(appControllerProvider).value;
    if (snapshot == null) return const Center(child: CircularProgressIndicator());
    final matching = snapshot.models.where((model) => _matches(model, snapshot)).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('স্টক')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: DropdownButtonFormField<int?>(
            initialValue: _selectedBrandId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'ব্র্যান্ড বাছাই করুন',
              prefixIcon: Icon(Icons.phone_android_rounded),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('সব ব্র্যান্ড')),
              ...snapshot.brands.map((brand) => DropdownMenuItem<int?>(
                    value: brand.id,
                    child: Text(brand.name, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (value) => setState(() => _selectedBrandId = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ব্র্যান্ড বা মডেল খুঁজুন',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _filterChip('সব', _StockFilter.all),
            const SizedBox(width: 8),
            _filterChip('কম আছে', _StockFilter.low),
            const SizedBox(width: 8),
            _filterChip('শেষ', _StockFilter.out),
            const Spacer(),
            Text('${matching.length} মডেল', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: matching.isEmpty
              ? emptyState(icon: Icons.inventory_2_outlined, title: 'কোনো মডেল নেই', subtitle: 'ফিল্টার বদলান বা নতুন মডেল যোগ করুন।')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: matching.length,
                  itemBuilder: (context, index) {
                    final model = matching[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                        child: _ModelStockRow(
                          model: model,
                          brandName: snapshot.brandFor(model.brandId)?.name ?? '',
                          threshold: snapshot.threshold,
                          onChange: (type, delta) => _change(model.id, type, delta),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  Widget _filterChip(String label, _StockFilter filter) => ChoiceChip(
        label: Text(label),
        selected: _filter == filter,
        onSelected: (_) => setState(() => _filter = filter),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      );
}

class _ModelStockRow extends StatelessWidget {
  const _ModelStockRow({
    required this.model,
    required this.brandName,
    required this.threshold,
    required this.onChange,
  });

  final DeviceModel model;
  final String brandName;
  final int threshold;
  final void Function(ItemType type, int delta) onChange;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(model.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
        Text(model.deviceKind.label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        if (model.releaseYear != null) ...[
          const SizedBox(width: 6),
          Text(model.releaseYear.toString(), style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ]),
      if (brandName.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(brandName, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
      const SizedBox(height: 7),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: model.availableTypes.map((type) => SizedBox(
          width: 124,
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _MiniStockControl(
              type: type,
              count: model.count(type),
              threshold: threshold,
              onMinus: () => onChange(type, -1),
              onPlus: () => onChange(type, 1),
            ),
          ),
        )).toList()),
      ),
      const Divider(height: 14),
    ]);
  }
}

class _MiniStockControl extends StatelessWidget {
  const _MiniStockControl({
    required this.type,
    required this.count,
    required this.threshold,
    required this.onMinus,
    required this.onPlus,
  });

  final ItemType type;
  final int count;
  final int threshold;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final color = stockColor(context, count, threshold);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(children: [
        Text(type.label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
            padding: EdgeInsets.zero,
            onPressed: count > 0 ? onMinus : null,
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
            padding: EdgeInsets.zero,
            onPressed: onPlus,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          ),
        ]),
      ]),
    );
  }
}
