// ==========================================
// FILE: ./services/providers.dart
// ==========================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/timezone.dart';
import '../models/task.dart';
import '../models/anchor.dart';
import '../models/habit.dart';
import '../models/person.dart';
import '../models/user.dart';
import '../services/local_db.dart';
import '../services/sync.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────
// GNOTE — ALL PROVIDERS
// Dependency Injection refactor: Global singletons are now
// exposed via Providers to allow testing and mocking.
// ─────────────────────────────────────────────────────────────

const _uuid = Uuid();

final localDbProvider = Provider<LocalDb>((ref) => LocalDb.instance);
final syncServiceProvider =
    Provider<SyncService>((ref) => SyncService.instance);
final syncStatusProvider = StreamProvider<SyncStatusSnapshot>((ref) {
  final status = ref.watch(syncServiceProvider).status;
  final controller = StreamController<SyncStatusSnapshot>();

  void emit() => controller.add(status.value);

  status.addListener(emit);
  emit();

  ref.onDispose(() {
    status.removeListener(emit);
    controller.close();
  });

  return controller.stream;
});
final authServiceProvider =
    Provider<AuthService>((ref) => AuthService.instance);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._db) : super(_read(_db));

  final LocalDb _db;

  static ThemeMode _read(LocalDb db) {
    return switch (db.getThemeMode()) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _db.saveThemeMode(raw);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(localDbProvider));
});

// ─────────────────────────────────────────────────────────────
// AUTH ERROR CLASSIFIER
// ─────────────────────────────────────────────────────────────

String _authError(Object e, {required bool isSignUp}) {
  if (e is AuthException) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Check your inbox — confirm your email first.';
    }
    if (msg.contains('invalid email')) {
      return 'That email address is not valid.';
    }
    if (msg.contains('password should be')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('weak password')) {
      return 'Password is too weak. Add numbers or symbols.';
    }
    if (msg.contains('token has expired') || msg.contains('expired')) {
      return 'That code has expired. Please request a new one.';
    }
    if (msg.contains('invalid otp') || msg.contains('token')) {
      return 'Invalid code. Please check and try again.';
    }
    if (isSignUp) {
      if (msg.contains('already registered') ||
          msg.contains('already been registered') ||
          msg.contains('user already exists')) {
        return 'An account with that email already exists. Sign in instead.';
      }
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Too many attempts. Wait a moment and try again.';
    }
    return e.message;
  }

  final str = e.toString().toLowerCase();
  if (str.contains('socketexception') ||
      str.contains('connection refused') ||
      str.contains('network is unreachable') ||
      str.contains('failed host lookup') ||
      str.contains('no address associated') ||
      str.contains('connection timed out') ||
      str.contains('handshake') ||
      str.contains('clientexception')) {
    return 'No internet connection. Check your network and try again.';
  }

  if (str.contains('supabaseurl') ||
      str.contains('supabaseclient') ||
      str.contains('not initialized')) {
    return 'App is not configured. Contact support.';
  }

  return 'Something went wrong. Please try again.';
}

// ═════════════════════════════════════════════════════════════
// AUTH PROVIDER
// ═════════════════════════════════════════════════════════════

class AuthNotifier extends StateNotifier<AsyncValue<GUser?>> {
  final AuthService _auth;
  final LocalDb _db;
  final SyncService _sync;

