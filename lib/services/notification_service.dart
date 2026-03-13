import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../core/constants.dart';

// ─────────────────────────────────────────────────────────────
// GNOTE — NOTIFICATION SERVICE
//
// Wraps awesome_notifications. All scheduling goes through here.
// Web: notifications are silently skipped — kIsWeb guard on init.
// iOS: permissions requested on first call to requestPermission().
//
// Five scheduled notifications:
//   1. morningAnchor     → 08:00 daily
//   2. daily3Reminder    → 08:45 daily (before 9am lock)
//   3. habitReminder     → user-set time (default 20:00)
//   4. responsibilityPick → 09:00 daily
//   5. captureReview     → Sunday 19:00
//
// Pattern: All methods are safe to call even if init was skipped.
// ─────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();

  // ── Initialise — call once in main() ─────────────────────────
  static Future<void> init() async {
    if (kIsWeb) return; // notifications not supported on web

    await AwesomeNotifications().initialize(
      null, // use default app icon
      [
        NotificationChannel(
          channelKey:         GChannels.anchor,
          channelName:        'Morning Anchor',
          channelDescription: 'Daily reminder to set your anchor',
          defaultColor:       const Color(0xFFF0A500),
          ledColor:           const Color(0xFFF0A500),
          importance:         NotificationImportance.High,
          channelShowBadge:   true,
        ),
        NotificationChannel(
          channelKey:         GChannels.tasks,
          channelName:        'Daily 3',
          channelDescription: 'Reminder before task lock at 9am',
          defaultColor:       const Color(0xFFF0A500),
          ledColor:           const Color(0xFFF0A500),
          importance:         NotificationImportance.High,
          channelShowBadge:   true,
        ),
        NotificationChannel(
          channelKey:         GChannels.habit,
          channelName:        'Habit',
          channelDescription: 'Daily habit reminder',
          defaultColor:       const Color(0xFF52E0A0),
          ledColor:           const Color(0xFF52E0A0),
          importance:         NotificationImportance.Default,
          channelShowBadge:   false,
        ),
        NotificationChannel(
          channelKey:         GChannels.responsibility,
          channelName:        'Responsibility',
          channelDescription: 'Reminder to pick and message someone',
          defaultColor:       const Color(0xFF3FA9F5),
          ledColor:           const Color(0xFF3FA9F5),
          importance:         NotificationImportance.Default,
          channelShowBadge:   false,
        ),
      ],
      debug: false,
    );
  }

  // ── Request permission — call after user first opens app ─────
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    return AwesomeNotifications().requestPermissionToSendNotifications();
  }

  // ── Check if permission granted ──────────────────────────────
  static Future<bool> isAllowed() async {
    if (kIsWeb) return false;
    return AwesomeNotifications().isNotificationAllowed();
  }

  // ── Ensure permission before scheduling/updating notifications ──
  static Future<bool> ensurePermission() async {
    if (kIsWeb) return false;
    if (await isAllowed()) return true;
    return requestPermission();
  }

  // ─────────────────────────────────────────────────────────────
  // SCHEDULE — all daily repeating notifications
  // Call after login once. They persist until cancelled.
  // ─────────────────────────────────────────────────────────────

  /// Call after login to set all daily reminders.
  static Future<void> scheduleAll({
    int habitHour   = 20,
    int habitMinute = 0,
  }) async {
    if (kIsWeb) return;
    try {
      await Future.wait([
        _scheduleMorningAnchor(),
        _scheduleDaily3Reminder(),
        _scheduleHabitReminder(habitHour, habitMinute),
        _scheduleResponsibilityPick(),
        _scheduleCaptureReview(),
      ]);
    } catch (_) {
      // Notification scheduling is non-critical — app continues without it
    }
  }

  static Future<void> ensurePermissionAndScheduleAll({
    int habitHour = 20,
    int habitMinute = 0,
  }) async {
    if (kIsWeb) return;
    final allowed = await ensurePermission();
    if (!allowed) return;
    await scheduleAll(habitHour: habitHour, habitMinute: habitMinute);
  }

  // ── 1. Morning Anchor — 08:00 daily ──────────────────────────
  static Future<void> _scheduleMorningAnchor() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         GNotifIds.morningAnchor,
        channelKey: GChannels.anchor,
        title:      '☀️ Good morning',
        body:       'Why did you wake up today? Set your anchor.',
        notificationLayout: NotificationLayout.Default,
        payload:    {'route': GRoutes.anchor},
      ),
      schedule: NotificationCalendar(
        hour:       8,
        minute:     0,
        second:     0,
        repeats:    true,
        allowWhileIdle: true,
      ),
    );
  }

  // ── 2. Daily 3 Reminder — 08:45 (15 min before lock) ─────────
  static Future<void> _scheduleDaily3Reminder() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         GNotifIds.daily3Reminder,
        channelKey: GChannels.tasks,
        title:      '⏰ Tasks lock in 15 minutes',
        body:       'Set your Daily 3 before 9am. Three tasks. No more.',
        notificationLayout: NotificationLayout.Default,
        payload:    {'route': GRoutes.daily3},
      ),
      schedule: NotificationCalendar(
        hour:       8,
        minute:     45,
        second:     0,
        repeats:    true,
        allowWhileIdle: true,
      ),
    );
  }

  // ── 3. Habit Reminder — user-set time (default 20:00) ────────
  static Future<void> _scheduleHabitReminder(int hour, int minute) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         GNotifIds.habitReminder,
        channelKey: GChannels.habit,
        title:      '🔥 Habit check-in',
        body:       'Did you do it today? Keep the streak alive.',
        notificationLayout: NotificationLayout.Default,
        payload:    {'route': GRoutes.habit},
      ),
      schedule: NotificationCalendar(
        hour:    hour,
        minute:  minute,
        second:  0,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  // ── 4. Responsibility Pick — 09:00 daily ─────────────────────
  static Future<void> _scheduleResponsibilityPick() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         GNotifIds.responsibilityPick,
        channelKey: GChannels.responsibility,
        title:      GStrings.respNotifTitle,
        body:       'Open Gnote to pick today\'s person and send them a message.',
        notificationLayout: NotificationLayout.Default,
        payload:    {'route': GRoutes.responsibility},
      ),
      schedule: NotificationCalendar(
        hour:    9,
        minute:  0,
        second:  0,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  // ── 5. Capture Review — Sunday 19:00 ─────────────────────────
  static Future<void> _scheduleCaptureReview() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         GNotifIds.captureReview,
        channelKey: GChannels.tasks,
        title:      '📋 Sunday review',
        body:       'Open your Capture list. Process what matters. Clear the rest.',
        notificationLayout: NotificationLayout.Default,
        payload:    {'route': GRoutes.capture},
      ),
      schedule: NotificationCalendar(
        weekday: DateTime.sunday,
        hour:    19,
        minute:  0,
        second:  0,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  // ── Update habit reminder time ────────────────────────────────
  static Future<bool> updateHabitTime(int hour, int minute) async {
    if (kIsWeb) return false;
    try {
      final allowed = await ensurePermission();
      if (!allowed) return false;
      await AwesomeNotifications()
          .cancelNotificationsByChannelKey(GChannels.habit);
      await _scheduleHabitReminder(hour, minute);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Cancel all — call on sign out ────────────────────────────
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await AwesomeNotifications().cancelAll();
    } catch (_) {}
  }

  // ── Cancel single ─────────────────────────────────────────────
  static Future<void> cancel(int id) async {
    if (kIsWeb) return;
    try {
      await AwesomeNotifications().cancel(id);
    } catch (_) {}
  }

  // ── Listen to notification taps ───────────────────────────────
  // Call this in main() after init.
  // router is GoRouter ref passed from app — navigates on tap.
  @pragma('vm:entry-point')
  static Future<void> onActionReceived(
    ReceivedAction action,
  ) async {
    final route = action.payload?['route'];
    if (route == null) return;
    // Navigation is handled by the app's router listener —
    // store the route in a global and consume it on next resume.
    _pendingRoute = route;
  }

  static String? _pendingRoute;

  /// Call this from app's first build or after resume
  /// to consume any tap that happened while app was closed.
  static String? consumePendingRoute() {
    final r = _pendingRoute;
    _pendingRoute = null;
    return r;
  }
}
