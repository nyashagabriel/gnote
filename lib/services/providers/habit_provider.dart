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
    final previous = state;
    final habit = GHabit(
      id: _uuid.v4(),
      userId: userId,
      name: name.trim(),
      streak: 0,
      isActive: true,
      createdAt: localNow(),
    );
    state = habit;

    try {
      await _db.saveHabit(habit);
      await _sync.pushHabit(habit);
      _load();
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> markDone() async {
    final habit = state;
    if (habit == null || habit.doneToday) return;

    final previous = habit;
    final optimistic = habit.copyWith(
      streak: habit.streakAlive ? habit.streak + 1 : 1,
      lastChecked: localNow(),
    );

    state = optimistic;

    try {
      await _db.markHabitDone(habit.id);
      final persisted = _db.getActiveHabit() ?? optimistic;
      state = persisted;
      await _sync.pushHabit(persisted);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final habitProvider = StateNotifierProvider<HabitNotifier, GHabit?>((ref) {
  return HabitNotifier(
    ref.watch(localDbProvider),
    ref.watch(syncServiceProvider),
  );
});