  AuthNotifier(this._auth, this._db, this._sync)
      : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final user = _auth.currentUser;
    if (user == null) {
      state = const AsyncValue.data(null);
      return;
    }
    _loadProfileSafely();
  }

  Future<void> _loadProfileSafely() async {
    try {
      final profile = await _auth.fetchProfile();
      state = AsyncValue.data(profile);
    } catch (_) {
      final sessionUser = _auth.currentUser;
      if (sessionUser == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final fallback = GUser(
        id: sessionUser.id,
        email: sessionUser.email ?? '',
        displayName: sessionUser.userMetadata?['display_name'] as String? ?? '',
        timezone: deviceTimezone(),
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
      );
      state = AsyncValue.data(fallback);
    }
  }

  Future<String?> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _auth.signIn(email: email, password: password);
      if (user == null) {
        state = const AsyncValue.data(null);
        return 'Incorrect email or password.';
      }
      try {
        await _sync.pullAll();
      } catch (_) {}
      state = AsyncValue.data(user);
      return null;
    } catch (e) {
      state = const AsyncValue.data(null);
      return _authError(e, isSignUp: false);
    }
  }

  Future<String?> signUp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      final outcome = await _auth.signUp(
        email: email,
        password: password,
        displayName: name,
      );
      switch (outcome) {
        case SignUpSessionActive(:final user):
          try {
            await _sync.pullAll();
          } catch (_) {}
          state = AsyncValue.data(user);
          return null;

        case SignUpNeedsVerification(:final email):
          state = const AsyncValue.data(null);
          return 'VERIFY:$email';

        case SignUpFailed(:final message):
          state = const AsyncValue.data(null);
          return message;
      }
    } catch (e) {
      state = const AsyncValue.data(null);
      return _authError(e, isSignUp: true);
    }
  }

  Future<String?> verifyOTP(String email, String token) async {
    state = const AsyncValue.loading();
    try {
      final user = await _auth.verifyOTP(email: email, token: token);
      if (user == null) {
        state = const AsyncValue.data(null);
        return 'Verification failed. Please try again.';
      }

      try {
        await _sync.pullAll();
      } catch (_) {}
      state = AsyncValue.data(user);
      return null;
    } catch (e) {
      state = const AsyncValue.data(null);
      return _authError(e, isSignUp: false);
    }
  }

  Future<String?> resendOTP(String email) async {
    try {
      await _auth.resendOTP(email: email);
      return null;
    } catch (e) {
      return _authError(e, isSignUp: false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _db.clearAll();
    state = const AsyncValue.data(null);
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.updateDisplayName(name);
    await _loadProfileSafely();
  }

  Future<void> updateTimezone(String timezone) async {
    await _auth.updateTimezone(timezone);
    await _loadProfileSafely();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<GUser?>>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(localDbProvider),
    ref.watch(syncServiceProvider),
  );
});

final currentUserProvider = Provider<GUser?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});

// ═════════════════════════════════════════════════════════════
// ANCHOR PROVIDER
// ═════════════════════════════════════════════════════════════

class AnchorNotifier extends StateNotifier<GAnchor?> {
  final LocalDb _db;
  final SyncService _sync;

  AnchorNotifier(this._db, this._sync) : super(null) {
    _load();
  }

  void _load() {
    state = _db.getTodayAnchor();
  }

  Future<void> lockAnchor(String content, String userId) async {
    final anchor = GAnchor(
      id: _uuid.v4(),
      userId: userId,
      content: content.trim(),
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await _db.saveAnchor(anchor);
    try {
      await _sync.pushAnchor(anchor);
    } catch (_) {}
    state = anchor;
  }

  bool get hasAnchorToday => state != null && state!.isToday;
}

final anchorProvider = StateNotifierProvider<AnchorNotifier, GAnchor?>((ref) {
  return AnchorNotifier(
      ref.watch(localDbProvider), ref.watch(syncServiceProvider));
});

// ═════════════════════════════════════════════════════════════
// DAILY 3 PROVIDER
// ═════════════════════════════════════════════════════════════

class Daily3State {
  final List<GTask> tasks;
  final bool locked;

  const Daily3State({required this.tasks, required this.locked});
  bool get isFull => tasks.length >= 3;
  bool get allDone => tasks.isNotEmpty && tasks.every((t) => t.isDone);
  int get doneCount => tasks.where((t) => t.isDone).length;
}

class Daily3Notifier extends StateNotifier<Daily3State> {
  final LocalDb _db;
  final SyncService _sync;

  Daily3Notifier(this._db, this._sync)
      : super(const Daily3State(tasks: [], locked: false)) {
    _load();
  }

