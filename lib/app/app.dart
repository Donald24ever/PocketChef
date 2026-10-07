import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../state/app_state_provider.dart';
import '../state/domain_providers.dart';
import 'router.dart';

class PocketChefApp extends ConsumerWidget {
  const PocketChefApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Keeps the per-user data coordinator alive: it reloads the active
    // account's planner / shopping / favourites whenever the uid changes.
    ref.watch(userDataCoordinatorProvider);

    return MaterialApp.router(
      title: 'PocketChef',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
