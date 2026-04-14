import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/widgets/app_shell.dart';
import '../features/users/presentation/user_list_page.dart';

class ReelBridgeApp extends ConsumerWidget {
  const ReelBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return MaterialApp(
      title: 'Reel Bridge',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: config.hasRequiredKeys
          ? const AppShell(child: UserListPage())
          : _MissingConfigPage(missingValues: config.missingValues),
    );
  }

  ThemeData _buildTheme() {
    const seed = Color(0xFF0F766E);
    const canvas = Color(0xFFF4EFE7);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: canvas,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF1E293B),
        displayColor: const Color(0xFF0F172A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: seed, width: 1.4),
        ),
      ),
    );
  }
}

class _MissingConfigPage extends StatelessWidget {
  const _MissingConfigPage({required this.missingValues});

  final List<String> missingValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Missing API configuration',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pass the missing values with dart defines before running the app.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      for (final value in missingValues)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('• $value'),
                        ),
                      const SizedBox(height: 16),
                      const SelectableText(
                        'flutter run '
                        '--dart-define=REQRES_API_KEY=... '
                        '--dart-define=REQRES_ENV=dev '
                        '--dart-define=OMDB_API_KEY=...',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
