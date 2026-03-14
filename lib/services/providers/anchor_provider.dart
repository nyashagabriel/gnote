import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/timezone.dart';
import '../../models/anchor.dart';
import '../local_db.dart';
import '../sync.dart';
import 'core_providers.dart';

const _uuid = Uuid();

class AnchorNotifier extends StateNotifier<GAnchor?> {
  AnchorNotifier(this._db, this._sync) : super(null) {
    _load();
  }

  final LocalDb _db;
  final SyncService _sync;

  void _load() {
    state = _db.getTodayAnchor();
  }

  Future<void> lockAnchor(String content, String userId) async {
    final anchor = GAnchor(
      id: _uuid.v4(),
      userId: userId,
      content: content.trim(),
      date: localNow(),
      createdAt: localNow(),
    );
    await _db.saveAnchor(anchor);
    await _sync.pushAnchor(anchor);
    state = anchor;
  }

  bool get hasAnchorToday => state != null && state!.isToday;
}

final anchorProvider = StateNotifierProvider<AnchorNotifier, GAnchor?>((ref) {
  return AnchorNotifier(
    ref.watch(localDbProvider),
    ref.watch(syncServiceProvider),
  );
});
