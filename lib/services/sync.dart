import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _db     = LocalDb.instance;

  String? get _userId => _client.auth.currentUser?.id;

  // ─────────────────────────────────────────────────────────
  // PUSH — Local → Supabase
  // Called after every local write.
  // ─────────────────────────────────────────────────────────

  Future<void> pushAnchor(GAnchor anchor) async {
    if (_userId == null) return;
    try {
      await _client.from(GTables.anchors).upsert(anchor.toJson());
    } catch (_) {}
  }

  Future<void> pushTask(GTask task) async {
    if (_userId == null) return;
    try {
      await _client.from(GTables.tasks).upsert(task.toJson());
    } catch (_) {}
  }

  Future<void> deleteTask(String taskId) async {
    if (_userId == null) return;
    try {
      await _client.from(GTables.tasks).delete().eq('id', taskId);
    } catch (_) {}
  }

  Future<void> pushHabit(GHabit habit) async {
    if (_userId == null) return;
    try {
      await _client.from(GTables.habits).upsert(habit.toJson());
    } catch (_) {}
  }

  Future<void> pushPerson(GPerson person) async {
    if (_userId == null) return;
    try {
      await _client.from(GTables.people).upsert(person.toJson());
    } catch (_) {}
  }

  Future<void> deletePerson(String personId) async {
    if (_userId == null) return;
    try {
      await _client.from(GTables.people).delete().eq('id', personId);
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────
  // PULL — Supabase → Local
  // Called once on login to hydrate Hive from cloud.
  // ─────────────────────────────────────────────────────────

  Future<void> pullAll() async {
    if (_userId == null) return;
    try {
      await Future.wait([
        _pullAnchors(),
        _pullTasks(),
        _pullHabits(),
        _pullPeople(),
      ]);
    } catch (_) {
      // Pull failed — Hive data from last session is used
    }
  }

  // BUG FIX: was `GAnchor.fromJson(row)` with no protection.
  // If any column is null, fromJson threw a cast exception and the
  // entire _pullAnchors() call failed with no recovery.
  // Now: bad rows are skipped individually — good rows still save.
  Future<void> _pullAnchors() async {
    final rows = await _client
        .from(GTables.anchors)
        .select()
        .eq('user_id', _userId!);

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
    final rows = await _client
        .from(GTables.tasks)
        .select()
        .eq('user_id', _userId!);

    for (final row in rows) {
      try {
        final task = GTask.fromJson(row);
        await _db.saveTask(task);
      } catch (_) {}
    }
  }

  Future<void> _pullHabits() async {
    final rows = await _client
        .from(GTables.habits)
        .select()
        .eq('user_id', _userId!);

    for (final row in rows) {
      try {
        final habit = GHabit.fromJson(row);
        await _db.saveHabit(habit);
      } catch (_) {}
    }
  }

  Future<void> _pullPeople() async {
    final rows = await _client
        .from(GTables.people)
        .select()
        .eq('user_id', _userId!);

    for (final row in rows) {
      try {
        final person = GPerson.fromJson(row);
        await _db.savePerson(person);
      } catch (_) {}
    }
  }
}
