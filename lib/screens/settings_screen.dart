import 'dart:convert';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import '../providers/app_controller.dart';
import '../widgets/common.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _modelSearch = TextEditingController();
  bool _showAllModels = false;

  @override
  void dispose() {
    _modelSearch.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (mounted) showAppMessage(context, success);
    } catch (error) {
      if (mounted) showAppMessage(context, error.toString(), error: true);
    }
  }

  Future<void> _addBrandDialog() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নতুন ব্র্যান্ড'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'ব্র্যান্ডের নাম')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('যোগ করুন')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    await _run(() => ref.read(appControllerProvider.notifier).addBrand(value), 'ব্র্যান্ড যোগ হয়েছে');
  }

  Future<void> _modelDialog(AppSnapshot snapshot, {DeviceModel? model}) async {
    final brandController = TextEditingController(
      text: model == null
          ? (snapshot.brands.isNotEmpty ? snapshot.brands.first.name : '')
          : snapshot.brandFor(model.brandId)?.name ?? '',
    );
    final modelController = TextEditingController(text: model?.name ?? '');
    final yearController = TextEditingController(text: model?.releaseYear?.toString() ?? '');
    var deviceKind = model?.deviceKind ?? DeviceKind.phone;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(model == null ? 'নতুন মডেল যোগ করুন' : 'মডেল সম্পাদনা'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: brandController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'ব্র্যান্ড',
                  helperText: 'নতুন ব্র্যান্ডের নামও লিখতে পারবেন',
                  suffixIcon: IconButton(tooltip: 'ব্র্যান্ড যোগ', onPressed: _addBrandDialog, icon: const Icon(Icons.add_circle_outline_rounded)),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 2, children: snapshot.brands.map((brand) => ActionChip(
                    label: Text(brand.name, style: const TextStyle(fontSize: 11)),
                    onPressed: () => setDialogState(() => brandController.text = brand.name),
                    visualDensity: VisualDensity.compact,
                  )).toList()),
              const SizedBox(height: 12),
              DropdownButtonFormField<DeviceKind>(
                initialValue: deviceKind,
                decoration: const InputDecoration(labelText: 'ডিভাইসের ধরন'),
                items: DeviceKind.values.map((kind) => DropdownMenuItem(value: kind, child: Text(kind.label))).toList(),
                onChanged: (value) => setDialogState(() => deviceKind = value ?? deviceKind),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: modelController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'মডেলের নাম'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'রিলিজ বছর (ঐচ্ছিক)', hintText: 'যেমন 2025'),
              ),
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('বাতিল')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'brand': brandController.text.trim(),
                'model': modelController.text.trim(),
                'deviceKind': deviceKind,
                'releaseYear': int.tryParse(yearController.text.trim()),
                'releaseYearInput': yearController.text.trim(),
              }),
              child: const Text('সেভ করুন'),
            ),
          ],
        ),
      ),
    );
    brandController.dispose();
    modelController.dispose();
    yearController.dispose();
    if (result == null) return;
    final typedYear = result['releaseYearInput'] as String;
    final parsedYear = result['releaseYear'] as int?;
    if (typedYear.isNotEmpty && (parsedYear == null || parsedYear < 1980 || parsedYear > 2100)) {
      if (mounted) showAppMessage(context, 'রিলিজ বছর 1980-2100 দিন, না হলে খালি রাখুন', error: true);
      return;
    }
    if (model != null && model.deviceKind == DeviceKind.phone && result['deviceKind'] == DeviceKind.tablet) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ফোনকে ট্যাব করবেন?'),
          content: const Text('Lens compatibility links সরানো হবে। আগের Lens stock মুছে ফেলা হবে না, তবে ট্যাব হিসেবে লুকানো থাকবে।'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('চালিয়ে যান')),
          ],
        ),
      );
      if (confirm != true) return;
    }
    await _run(() async {
      if (model == null) {
        await ref.read(appControllerProvider.notifier).addModel(
          brand: result['brand'] as String,
          model: result['model'] as String,
          deviceKind: result['deviceKind'] as DeviceKind,
          releaseYear: result['releaseYear'] as int?,
        );
      } else {
        await ref.read(appControllerProvider.notifier).updateModel(
          id: model.id,
          brand: result['brand'] as String,
          model: result['model'] as String,
          deviceKind: result['deviceKind'] as DeviceKind,
          releaseYear: result['releaseYear'] as int?,
        );
      }
    }, model == null ? 'মডেল যোগ হয়েছে' : 'মডেল আপডেট হয়েছে');
  }

  Future<void> _deleteModel(DeviceModel model) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('মডেল মুছে ফেলবেন?'),
        content: Text('${model.name}-এর সব স্টক ও compatibility group-এর membership মুছে যাবে। এই কাজ ফেরানো যাবে না। আগে Backup নিন।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('মুছে ফেলুন')),
        ],
      ),
    );
    if (confirm == true) {
      await _run(() => ref.read(appControllerProvider.notifier).deleteModel(model.id), 'মডেল মুছে ফেলা হয়েছে');
    }
  }

  Future<void> _groupDialog(AppSnapshot snapshot, {CompatibilityGroup? group}) async {
    final labelController = TextEditingController(text: group?.label ?? '');
    final evidenceController = TextEditingController(text: group?.evidenceUrls.join('\n') ?? '');
    final noteController = TextEditingController(text: group?.evidenceNote ?? '');
    final memberSearchController = TextEditingController();
    var type = group?.type ?? ItemType.glass;
    var confidence = group?.members.isNotEmpty == true
        ? group!.members.first.confidence
        : FitConfidence.ninety;
    final selected = <int>{...?group?.members.map((member) => member.modelId)};
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(group == null ? 'মিলের গ্রুপ' : 'গ্রুপ সম্পাদনা'),
          content: SizedBox(
            width: 440,
            height: MediaQuery.of(context).size.height * 0.72,
            child: Column(children: [
              TextField(controller: labelController, decoration: const InputDecoration(labelText: 'গ্রুপের নাম', hintText: 'যেমন: একই Glass part')),
              const SizedBox(height: 10),
              DropdownButtonFormField<ItemType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'পার্টের ধরন'),
                items: ItemType.values.map((item) => DropdownMenuItem(value: item, child: Text(item.label))).toList(),
                onChanged: (value) => setDialogState(() {
                  type = value ?? type;
                  if (type == ItemType.lens) {
                    selected.removeWhere((id) => snapshot.modelFor(id)?.deviceKind == DeviceKind.tablet);
                  }
                }),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<FitConfidence>(
                initialValue: confidence,
                decoration: const InputDecoration(labelText: 'শুরুর confidence'),
                items: const [
                  DropdownMenuItem(value: FitConfidence.ninety, child: Text('৯০% নিশ্চিত — আগে যাচাই করুন')),
                  DropdownMenuItem(value: FitConfidence.sure, child: Text('নিশ্চিত — বাস্তবে পরীক্ষা করা')),
                ],
                onChanged: (value) => setDialogState(() => confidence = value ?? confidence),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('${selected.length}টি মডেল বাছাই', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: memberSearchController,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(
                  hintText: 'মডেল খুঁজুন',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Builder(builder: (context) {
                  final needle = normalizeSearch(memberSearchController.text);
                  final candidates = snapshot.models.where((model) {
                    if (!model.availableTypes.contains(type)) return false;
                    final brand = snapshot.brandFor(model.brandId)?.name ?? '';
                    return needle.isEmpty || normalizeSearch('$brand ${model.name}').contains(needle);
                  }).toList();
                  return ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final model = candidates[index];
                      final brand = snapshot.brandFor(model.brandId)?.name ?? '';
                      final isSelected = selected.contains(model.id);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: isSelected,
                        title: Text(model.name),
                        subtitle: Text('$brand · ${model.deviceKind.label}'),
                        onChanged: (value) => setDialogState(() {
                          if (value == true) {
                            selected.add(model.id);
                          } else {
                            selected.remove(model.id);
                          }
                        }),
                      );
                    },
                  );
                }),
              ),
              TextField(
                controller: evidenceController,
                minLines: 1,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'প্রমাণের URL (প্রতি লাইনে একটি, ঐচ্ছিক)'),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: noteController,
                minLines: 1,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'কেন মিলবে / কীভাবে যাচাই হয়েছে'),
              ),
              const SizedBox(height: 5),
              const Text('শুধু একই পার্ট বাস্তবে ফিট হলে মডেলগুলো এক গ্রুপে রাখুন।', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('বাতিল')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'label': labelController.text.trim(),
                'type': type,
                'confidence': confidence,
                'models': selected.toList(),
                'evidenceUrls': evidenceController.text.split('\n').map((value) => value.trim()).where((value) => value.isNotEmpty).toList(),
                'evidenceNote': noteController.text.trim(),
              }),
              child: const Text('সেভ করুন'),
            ),
          ],
        ),
      ),
    );
    labelController.dispose();
    evidenceController.dispose();
    noteController.dispose();
    memberSearchController.dispose();
    if (result == null) return;
    await _run(() => ref.read(appControllerProvider.notifier).saveGroup(
          id: group?.id,
          label: result['label'] as String,
          type: result['type'] as ItemType,
          modelIds: result['models'] as List<int>,
          confidence: result['confidence'] as FitConfidence,
          evidenceUrls: result['evidenceUrls'] as List<String>,
          evidenceNote: result['evidenceNote'] as String,
        ), 'Compatibility group সেভ হয়েছে');
  }

  Future<void> _deleteGroup(CompatibilityGroup group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('গ্রুপ মুছে ফেলবেন?'),
        content: const Text('এই গ্রুপ থেকে আর বিকল্প মডেল দেখাবে না।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('মুছুন')),
        ],
      ),
    );
    if (confirm == true) {
      await _run(() => ref.read(appControllerProvider.notifier).deleteGroup(group.id), 'গ্রুপ মুছে ফেলা হয়েছে');
    }
  }

  Future<void> _backup() async {
    await _run(() async {
      final data = await ref.read(appControllerProvider.notifier).exportBackup();
      final directory = await Directory.systemTemp.createTemp('cover_stock_');
      final file = File('${directory.path}/cover_stock_backup.json');
      await file.writeAsString(data, flush: true);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        text: 'Cover Stock backup — নিরাপদে রেখে দিন।',
      ));
    }, 'Backup তৈরি হয়েছে');
  }

  Future<PlatformFile?> _pickFile(String extension) {
    // file_picker v13 uses pickFile() for a single file and no withData flag.
    return FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [extension],
    );
  }

  Future<String> _readPickedFile(PlatformFile file) async {
    final bytes = await file.readAsBytes();
    return utf8.decode(bytes, allowMalformed: false).replaceFirst('\uFEFF', '');
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Restore করবেন?'),
        content: const Text('Restore করলে এই ফোনের বর্তমান সব ডেটা Backup-এর ডেটা দিয়ে বদলে যাবে। আগে বর্তমান ডেটার Backup রাখুন।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('চালিয়ে যান')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final file = await _pickFile('json');
      if (file == null) return;
      final content = await _readPickedFile(file);
      await ref.read(appControllerProvider.notifier).restoreBackup(content);
      if (mounted) showAppMessage(context, 'Backup Restore সম্পন্ন হয়েছে');
    } catch (error) {
      if (mounted) showAppMessage(context, error.toString(), error: true);
    }
  }

  Future<void> _importCatalogUpdate() async {
    try {
      final file = await _pickFile('json');
      if (file == null) return;
      final content = await _readPickedFile(file);
      final added = await ref.read(appControllerProvider.notifier).importCatalogUpdate(content);
      if (mounted) showAppMessage(context, '$addedটি নতুন মডেল/গ্রুপ যোগ হয়েছে');
    } catch (error) {
      if (mounted) showAppMessage(context, error.toString(), error: true);
    }
  }

  Future<void> _importCsv() async {
    try {
      final file = await _pickFile('csv');
      if (file == null) return;
      final content = await _readPickedFile(file);
      final added = await ref.read(appControllerProvider.notifier).importCsv(content);
      if (mounted) showAppMessage(context, '$addedটি নতুন মডেল যোগ হয়েছে');
    } catch (error) {
      if (mounted) showAppMessage(context, error.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(appControllerProvider).value;
    if (snapshot == null) return const Center(child: CircularProgressIndicator());
    final query = normalizeSearch(_modelSearch.text);
    final models = snapshot.models.where((model) {
      if (!_showAllModels && query.isEmpty) return false;
      final brand = snapshot.brandFor(model.brandId)?.name ?? '';
      return normalizeSearch('$brand ${model.name}').contains(query);
    }).take(80).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          sectionTitle('মডেল পরিচালনা', trailing: '${snapshot.models.length}টি মডেল'),
          FilledButton.icon(
            onPressed: () => _modelDialog(snapshot),
            icon: const Icon(Icons.add_rounded),
            label: const Text('নতুন মডেল যোগ করুন'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _modelSearch,
            onChanged: (_) => setState(() => _showAllModels = true),
            decoration: InputDecoration(
              hintText: 'মডেল বা ব্র্যান্ড খুঁজে সম্পাদনা করুন',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  _modelSearch.clear();
                  setState(() => _showAllModels = false);
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
          if (models.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...models.map((model) => Card(
                  margin: const EdgeInsets.only(bottom: 5),
                  child: ListTile(
                    dense: true,
                    title: Text(model.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text([
                      snapshot.brandFor(model.brandId)?.name ?? '',
                      model.deviceKind.label,
                      if (model.releaseYear != null) model.releaseYear.toString(),
                    ].join(' · ')),
                    trailing: Wrap(spacing: 2, children: [
                      IconButton(tooltip: 'সম্পাদনা', onPressed: () => _modelDialog(snapshot, model: model), icon: const Icon(Icons.edit_outlined)),
                      IconButton(tooltip: 'মুছুন', onPressed: () => _deleteModel(model), icon: const Icon(Icons.delete_outline_rounded, color: Colors.red)),
                    ]),
                  ),
                )),
            if (models.length == 80)
              const Text('প্রথম ৮০টি ফলাফল দেখানো হচ্ছে। আরও নির্দিষ্ট করে খুঁজুন।', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
          sectionTitle('মিলের গ্রুপ', trailing: '${snapshot.groups.length}টি গ্রুপ'),
          OutlinedButton.icon(
            onPressed: () => _groupDialog(snapshot),
            icon: const Icon(Icons.add_rounded),
            label: const Text('নতুন মিলের গ্রুপ'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          if (snapshot.groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('এখনো কোনো compatibility group নেই। যাচাই করা একই পার্টের মডেলগুলো এক গ্রুপে যোগ করুন।',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            )
          else
            ...snapshot.groups.map((group) {
              final names = group.members.map((member) => snapshot.modelFor(member.modelId)?.name ?? '').where((name) => name.isNotEmpty).join(' · ');
              return Card(
                margin: const EdgeInsets.only(top: 7),
                child: ListTile(
                  title: Text(group.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${group.type.label} · $names', maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Wrap(spacing: 0, children: [
                    IconButton(tooltip: 'সম্পাদনা', onPressed: () => _groupDialog(snapshot, group: group), icon: const Icon(Icons.edit_outlined)),
                    IconButton(tooltip: 'মুছুন', onPressed: () => _deleteGroup(group), icon: const Icon(Icons.delete_outline_rounded, color: Colors.red)),
                  ]),
                ),
              );
            }),
          sectionTitle('কম স্টকের সীমা'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('কম স্টকের সীমা', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 3),
                  Text('এই সংখ্যা বা কম হলে অর্ডার লিস্টে দেখাবে', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ])),
                IconButton(
                  onPressed: snapshot.threshold > 0
                      ? () => _run(() => ref.read(appControllerProvider.notifier).setThreshold(snapshot.threshold - 1), 'সীমা আপডেট হয়েছে')
                      : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Text('${snapshot.threshold}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                IconButton(
                  onPressed: snapshot.threshold < 99
                      ? () => _run(() => ref.read(appControllerProvider.notifier).setThreshold(snapshot.threshold + 1), 'সীমা আপডেট হয়েছে')
                      : null,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ]),
            ),
          ),
          sectionTitle('ব্যাকআপ ও CSV'),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('JSON ব্যাকআপ তৈরি করুন', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('সব ডেটা JSON ফাইলে শেয়ার বা সেভ করুন'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _backup,
                minVerticalPadding: 10,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restore_rounded),
                title: const Text('JSON ব্যাকআপ ফিরিয়ে আনুন', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('আগের JSON Backup ফিরিয়ে আনুন'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _restore,
                minVerticalPadding: 10,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: const Text('AI Data Pack যোগ করুন', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('ChatGPT থেকে তৈরি JSON ফাইল import করুন; অ্যাপের ভিতরে AI বা Internet লাগে না'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _importCatalogUpdate,
                minVerticalPadding: 10,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.table_view_outlined),
                title: const Text('CSV ফাইল থেকে ডেটা যোগ করুন', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('bulk model, stock ও compatibility group যোগ করুন'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _importCsv,
                minVerticalPadding: 10,
              ),
            ]),
          ),
          sectionTitle('অ্যাপ'),
          Card(
            child: SwitchListTile(
              value: snapshot.darkMode,
              onChanged: (value) => _run(() => ref.read(appControllerProvider.notifier).setDarkMode(value), 'Theme বদলানো হয়েছে'),
              title: const Text('ডার্ক মোড', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('রাতের ব্যবহারের জন্য'),
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('মডেল ডেটার উৎস', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                '${snapshot.catalogSourceName} · ${snapshot.catalogLicense} · ${snapshot.catalogAttribution}. '
                '${snapshot.catalogNote.isEmpty ? 'মডেল তালিকা অসম্পূর্ণ হতে পারে; এটি accessory fit-এর প্রমাণ নয়.' : snapshot.catalogNote}',
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(16)),
            child: const Text(
              'Compatibility may be wrong. Always check before giving.\n\nবিকল্প মডেল দেওয়ার আগে ফোনের পার্ট মিলিয়ে নিন। ভুল compatibility বাদ দিলে সেটি আর দেখানো হবে না।',
              style: TextStyle(fontSize: 12, height: 1.45),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text('Cover Stock · Offline · v1.0.0', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11))),
        ],
      ),
    );
  }
}
