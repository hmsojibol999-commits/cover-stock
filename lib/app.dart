import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/app_controller.dart';
import 'screens/orders_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stock_screen.dart';

const _seedColor = Color(0xFF155E75);

class CoverStockApp extends ConsumerWidget {
  const CoverStockApp({super.key});

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7FAFC)
          : const Color(0xFF101A20),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.light ? Colors.white : const Color(0xFF1B2A32),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light
            ? const Color(0xFFF7FAFC)
            : const Color(0xFF101A20),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1B2A32),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _seedColor, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: brightness == Brightness.light ? Colors.white : const Color(0xFF1B2A32),
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            )),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(appControllerProvider);
    final darkMode = snapshot.value?.darkMode ?? false;
    return MaterialApp(
      title: 'Cover Stock',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: snapshot.when(
        loading: () => const _LaunchScreen(),
        error: (error, stack) => _StartupError(error: error.toString()),
        data: (_) => const _HomeShell(),
      ),
    );
  }
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.inventory_2_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 18),
              const Text('Cover Stock', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                'প্রথমবার মডেল তালিকা প্রস্তুত হচ্ছে',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 12),
              const SizedBox(width: 30, height: 3, child: LinearProgressIndicator()),
            ],
          ),
        ),
      );
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.storage_rounded, size: 48),
              const SizedBox(height: 12),
              const Text('ডেটাবেস চালু করা যায়নি', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  final _pages = const [
    SearchScreen(),
    StockScreen(),
    OrdersScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.compare_arrows_rounded), label: 'মিল যাচাই'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'স্টক'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'অর্ডার'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'সেটিংস'),
        ],
      ),
    );
  }
}
