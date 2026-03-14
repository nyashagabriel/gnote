import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_service.dart';
import '../local_db.dart';
import '../sync.dart';

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
