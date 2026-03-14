import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../services/local_db.dart';
import '../services/notification_service.dart';
import 'constants.dart';

Future<void> completeAuthenticatedEntry(BuildContext context) async {
  final reminder = LocalDb.instance.getHabitReminderTime();
  await NotificationService.ensurePermissionAndScheduleAll(
    habitHour: reminder.hour,
    habitMinute: reminder.minute,
  );
  if (!context.mounted) return;
  context.go(GRoutes.anchor);
}