  void _load() {
    final tasks = _db.getTodayTasks();
    final locked = _isLockedTime() || tasks.length >= 3;
    state = Daily3State(tasks: tasks, locked: locked);
  }

  bool _isLockedTime() {
    return localNow().hour >= 9;
  }

  Future<String?> addTask({
    required String what,
    required String doneWhen,
    required DateTime by,
    required String category,
    required String userId,
  }) async {
    if (state.isFull) return 'Three tasks locked. Focus now.';
    if (state.locked) return 'Tasks locked after 9am.';

    final task = GTask(
      id: _uuid.v4(),
      userId: userId,
      what: what.trim(),
      doneWhen: doneWhen.trim(),
      by: by,
      category: category,
      isCapture: false,
      createdAt: DateTime.now(),
    );
    await _db.saveTask(task);
    try {
      await _sync.pushTask(task);
    } catch (_) {}
    _load();
    return null;
  }

  Future<void> toggleDone(String taskId) async {
    await _db.toggleTaskDone(taskId);
    final updated = _db
        .getTodayTasks()
        .firstWhere((t) => t.id == taskId, orElse: () => state.tasks.first);
    try {
      await _sync.pushTask(updated);
    } catch (_) {}
    _load();
  }
}

final daily3Provider =
    StateNotifierProvider<Daily3Notifier, Daily3State>((ref) {
  return Daily3Notifier(
      ref.watch(localDbProvider), ref.watch(syncServiceProvider));
});

// ═════════════════════════════════════════════════════════════
// CAPTURE PROVIDER
// ═════════════════════════════════════════════════════════════

class CaptureNotifier extends StateNotifier<List<GTask>> {
  final LocalDb _db;
  final SyncService _sync;

  CaptureNotifier(this._db, this._sync) : super([]) {
    _load();
  }

  void _load() {
    state = _db.getCaptureItems();
  }

  Future<void> addItem(String content, String userId) async {
    if (content.trim().isEmpty) return;
    final task = GTask(
      id: _uuid.v4(),
      userId: userId,
      what: content.trim(),
      doneWhen: '',
      by: DateTime.now().add(const Duration(days: 7)),
      category: 'other',
      isCapture: true,
      createdAt: DateTime.now(),
    );
    await _db.saveTask(task);
    try {
      await _sync.pushTask(task);
    } catch (_) {}
    _load();
  }

  Future<void> deleteItem(String taskId) async {
    await _db.deleteTask(taskId);
    try {
      await _sync.deleteTask(taskId);
    } catch (_) {}
    _load();
  }

  Future<void> restoreItem(GTask task) async {
    await _db.saveTask(task);
    try {
      await _sync.pushTask(task);
    } catch (_) {}
    _load();
  }

  Future<void> shareList() async {
    if (state.isEmpty) return;
    final text = state
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${e.value.what}')
        .join('\n');
    await Share.share('Gnote — Capture List\n\n$text');
  }
}

final captureProvider =
    StateNotifierProvider<CaptureNotifier, List<GTask>>((ref) {
  return CaptureNotifier(
      ref.watch(localDbProvider), ref.watch(syncServiceProvider));
});

// ═════════════════════════════════════════════════════════════
// HABIT PROVIDER
// ═════════════════════════════════════════════════════════════

class HabitNotifier extends StateNotifier<GHabit?> {
  final LocalDb _db;
  final SyncService _sync;

  HabitNotifier(this._db, this._sync) : super(null) {
    _load();
  }

  void _load() {
    state = _db.getActiveHabit();
  }

  Future<void> setHabit(String name, String userId) async {
    final habit = GHabit(
      id: _uuid.v4(),
      userId: userId,
      name: name.trim(),
      streak: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );
    await _db.saveHabit(habit);
    try {
      await _sync.pushHabit(habit);
    } catch (_) {}
    _load();
  }

