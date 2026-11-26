import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'providers/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _DatabaseBootstrap());
}

/// Show a Flutter splash while SQLite is created and the bundled catalogue merges.
class _DatabaseBootstrap extends StatefulWidget {
  const _DatabaseBootstrap();

  @override
  State<_DatabaseBootstrap> createState() => _DatabaseBootstrapState();
}

class _DatabaseBootstrapState extends State<_DatabaseBootstrap> {
  late final Future<AppDatabase> _databaseFuture = AppDatabase.open();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDatabase>(
      future: _databaseFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _DatabaseStartupError(error: snapshot.error.toString());
        }
        if (!snapshot.hasData) return const _DatabaseLoading();
        return ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(snapshot.data!),
          ],
          child: const CoverStockApp(),
        );
      },
    );
  }
}

class _DatabaseLoading extends StatelessWidget {
  const _DatabaseLoading();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF155E75)),
        ),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF155E75),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  const Text('Cover Stock', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('প্রথমবার মডেল তালিকা প্রস্তুত হচ্ছে', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  const SizedBox(width: 34, height: 3, child: LinearProgressIndicator()),
                ]),
              ),
            ),
          ),
        ),
      );
}

class _DatabaseStartupError extends StatelessWidget {
  const _DatabaseStartupError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.storage_rounded, size: 48),
                  const SizedBox(height: 14),
                  const Text('ডেটাবেস চালু করা যায়নি', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('অ্যাপটি বন্ধ করে আবার চালু করুন। সমস্যা থাকলে এই বার্তাটি দেখান।', textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                ]),
              ),
            ),
          ),
        ),
      );
}
