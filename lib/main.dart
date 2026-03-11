// ==========================================
// FILE: ./main.dart
// ==========================================

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/task.dart';
import 'models/anchor.dart';
import 'models/habit.dart';
import 'models/person.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'services/notification_service.dart';
import 'services/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Local Database Init
  await Hive.initFlutter();
  Hive.registerAdapter(GTaskAdapter());
  Hive.registerAdapter(GAnchorAdapter());
  Hive.registerAdapter(GHabitAdapter());
  Hive.registerAdapter(GPersonAdapter());
  await Hive.openBox<GTask>(GBoxes.tasks);
  await Hive.openBox<GAnchor>(GBoxes.anchors);
  await Hive.openBox<GHabit>(GBoxes.habits);
  await Hive.openBox<GPerson>(GBoxes.people);
  await Hive.openBox<dynamic>(GBoxes.meta);
  await Hive.openBox<dynamic>(GBoxes.selections);

  // 2. Security: Compile-time injected secrets (No hardcoded keys)
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'CRITICAL: Supabase configuration missing. '
      'Run with: --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // 3. Notifications Init
  await NotificationService.init();
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationService.onActionReceived,
  );

  runApp(const ProviderScope(child: GnoteApp()));
}

class GnoteApp extends ConsumerStatefulWidget {
  const GnoteApp({super.key});
  @override
  ConsumerState<GnoteApp> createState() => _GnoteAppState();
}

class _GnoteAppState extends ConsumerState<GnoteApp>
    with WidgetsBindingObserver {
  DateTime _lastDate = DateTime.now();

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
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    final newDay = now.year != _lastDate.year ||
        now.month != _lastDate.month ||
        now.day != _lastDate.day;

    if (newDay) {
      _lastDate = now;
      ref.invalidate(anchorProvider);
      ref.invalidate(daily3Provider);
      ref.invalidate(habitProvider);
    }
    final route = NotificationService.consumePendingRoute();
    if (route != null && mounted) goRouter.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: GStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: GTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: goRouter,
    );
  }
}