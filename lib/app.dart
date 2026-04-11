import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/network/sync_service.dart';

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class TcomApp extends ConsumerStatefulWidget {
  const TcomApp({super.key});

  @override
  ConsumerState<TcomApp> createState() => _TcomAppState();
}

class _TcomAppState extends ConsumerState<TcomApp> with WidgetsBindingObserver {
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final elapsed = DateTime.now().difference(_pausedTime!);
        if (elapsed.inSeconds > 60) {
          // Force biometric re-verification loop
          ref.read(appRouterProvider).go('/auth');
        }
      }
      _pausedTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep sync service alive globally to listen for connectivity drops/restores
    ref.watch(syncServiceProvider);
    
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Med+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.tacticalDarkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
