import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/timezone.dart';
import '../../models/task.dart';
import '../local_db.dart';
import '../sync.dart';
import 'core_providers.dart';

const _uuid = Uuid();

class CaptureNotifier extends StateNotifier<List<GTask>> {
  CaptureNotifier(this._db, this._sync) : super([]) {
    _load();
  }

  final LocalDb _db;
  final SyncService _sync;

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
      by: localNow().add(const Duration(days: 7)),
      category: 'other',
      isCapture: true,
      createdAt: localNow(),
    );
    await _db.saveTask(task);
    await _sync.pushTask(task);
    _load();
  }

  Future<void> deleteItem(String taskId) async {
    await _db.deleteTask(taskId);
    await _sync.deleteTask(taskId);
    _load();
  }

  Future<void> restoreItem(GTask task) async {
    await _db.saveTask(task);
    await _sync.pushTask(task);
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
    ref.watch(localDbProvider),
    ref.watch(syncServiceProvider),
  );
});