  Future<void> markDone() async {
    if (state == null || state!.doneToday) return;
    await _db.markHabitDone(state!.id);
    final updated = _db.getActiveHabit();
    if (updated != null) {
      try {
        await _sync.pushHabit(updated);
      } catch (_) {}
    }
    _load();
  }
}

final habitProvider = StateNotifierProvider<HabitNotifier, GHabit?>((ref) {
  return HabitNotifier(
      ref.watch(localDbProvider), ref.watch(syncServiceProvider));
});

// ═════════════════════════════════════════════════════════════
// RESPONSIBILITY PROVIDER
// ═════════════════════════════════════════════════════════════

class ResponsibilityState {
  final List<GPerson> motivators;
  final List<GPerson> meditators;
  final GPerson? selectedMotivator;
  final GPerson? selectedMeditator;
  const ResponsibilityState({
    required this.motivators,
    required this.meditators,
    this.selectedMotivator,
    this.selectedMeditator,
  });
}

class ResponsibilityNotifier extends StateNotifier<ResponsibilityState> {
  final LocalDb _db;
  final SyncService _sync;

  ResponsibilityNotifier(this._db, this._sync)
      : super(const ResponsibilityState(motivators: [], meditators: [])) {
    _load();
  }

  void _load() {
    state = ResponsibilityState(
      motivators: _db.getMotivators(),
      meditators: _db.getMeditators(),
      selectedMotivator: state.selectedMotivator,
      selectedMeditator: state.selectedMeditator,
    );
  }

  Future<void> addPerson({
    required String name,
    required String whatsappNumber,
    required String role,
    required String messageTemplate,
    required String userId,
  }) async {
    final person = GPerson(
      id: _uuid.v4(),
      userId: userId,
      name: name.trim(),
      whatsappNumber: whatsappNumber.trim(),
      role: role,
      messageTemplate: messageTemplate.trim(),
      timesSelected: 0,
      createdAt: DateTime.now(),
    );
    await _db.savePerson(person);
    try {
      await _sync.pushPerson(person);
    } catch (_) {}
    _load();
  }

  Future<void> deletePerson(String personId) async {
    await _db.deletePerson(personId);
    try {
      await _sync.deletePerson(personId);
    } catch (_) {}
    _load();
  }

  void pickMotivator() {
    final pool = state.motivators.where((p) => !p.selectedToday).toList();
    final pick = pool.isNotEmpty
        ? (pool..shuffle()).first
        : ([...state.motivators]
              ..sort((a, b) => a.timesSelected.compareTo(b.timesSelected)))
            .firstOrNull;
    state = ResponsibilityState(
      motivators: state.motivators,
      meditators: state.meditators,
      selectedMotivator: pick,
      selectedMeditator: state.selectedMeditator,
    );
  }

  void pickMeditator() {
    final pool = state.meditators.where((p) => !p.selectedToday).toList();
    final pick = pool.isNotEmpty
        ? (pool..shuffle()).first
        : ([...state.meditators]
              ..sort((a, b) => a.timesSelected.compareTo(b.timesSelected)))
            .firstOrNull;
    state = ResponsibilityState(
      motivators: state.motivators,
      meditators: state.meditators,
      selectedMotivator: state.selectedMotivator,
      selectedMeditator: pick,
    );
  }

  Future<void> sendWhatsApp(GPerson person) async {
    final message = Uri.encodeComponent(person.resolvedMessage);
    final number = person.whatsappNumber.replaceAll(' ', '');
    final url = Uri.parse('https://wa.me/$number?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      await _db.markPersonSelected(person.id);
      try {
        await _sync.pushPerson(
          _db.getAllPeople().firstWhere((p) => p.id == person.id),
        );
      } catch (_) {}
      _load();
    }
  }
}

final responsibilityProvider =
    StateNotifierProvider<ResponsibilityNotifier, ResponsibilityState>((ref) {
  return ResponsibilityNotifier(
      ref.watch(localDbProvider), ref.watch(syncServiceProvider));
});
