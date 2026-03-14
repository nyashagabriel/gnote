import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/timezone.dart';
import '../../models/task.dart';
import '../local_db.dart';
import '../sync.dart';
import 'core_providers.dart';

const _uuid = Uuid();

class Daily3State {
  const Daily3State({required this.tasks, required this.locked});

  final List<GTask> tasks;
  final bool locked;

  bool get isFull => tasks.length >= 3;
  bool get allDone => tasks.isNotEmpty && tasks.every((t) => t.isDone);
  int get doneCount => tasks.where((t) => t.isDone).length;
}

class Daily3Notifier extends StateNotifier<Daily3State> {
  Daily3Notifier(this._db, this._sync)
      : super(const Daily3State(tasks: [], locked: false)) {
    _load();
  }

  final LocalDb _db;
  final SyncService _sync;

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
      createdAt: localNow(),
    );
    await _db.saveTask(task);
    await _sync.pushTask(task);
    _load();
    return null;
  }

  Future<void> toggleDone(String taskId) async {
    await _db.toggleTaskDone(taskId);
    final updated = _db
        .getTodayTasks()
        .firstWhere((t) => t.id == taskId, orElse: () => state.tasks.first);
    await _sync.pushTask(updated);
    _load();
  }
}

final daily3Provider =
    StateNotifierProvider<Daily3Notifier, Daily3State>((ref) {
  return Daily3Notifier(
    ref.watch(localDbProvider),
    ref.watch(syncServiceProvider),
  );
});
