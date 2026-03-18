import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../core/timezone.dart';
import '../models/task.dart';
import '../models/anchor.dart';
import '../models/habit.dart';
import '../models/person.dart';
import '../models/user.dart';
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
  SyncService._() {
    _restorePending();
  }
  static final SyncService instance = SyncService._();

  final _client = Supabase.instance.client;
  final _db = LocalDb.instance;
  final List<_PendingSyncOp> _pending = [];
  final List<RealtimeChannel> _realtimeChannels = [];
  Timer? _autoRetryTimer;
  bool _isRetryingPending = false;
  bool _isPullingAll = false;
  String? _realtimeUserId;

  final ValueNotifier<SyncStatusSnapshot> status =
      ValueNotifier<SyncStatusSnapshot>(const SyncStatusSnapshot());
  final ValueNotifier<int> realtimeRevision = ValueNotifier<int>(0);
  final ValueNotifier<int> profileRevision = ValueNotifier<int>(0);

  String? get _userId => _client.auth.currentUser?.id;

  void _restorePending() {
    final stored = _db.getPendingSyncOps();
    _pending
      ..clear()
      ..addAll(
        stored.map(_PendingSyncOp.fromJson).whereType<_PendingSyncOp>(),
      );
    _syncAutoRetryLoop();
    _setStatus(
      phase: _pending.isEmpty ? SyncPhase.idle : SyncPhase.error,
      error: _pending.isEmpty ? null : 'Sync pending from previous session.',
    );
  }

  Future<void> _persistPending() async {
    if (_pending.isEmpty) {
      await _db.clearPendingSyncOps();
      return;
    }
    await _db.savePendingSyncOps(
      _pending.map((op) => op.toJson()).toList(),
    );
  }

  Future<void> _enqueue(_PendingSyncOp op) async {
    _pending.removeWhere((existing) => existing.key == op.key);
    _pending.add(op);
    await _persistPending();
    _syncAutoRetryLoop();
  }

  Future<void> _dequeue(_PendingSyncOp op) async {
    _pending.removeWhere((existing) => existing.key == op.key);
    await _persistPending();
    _syncAutoRetryLoop();
  }

  void _syncAutoRetryLoop() {
    if (_pending.isEmpty) {
      _autoRetryTimer?.cancel();
      _autoRetryTimer = null;
      return;
    }

    _autoRetryTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => retryPendingInBackground(),
    );
  }

  void _setStatus({
    SyncPhase? phase,
    String? error,
  }) {
    status.value = status.value.copyWith(
      phase: phase ?? status.value.phase,
      pendingCount: _pending.length,
      lastError: error,
      lastSyncedAt:
          (phase == SyncPhase.synced) ? localNow() : status.value.lastSyncedAt,
    );
  }

  Future<void> _runRemote(
    _PendingSyncOp op,
  ) async {
    if (_userId == null) return;
    try {
      _setStatus(phase: SyncPhase.syncing, error: null);
      await op.run(_client);
      await _dequeue(op);
      _setStatus(
          phase: _pending.isEmpty ? SyncPhase.synced : SyncPhase.syncing);
    } catch (e) {
      await _enqueue(op);
      _setStatus(phase: SyncPhase.error, error: e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────
  // PUSH — Local → Supabase
  // Called after every local write.
  // ─────────────────────────────────────────────────────────

  Future<void> pushAnchor(GAnchor anchor) async {
    if (_userId == null) return;
    await _runRemote(_PendingSyncOp.pushAnchor(anchor));
  }

  Future<void> pushTask(GTask task) async {
    if (_userId == null) return;
    await _runRemote(_PendingSyncOp.pushTask(task));
  }

  Future<void> deleteTask(String taskId) async {
    if (_userId == null) return;
    await _runRemote(_PendingSyncOp.deleteTask(taskId));
  }

  Future<void> pushHabit(GHabit habit) async {
    if (_userId == null) return;
    await _runRemote(_PendingSyncOp.pushHabit(habit));
  }

  Future<void> pushPerson(GPerson person) async {
    if (_userId == null) return;
    await _runRemote(_PendingSyncOp.pushPerson(person));
  }

  Future<void> deletePerson(String personId) async {
    if (_userId == null) return;
    await _runRemote(_PendingSyncOp.deletePerson(personId));
  }

  // ─────────────────────────────────────────────────────────
  // PULL — Supabase → Local
  // Called once on login to hydrate Hive from cloud.
  // ─────────────────────────────────────────────────────────

  Future<void> pullAll() async {
    if (_userId == null || _isPullingAll) return;
    _isPullingAll = true;
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
    } finally {
      _isPullingAll = false;
    }
  }

  Future<void> retryPending() async {
    if (_userId == null || _pending.isEmpty || _isRetryingPending) return;
    _isRetryingPending = true;
    _setStatus(phase: SyncPhase.syncing, error: null);

    final snapshot = List<_PendingSyncOp>.from(_pending);

    for (final op in snapshot) {
      try {
        await op.run(_client);
        await _dequeue(op);
      } catch (e) {
        await _enqueue(op);
        _setStatus(phase: SyncPhase.error, error: e.toString());
      }
    }

    _setStatus(phase: _pending.isEmpty ? SyncPhase.synced : SyncPhase.error);
    _isRetryingPending = false;
    _syncAutoRetryLoop();
  }

  void retryPendingInBackground() {
    unawaited(retryPending());
  }

  void pullAllInBackground() {
    unawaited(pullAll());
  }

  Future<void> enableRealtimeForCurrentUser() async {
    final userId = _userId;
    if (userId == null) return;
    if (_realtimeUserId == userId && _realtimeChannels.isNotEmpty) return;

    await disableRealtime();
    _realtimeUserId = userId;

    _subscribeOwnedTable(
      channelName: 'anchors:$userId',
      table: GTables.anchors,
      onUpsert: (record) async => _db.saveAnchor(GAnchor.fromJson(record)),
    );
    _subscribeOwnedTable(
      channelName: 'tasks:$userId',
      table: GTables.tasks,
      onUpsert: (record) async => _db.saveTask(GTask.fromJson(record)),
      onDelete: (record) async {
        final taskId = record['id']?.toString();
        if (taskId != null) await _db.deleteTask(taskId);
      },
    );
    _subscribeOwnedTable(
      channelName: 'habits:$userId',
      table: GTables.habits,
      onUpsert: (record) async => _db.saveHabit(GHabit.fromJson(record)),
    );
    _subscribeOwnedTable(
      channelName: 'people:$userId',
      table: GTables.people,
      onUpsert: (record) async => _db.savePerson(GPerson.fromJson(record)),
      onDelete: (record) async {
        final personId = record['id']?.toString();
        if (personId != null) await _db.deletePerson(personId);
      },
    );

    final profileChannel = _client
        .channel('profiles:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) async {
            try {
              final record = _selectRealtimeRecord(payload);
              if (record == null) return;
              await _db.saveCurrentUser(GUser.fromJson(record));
              _markRealtimeApplied(profileChanged: true);
            } catch (e, stackTrace) {
              debugPrint('Realtime profile event failed: $e');
              debugPrintStack(stackTrace: stackTrace);
            }
          },
        )
        .subscribe();
    _realtimeChannels.add(profileChannel);
  }

  Future<void> disableRealtime() async {
    for (final channel in _realtimeChannels) {
      await _client.removeChannel(channel);
    }
    _realtimeChannels.clear();
    _realtimeUserId = null;
  }

  void _subscribeOwnedTable({
    required String channelName,
    required String table,
    required Future<void> Function(Map<String, dynamic> record) onUpsert,
    Future<void> Function(Map<String, dynamic> record)? onDelete,
  }) {
    final userId = _realtimeUserId;
    if (userId == null) return;

    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            try {
              if (payload.eventType == PostgresChangeEvent.delete) {
                final oldRecord = _asRecord(payload.oldRecord);
                if (oldRecord != null && onDelete != null) {
                  await onDelete(oldRecord);
                  _markRealtimeApplied();
                }
                return;
              }

              final record = _asRecord(payload.newRecord);
              if (record == null) return;
              await onUpsert(record);
              _markRealtimeApplied();
            } catch (e, stackTrace) {
              debugPrint('Realtime $table event failed: $e');
              debugPrintStack(stackTrace: stackTrace);
            }
          },
        )
        .subscribe();

    _realtimeChannels.add(channel);
  }

  Map<String, dynamic>? _selectRealtimeRecord(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.delete) {
      return _asRecord(payload.oldRecord);
    }
    return _asRecord(payload.newRecord);
  }

  Map<String, dynamic>? _asRecord(Object? record) {
    if (record is Map) return Map<String, dynamic>.from(record);
    return null;
  }

  void _markRealtimeApplied({bool profileChanged = false}) {
    realtimeRevision.value = realtimeRevision.value + 1;
    if (profileChanged) {
      profileRevision.value = profileRevision.value + 1;
    }
    status.value = status.value.copyWith(
      lastSyncedAt: localNow(),
      lastError: null,
    );
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
      } catch (e, stackTrace) {
        debugPrint('Sync skipped malformed anchor row: $e');
        debugPrintStack(stackTrace: stackTrace);
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
      } catch (e, stackTrace) {
        debugPrint('Sync skipped malformed task row: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> _pullHabits() async {
    final rows =
        await _client.from(GTables.habits).select().eq('user_id', _userId!);

    for (final row in rows) {
      try {
        final habit = GHabit.fromJson(row);
        await _db.saveHabit(habit);
      } catch (e, stackTrace) {
        debugPrint('Sync skipped malformed habit row: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> _pullPeople() async {
    final rows =
        await _client.from(GTables.people).select().eq('user_id', _userId!);

    for (final row in rows) {
      try {
        final person = GPerson.fromJson(row);
        await _db.savePerson(person);
      } catch (e, stackTrace) {
        debugPrint('Sync skipped malformed person row: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
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
  const _PendingSyncOp._({
    required this.kind,
    required this.targetId,
    required this.payload,
  });

  factory _PendingSyncOp.pushAnchor(GAnchor anchor) {
    return _PendingSyncOp._(
      kind: _PendingSyncKind.pushAnchor,
      targetId: anchor.id,
      payload: anchor.toJson(),
    );
  }

  factory _PendingSyncOp.pushTask(GTask task) {
    return _PendingSyncOp._(
      kind: _PendingSyncKind.pushTask,
      targetId: task.id,
      payload: task.toJson(),
    );
  }

  factory _PendingSyncOp.deleteTask(String taskId) {
    return _PendingSyncOp._(
      kind: _PendingSyncKind.deleteTask,
      targetId: taskId,
      payload: {'id': taskId},
    );
  }

  factory _PendingSyncOp.pushHabit(GHabit habit) {
    return _PendingSyncOp._(
      kind: _PendingSyncKind.pushHabit,
      targetId: habit.id,
      payload: habit.toJson(),
    );
  }

  factory _PendingSyncOp.pushPerson(GPerson person) {
    return _PendingSyncOp._(
      kind: _PendingSyncKind.pushPerson,
      targetId: person.id,
      payload: person.toJson(),
    );
  }

  factory _PendingSyncOp.deletePerson(String personId) {
    return _PendingSyncOp._(
      kind: _PendingSyncKind.deletePerson,
      targetId: personId,
      payload: {'id': personId},
    );
  }

  static _PendingSyncOp? fromJson(Map<String, dynamic> json) {
    final kind = _PendingSyncKind.fromValue(json['kind']?.toString());
    final targetId = json['target_id']?.toString();
    final payload = json['payload'];
    if (kind == null || targetId == null || payload is! Map) return null;
    return _PendingSyncOp._(
      kind: kind,
      targetId: targetId,
      payload: Map<String, dynamic>.from(payload),
    );
  }

  final _PendingSyncKind kind;
  final String targetId;
  final Map<String, dynamic> payload;

  String get key => '${kind.value}:$targetId';

  Map<String, dynamic> toJson() {
    return {
      'kind': kind.value,
      'target_id': targetId,
      'payload': payload,
    };
  }

  Future<void> run(SupabaseClient client) {
    return switch (kind) {
      _PendingSyncKind.pushAnchor =>
        client.from(GTables.anchors).upsert(payload),
      _PendingSyncKind.pushTask => client.from(GTables.tasks).upsert(payload),
      _PendingSyncKind.deleteTask =>
        client.from(GTables.tasks).delete().eq('id', targetId),
      _PendingSyncKind.pushHabit => client.from(GTables.habits).upsert(payload),
      _PendingSyncKind.pushPerson =>
        client.from(GTables.people).upsert(payload),
      _PendingSyncKind.deletePerson =>
        client.from(GTables.people).delete().eq('id', targetId),
    };
  }
}

enum _PendingSyncKind {
  pushAnchor('push_anchor'),
  pushTask('push_task'),
  deleteTask('delete_task'),
  pushHabit('push_habit'),
  pushPerson('push_person'),
  deletePerson('delete_person');

  const _PendingSyncKind(this.value);

  final String value;

  static _PendingSyncKind? fromValue(String? value) {
    for (final kind in values) {
      if (kind.value == value) return kind;
    }
    return null;
  }
}
