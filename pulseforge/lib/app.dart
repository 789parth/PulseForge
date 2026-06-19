import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class PulseForgeApp extends ConsumerWidget {
  const PulseForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingCompleteProvider);
    final isDark = ref.watch(themeModeProvider.select((s) => s.value ?? true));
    final router = ref.watch(routerProvider);

    ref.watch(seedDataProvider);

    return onboardingAsync.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const Scaffold(
          backgroundColor: Color(0xFF0A0A0A),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
          ),
        ),
      ),
      error: (_, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const Scaffold(
          backgroundColor: Color(0xFF0A0A0A),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Color(0xFFFF4C4C), size: 48),
                SizedBox(height: 16),
                Text(
                  'Failed to start app.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Please restart the application.',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (_) => MaterialApp.router(
        title: 'PulseForge',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        routerConfig: router,
        builder: (context, child) {
          SystemChrome.setSystemUIOverlayStyle(
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          );
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
