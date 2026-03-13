import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/anchor.dart';
import '../models/habit.dart';
import '../models/person.dart';
import '../core/constants.dart';
import 'local_db.dart';

// ─────────────────────────────────────────────────────────────
// GNOTE — SYNC SERVICE
//
// Hive is always written first (instant, offline safe).
// This service pushes to Supabase and pulls on login.
//
// BUG FIX in _pull* methods: each row is now wrapped in try/catch.
// Original code called fromJson directly — one null column from
// Supabase killed the entire pull and wiped local state.
// Now: bad rows are silently skipped. Hive data from last session
// stays intact for any row that fails to parse.
// ─────────────────────────────────────────────────────────────

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _client = Supabase.instance.client;
  final _db = LocalDb.instance;
  final List<_PendingSyncOp> _pending = [];

  final ValueNotifier<SyncStatusSnapshot> status =
      ValueNotifier<SyncStatusSnapshot>(const SyncStatusSnapshot());

  String? get _userId => _client.auth.currentUser?.id;

  void _setStatus({
    SyncPhase? phase,
    String? error,
  }) {
    status.value = status.value.copyWith(
      phase: phase ?? status.value.phase,
      pendingCount: _pending.length,
      lastError: error,
      lastSyncedAt: (phase == SyncPhase.synced)
          ? DateTime.now()
          : status.value.lastSyncedAt,
    );
  }

  Future<void> _runRemote(
    String name,
    Future<void> Function() op,
  ) async {
    if (_userId == null) return;
    try {
      _setStatus(phase: SyncPhase.syncing, error: null);
      await op();
      _setStatus(
          phase: _pending.isEmpty ? SyncPhase.synced : SyncPhase.syncing);
    } catch (e) {
      _pending.add(_PendingSyncOp(name: name, run: op));
      _setStatus(phase: SyncPhase.error, error: e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────
  // PUSH — Local → Supabase
  // Called after every local write.
  // ─────────────────────────────────────────────────────────

  Future<void> pushAnchor(GAnchor anchor) async {
    if (_userId == null) return;
    await _runRemote('pushAnchor:${anchor.id}', () async {
      await _client.from(GTables.anchors).upsert(anchor.toJson());
    });
  }

  Future<void> pushTask(GTask task) async {
    if (_userId == null) return;
    await _runRemote('pushTask:${task.id}', () async {
      await _client.from(GTables.tasks).upsert(task.toJson());
    });
  }

  Future<void> deleteTask(String taskId) async {
    if (_userId == null) return;
    await _runRemote('deleteTask:$taskId', () async {
      await _client.from(GTables.tasks).delete().eq('id', taskId);
    });
  }

  Future<void> pushHabit(GHabit habit) async {
    if (_userId == null) return;
    await _runRemote('pushHabit:${habit.id}', () async {
      await _client.from(GTables.habits).upsert(habit.toJson());
    });
  }

  Future<void> pushPerson(GPerson person) async {
    if (_userId == null) return;
    await _runRemote('pushPerson:${person.id}', () async {
      await _client.from(GTables.people).upsert(person.toJson());
    });
  }

  Future<void> deletePerson(String personId) async {
    if (_userId == null) return;
    await _runRemote('deletePerson:$personId', () async {
      await _client.from(GTables.people).delete().eq('id', personId);
    });
  }

  // ─────────────────────────────────────────────────────────
  // PULL — Supabase → Local
  // Called once on login to hydrate Hive from cloud.
  // ─────────────────────────────────────────────────────────

  Future<void> pullAll() async {
    if (_userId == null) return;
    _setStatus(phase: SyncPhase.syncing, error: null);
    try {
      await retryPending();
      await Future.wait([
        _pullAnchors(),
        _pullTasks(),
        _pullHabits(),
        _pullPeople(),
      ]);
      _setStatus(phase: _pending.isEmpty ? SyncPhase.synced : SyncPhase.error);
    } catch (e) {
      _setStatus(phase: SyncPhase.error, error: e.toString());
    }
  }

  Future<void> retryPending() async {
    if (_userId == null || _pending.isEmpty) return;
    _setStatus(phase: SyncPhase.syncing, error: null);

    final snapshot = List<_PendingSyncOp>.from(_pending);
    _pending.clear();

    for (final op in snapshot) {
      try {
        await op.run();
      } catch (e) {
        _pending.add(op);
        _setStatus(phase: SyncPhase.error, error: e.toString());
      }
    }

    _setStatus(phase: _pending.isEmpty ? SyncPhase.synced : SyncPhase.error);
  }

  // BUG FIX: was `GAnchor.fromJson(row)` with no protection.
  // If any column is null, fromJson threw a cast exception and the
  // entire _pullAnchors() call failed with no recovery.
  // Now: bad rows are skipped individually — good rows still save.
  Future<void> _pullAnchors() async {
    final rows =
        await _client.from(GTables.anchors).select().eq('user_id', _userId!);

    for (final row in rows) {
      try {
        final anchor = GAnchor.fromJson(row);
        await _db.saveAnchor(anchor);
      } catch (_) {
        // Skip malformed row — Hive data from last session used for this entry
      }
    }
  }

  Future<void> _pullTasks() async {
    final rows =
        await _client.from(GTables.tasks).select().eq('user_id', _userId!);

    for (final row in rows) {
      try {
        final task = GTask.fromJson(row);
        await _db.saveTask(task);
      } catch (_) {}
    }
  }

  Future<void> _pullHabits() async {
    final rows =
        await _client.from(GTables.habits).select().eq('user_id', _userId!);

    for (final row in rows) {
      try {
        final habit = GHabit.fromJson(row);
        await _db.saveHabit(habit);
      } catch (_) {}
    }
  }

  Future<void> _pullPeople() async {
    final rows =
        await _client.from(GTables.people).select().eq('user_id', _userId!);

    for (final row in rows) {
      try {
        final person = GPerson.fromJson(row);
        await _db.savePerson(person);
      } catch (_) {}
    }
  }
}

enum SyncPhase { idle, syncing, synced, error }

@immutable
class SyncStatusSnapshot {
  const SyncStatusSnapshot({
    this.phase = SyncPhase.idle,
    this.pendingCount = 0,
    this.lastError,
    this.lastSyncedAt,
  });

  final SyncPhase phase;
  final int pendingCount;
  final String? lastError;
  final DateTime? lastSyncedAt;

  SyncStatusSnapshot copyWith({
    SyncPhase? phase,
    int? pendingCount,
    String? lastError,
    DateTime? lastSyncedAt,
  }) {
    return SyncStatusSnapshot(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      lastError: lastError,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class _PendingSyncOp {
  const _PendingSyncOp({
    required this.name,
    required this.run,
  });

  final String name;
  final Future<void> Function() run;
}
