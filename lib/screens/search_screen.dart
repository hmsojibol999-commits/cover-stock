import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../providers/app_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(appControllerProvider).value;
    if (snapshot == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final query = _searchController.text;
    final selected =
        _selectedModelId == null ? null : snapshot.modelFor(_selectedModelId!);
    final matches = query.trim().isEmpty
        ? const <DeviceModel>[]
        : snapshot.searchModels(query);
    final results = matches.take(30).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('মিল যাচাই'),
        actions: [
          if (selected != null)
            IconButton(
              tooltip: 'অন্য মডেল খুঁজুন',
              onPressed: () {
                setState(() => _selectedModelId = null);
                _focusNode.requestFocus();
              },
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            const Text(
              'একটি মডেল লিখুন। তার COVER, GLASS ও LENS কোন কোন মডেলের সঙ্গে মেলে আলাদা করে দেখুন।',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() => _selectedModelId = null),
              decoration: InputDecoration(
                hintText: 'যেমন V20, Vivo V20 বা Galaxy S24',
                prefixIcon: const Icon(Icons.search_rounded, size: 26),
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
              const SizedBox(height: 18),
              const Text(
                'মডেল বাছাই করুন',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (results.isEmpty)
                const _EmptyState(
                  title: 'মডেল পাওয়া যায়নি',
                  message: 'অন্য বানানে বা সম্পূর্ণ ব্র্যান্ডসহ খুঁজুন।',
                )
              else
                ...results.map((model) {
                  final brand = snapshot.brandFor(model.brandId)?.name ?? '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        model.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text([
                        brand,
                        model.deviceKind.label,
                        if (model.releaseYear != null)
                          model.releaseYear.toString(),
                      ].join(' · ')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        setState(() => _selectedModelId = model.id);
                        _focusNode.unfocus();
                      },
                    ),
                  );
                }),
              if (matches.length > 30)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'আরও ফলাফল আছে — আরও নির্দিষ্ট করে লিখুন।',
                    textAlign: TextAlign.center,
                  ),
                ),
            ] else if (selected != null) ...[
              const SizedBox(height: 18),
              Text(
                snapshot.brandFor(selected.brandId)?.name ?? '',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                selected.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'প্রতিটি category আলাদা। একটির মিল অন্য category-তে প্রযোজ্য নয়।',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              ...selected.availableTypes.map((type) {
                final alternatives =
                    snapshot.alternativesFor(selected.id, type);
                return _CompatibilitySection(
                  type: type,
                  alternatives: alternatives,
                );
              }),
              const SizedBox(height: 8),
              const _Notice(),
            ] else ...[
              const SizedBox(height: 30),
              const _EmptyState(
                title: 'মডেল খুঁজুন',
                message:
                    'উদাহরণ: V20 লিখে Vivo V20 নির্বাচন করুন। তারপর COVER, GLASS ও LENS-এর আলাদা ফলাফল দেখুন।',
              ),
              const SizedBox(height: 12),
              const _Notice(),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompatibilitySection extends StatelessWidget {
  const _CompatibilitySection({
    required this.type,
    required this.alternatives,
  });

  final ItemType type;
  final List<CompatibilitySuggestion> alternatives;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    type.key,
                    style: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${alternatives.length}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (alternatives.isEmpty)
              Text(
                'এই category-র verified compatibility data এখনো পাওয়া যায়নি। কোনো মিল অনুমান করে দেখানো হচ্ছে না।',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              )
            else
              ...alternatives.map((suggestion) {
                final sure = suggestion.confidence == FitConfidence.sure;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    sure
                        ? Icons.verified_rounded
                        : Icons.fact_check_outlined,
                    color: sure
                        ? const Color(0xFF23864A)
                        : const Color(0xFFB77900),
                  ),
                  title: Text(
                    '${suggestion.brandName} ${suggestion.model.name}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    sure
                        ? '${suggestion.groupLabel} · verified source'
                        : '${suggestion.groupLabel} · সম্ভাব্য মিল, আগে glass/cutout মিলিয়ে নিন',
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_rounded, size: 34),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .secondaryContainer
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Compatibility data source-based, but may still be wrong. '
        'A model name or screen size alone does not prove a fit. '
        'Check the exact part, cutout and body shape before giving it to a customer.',
        style: TextStyle(fontSize: 12, height: 1.4),
      ),
    );
  }
}
