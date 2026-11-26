import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../providers/app_controller.dart';
import '../widgets/common.dart';
import '../widgets/stock_count_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  int? _selectedModelId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sell(int modelId, ItemType type) async {
    try {
      await ref.read(appControllerProvider.notifier).changeStock(modelId, type, -1);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('১টি স্টক কমানো হয়েছে'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              unawaited(ref.read(appControllerProvider.notifier).changeStock(modelId, type, 1));
            },
          ),
        ));
    } catch (error) {
      if (mounted) showAppMessage(context, error.toString(), error: true);
    }
  }

  Future<void> _add(int modelId, ItemType type) async {
    try {
      await ref.read(appControllerProvider.notifier).changeStock(modelId, type, 1);
    } catch (error) {
      if (mounted) showAppMessage(context, error.toString(), error: true);
    }
  }

  Future<void> _markSure(int sourceId, int otherId, ItemType type) async {
    try {
      await ref.read(appControllerProvider.notifier).markPairSure(sourceId, otherId, type);
      if (mounted) showAppMessage(context, 'এই মিলটি নিশ্চিত হিসেবে রাখা হয়েছে');
    } catch (error) {
      if (mounted) showAppMessage(context, error.toString(), error: true);
    }
  }

  Future<void> _markWrong(int sourceId, int otherId, ItemType type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('মিলটি ভুল?'),
        content: const Text('এই দুই মডেলের এই ধরনের পার্টের মিল স্থায়ীভাবে বাদ যাবে। পরে আর বিকল্পে দেখাবে না।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ফিরে যান')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('বাদ দিন')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(appControllerProvider.notifier).markPairWrong(sourceId, otherId, type);
      if (mounted) showAppMessage(context, 'এই মিলটি স্থায়ীভাবে বাদ দেওয়া হয়েছে');
    } catch (error) {
      if (mounted) showAppMessage(context, error.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(appControllerProvider).value;
    if (snapshot == null) return const Center(child: CircularProgressIndicator());
    final query = _searchController.text;
    final selected = _selectedModelId == null ? null : snapshot.modelFor(_selectedModelId!);
    final matches = query.trim().isEmpty ? const <DeviceModel>[] : snapshot.searchModels(query);
    final results = matches.take(18).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Cover Stock')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            TextField(
              controller: _searchController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() => _selectedModelId = null),
              decoration: InputDecoration(
                hintText: 'মডেল লিখুন — যেমন V20, Vivo V20',
                prefixIcon: const Icon(Icons.search_rounded, size: 27),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'মুছুন',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _selectedModelId = null);
                          _focusNode.requestFocus();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            if (selected == null && query.trim().isNotEmpty) ...[
              sectionTitle('মডেল বাছাই করুন'),
              if (results.isEmpty)
                emptyState(
                  icon: Icons.phone_android_rounded,
                  title: 'মডেল পাওয়া যায়নি',
                  subtitle: 'সেটিংস থেকে নতুন মডেল যোগ করুন।',
                )
              else
                ...results.map((model) {
                  final brand = snapshot.brandFor(model.brandId)?.name ?? '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      minVerticalPadding: 11,
                      title: Text(model.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      subtitle: Text([
                        brand,
                        model.deviceKind.label,
                        if (model.releaseYear != null) model.releaseYear.toString(),
                      ].join(' · ')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        setState(() => _selectedModelId = model.id);
                        _focusNode.unfocus();
                      },
                    ),
                  );
                }),
              if (matches.length > 18)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('আরও ফলাফল আছে — আরও নির্দিষ্ট করে লিখুন।', textAlign: TextAlign.center),
                ),
            ] else if (selected != null) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(snapshot.brandFor(selected.brandId)?.name ?? '',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(selected.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  ]),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedModelId = null),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('অন্য মডেল'),
                ),
              ]),
              const SizedBox(height: 8),
              ...selected.availableTypes.map((type) {
                final count = selected.count(type);
                final alternatives = count == 0 ? snapshot.alternativesFor(selected.id, type) : const <CompatibilitySuggestion>[];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    StockCountCard(
                      type: type,
                      count: count,
                      threshold: snapshot.threshold,
                      onSell: () => _sell(selected.id, type),
                      onAdd: () => _add(selected.id, type),
                    ),
                    if (count == 0) ...[
                      const SizedBox(height: 8),
                      Text('অন্য মডেলে মিল আছে?', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      if (alternatives.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text('কোনো নিশ্চিত বিকল্প যোগ করা নেই।', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        )
                      else
                        ...alternatives.map((suggestion) => _AlternativeTile(
                              suggestion: suggestion,
                              type: type,
                              onSell: () => _sell(suggestion.model.id, type),
                              onSure: () => _markSure(selected.id, suggestion.model.id, type),
                              onWrong: () => _markWrong(selected.id, suggestion.model.id, type),
                            )),
                    ],
                  ]),
                );
              }),
              const SizedBox(height: 4),
              const _CompatibilityNote(),
            ] else ...[
              const SizedBox(height: 30),
              emptyState(
                icon: Icons.manage_search_rounded,
                title: 'মডেল খুঁজুন',
                subtitle: 'কাস্টমার যে মডেল বলবে, এখানে লিখুন। যেমন V20 বা Vivo V20।',
              ),
              const _CompatibilityNote(),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlternativeTile extends StatelessWidget {
  const _AlternativeTile({
    required this.suggestion,
    required this.type,
    required this.onSell,
    required this.onSure,
    required this.onWrong,
  });

  final CompatibilitySuggestion suggestion;
  final ItemType type;
  final VoidCallback onSell;
  final VoidCallback onSure;
  final VoidCallback onWrong;

  @override
  Widget build(BuildContext context) {
    final sure = suggestion.confidence == FitConfidence.sure;
    final color = sure ? const Color(0xFF23864A) : const Color(0xFFB77900);
    return Card(
      margin: const EdgeInsets.only(top: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(sure ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: color),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${suggestion.brandName} ${suggestion.model.name}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                sure
                    ? 'নিশ্চিত মিল · স্টক ${suggestion.count}'
                    : '৯০% নিশ্চিত · দেওয়ার আগে মিলিয়ে নিন · স্টক ${suggestion.count}',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ])),
            FilledButton(
              onPressed: onSell,
              style: FilledButton.styleFrom(minimumSize: const Size(88, 52)),
              child: const Text('বিক্রি'),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            if (!sure)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSure,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Fit হলো'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF23864A), minimumSize: const Size(0, 52)),
                ),
              ),
            if (!sure) const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onWrong,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('ভুল'),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB3261E), minimumSize: const Size(0, 52)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _CompatibilityNote extends StatelessWidget {
  const _CompatibilityNote();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, size: 19),
          SizedBox(width: 8),
          Expanded(child: Text('Compatibility may be wrong. Always check before giving.', style: TextStyle(fontSize: 12))),
        ]),
      );
}
