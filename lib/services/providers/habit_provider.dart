import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/timezone.dart';
import '../../models/habit.dart';
import '../local_db.dart';
import '../sync.dart';
import 'core_providers.dart';

const _uuid = Uuid();

class HabitNotifier extends StateNotifier<GHabit?> {
  HabitNotifier(this._db, this._sync) : super(null) {
    _load();
  }

  final LocalDb _db;
  final SyncService _sync;

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
      createdAt: localNow(),
    );
    await _db.saveHabit(habit);
    await _sync.pushHabit(habit);
    _load();
  }

  Future<void> markDone() async {
    if (state == null || state!.doneToday) return;
    await _db.markHabitDone(state!.id);
    final updated = _db.getActiveHabit();
    if (updated != null) {
      await _sync.pushHabit(updated);
    }
    _load();
  }
}

final habitProvider = StateNotifierProvider<HabitNotifier, GHabit?>((ref) {
  return HabitNotifier(
    ref.watch(localDbProvider),
    ref.watch(syncServiceProvider),
  );
});
