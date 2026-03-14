// ==========================================
// FILE: ./main.dart
// ==========================================

import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/app_localizations.dart';
import 'models/task.dart';
import 'models/anchor.dart';
import 'models/habit.dart';
import 'models/person.dart';
import 'models/user.dart';
import 'core/constants.dart';
import 'core/timezone.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'services/notification_service.dart';
import 'services/providers.dart';
import 'services/sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Local Database Init
  await Hive.initFlutter();
  Hive.registerAdapter(GUserAdapter());
  Hive.registerAdapter(GTaskAdapter());
  Hive.registerAdapter(GAnchorAdapter());
  Hive.registerAdapter(GHabitAdapter());
  Hive.registerAdapter(GPersonAdapter());
  await Hive.openBox<GUser>(GBoxes.users);
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
  DateTime _lastDate = localNow();
  late final VoidCallback _realtimeListener;

  void _invalidateDayBoundProviders() {
    ref.invalidate(anchorProvider);
    ref.invalidate(daily3Provider);
    ref.invalidate(captureProvider);
    ref.invalidate(habitProvider);
    ref.invalidate(responsibilityProvider);
  }

  void _refreshFromCloudOnResume() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    unawaited(() async {
      await ref.read(syncServiceProvider).pullAll();
      if (!mounted) return;
      _invalidateDayBoundProviders();
    }());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _realtimeListener = () {
      if (!mounted) return;
      _invalidateDayBoundProviders();
      ref.invalidate(authProvider);
    };
    ref
        .read(syncServiceProvider)
        .realtimeRevision
        .addListener(_realtimeListener);
  }

  @override
  void dispose() {
    ref
        .read(syncServiceProvider)
        .realtimeRevision
        .removeListener(_realtimeListener);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      ref.read(syncServiceProvider).retryPendingInBackground();
      return;
    }

    if (state != AppLifecycleState.resumed) return;
    final now = localNow();
    final newDay = now.year != _lastDate.year ||
        now.month != _lastDate.month ||
        now.day != _lastDate.day;

    if (newDay) {
      _lastDate = now;
      _invalidateDayBoundProviders();
    }

    _refreshFromCloudOnResume();

    final route = NotificationService.consumePendingRoute();
    if (route != null && mounted) goRouter.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus =
        ref.watch(syncStatusProvider).valueOrNull ?? const SyncStatusSnapshot();
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      theme: GTheme.light,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      darkTheme: GTheme.dark,
      themeMode: themeMode,
      routerConfig: goRouter,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            _SyncBanner(
              status: syncStatus,
              onRetry: () => ref.read(syncServiceProvider).retryPending(),
            ),
          ],
        );
      },
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({
    required this.status,
    required this.onRetry,
  });

  final SyncStatusSnapshot status;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (status.phase == SyncPhase.idle || status.pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final isError = status.phase == SyncPhase.error;
    final label = isError
        ? l10n.syncFailed(status.pendingCount)
        : l10n.syncPendingWithCount(status.pendingCount);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Material(
          color: isError ? GColors.dangerDim : GColors.azureDim,
          child: InkWell(
            onTap: isError ? () => onRetry() : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GSpacing.pagePadding,
                vertical: GSpacing.sm,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GText.muted.copyWith(
                  color: isError ? GColors.danger : GColors.azure,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
