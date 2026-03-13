import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants.dart';
import '../core/timezone.dart';
import '../models/anchor.dart';
import '../models/habit.dart';
import '../models/person.dart';
import '../models/task.dart';

class LocalDb {
  LocalDb._();

  static final LocalDb instance = LocalDb._();

  Box<GTask> get _tasks => Hive.box<GTask>(GBoxes.tasks);
  Box<GAnchor> get _anchors => Hive.box<GAnchor>(GBoxes.anchors);
  Box<GHabit> get _habits => Hive.box<GHabit>(GBoxes.habits);
  Box<GPerson> get _people => Hive.box<GPerson>(GBoxes.people);
  Box<dynamic> get _meta => Hive.box<dynamic>(GBoxes.meta);
  Box<dynamic> get _selections => Hive.box<dynamic>(GBoxes.selections);

  static const String _draftDateKey = 'anchor_draft_date';
  static const String _habitReminderHourKey = 'habit_reminder_hour';
  static const String _habitReminderMinuteKey = 'habit_reminder_minute';
  static const String _themeModeKey = 'theme_mode';

  // ANCHOR

  GAnchor? getTodayAnchor() {
    final today = localNow();
    for (final anchor in _anchors.values) {
      final anchorDate = asLocal(anchor.date);
      if (isSameLocalDay(anchorDate, today)) {
        return anchor;
      }
    }
    return null;
  }

  List<GAnchor> getAllAnchors() {
    final list = _anchors.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> saveAnchor(GAnchor anchor) async {
    await _anchors.put(anchor.id, anchor);
  }

  // TASKS — Daily 3 + Capture

  List<GTask> getTodayTasks() {
    final today = localNow();

    final list = _tasks.values.where((task) {
      if (task.isCapture) return false;
      final createdAt = asLocal(task.createdAt);
      return isSameLocalDay(createdAt, today);
    }).toList();

    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  List<GTask> getCaptureItems() {
    final list = _tasks.values.where((task) => task.isCapture).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveTask(GTask task) async {
    await _tasks.put(task.id, task);
  }

  Future<void> toggleTaskDone(String taskId) async {
    final task = _tasks.get(taskId);
    if (task == null) return;

    task.isDone = !task.isDone;
    task.completedAt = task.isDone ? localNow() : null;

    await task.save();
  }

  Future<void> deleteTask(String taskId) async {
    await _tasks.delete(taskId);
  }

  // HABITS

  GHabit? getActiveHabit() {
    for (final habit in _habits.values) {
      if (habit.isActive) return habit;
    }
    return null;
  }

  List<GHabit> getAllHabits() => _habits.values.toList();

  Future<void> saveHabit(GHabit habit) async {
    for (final existing in _habits.values) {
      if (existing.id != habit.id && existing.isActive) {
        existing.isActive = false;
        await existing.save();
      }
    }

    await _habits.put(habit.id, habit);
  }

  Future<void> markHabitDone(String habitId) async {
    final habit = _habits.get(habitId);
    if (habit == null || habit.doneToday) return;

    habit.streak = habit.streakAlive ? habit.streak + 1 : 1;
    habit.lastChecked = localNow();

    await habit.save();
  }

  // PEOPLE — Responsibility

  List<GPerson> getMotivators() {
    final list =
        _people.values.where((person) => person.role == 'Motivator').toList();
    list.sort((a, b) {
      final aDate = a.lastSelectedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.lastSelectedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });
    return list;
  }

  List<GPerson> getMeditators() {
    final list =
        _people.values.where((person) => person.role == 'Meditator').toList();
    list.sort((a, b) {
      final aDate = a.lastSelectedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.lastSelectedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });
    return list;
  }

  List<GPerson> getAllPeople() => _people.values.toList();

  Future<void> savePerson(GPerson person) async {
    await _people.put(person.id, person);
  }

  Future<void> deletePerson(String personId) async {
    await _people.delete(personId);
  }

  Future<void> markPersonSelected(String personId) async {
    final person = _people.get(personId);
    if (person == null) return;

    person.lastSelectedAt = localNow();
    person.timesSelected = person.timesSelected + 1;

    await person.save();
  }

  // ANCHOR DRAFT

  String? getAnchorDraft() {
    final value = _meta.get(GBoxes.anchorDraftKey);
    return value is String ? value : null;
  }

  DateTime? getDraftDate() {
    final value = _meta.get(_draftDateKey);
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  Future<void> saveAnchorDraft(String text) async {
    await _meta.put(GBoxes.anchorDraftKey, text);
    await _meta.put(_draftDateKey, localNow().toIso8601String());
  }

  Future<void> saveDraftDate(DateTime date) async {
    await _meta.put(_draftDateKey, date.toIso8601String());
  }

  Future<void> clearAnchorDraft() async {
    await _meta.delete(GBoxes.anchorDraftKey);
    await _meta.delete(_draftDateKey);
  }

  ({int hour, int minute}) getHabitReminderTime() {
    final hour = _meta.get(_habitReminderHourKey);
    final minute = _meta.get(_habitReminderMinuteKey);

    final h = (hour is int && hour >= 0 && hour <= 23) ? hour : 20;
    final m = (minute is int && minute >= 0 && minute <= 59) ? minute : 0;
    return (hour: h, minute: m);
  }

  Future<void> saveHabitReminderTime(int hour, int minute) async {
    await _meta.put(_habitReminderHourKey, hour);
    await _meta.put(_habitReminderMinuteKey, minute);
  }

  String getThemeMode() {
    final value = _meta.get(_themeModeKey);
    if (value is! String) return 'system';
    return switch (value) {
      'light' => 'light',
      'dark' => 'dark',
      _ => 'system',
    };
  }

  Future<void> saveThemeMode(String mode) async {
    await _meta.put(_themeModeKey, mode);
  }

  // ANCHOR EXISTS TODAY — used by router nav lock

  bool get hasAnchorToday {
    final today = localNow();

    for (final anchor in _anchors.values) {
      final anchorDate = asLocal(anchor.date);
      if (isSameLocalDay(anchorDate, today)) {
        return true;
      }
    }

    return false;
  }

  // CLEAR — called on sign out

  Future<void> clearAll() async {
    await _tasks.clear();
    await _anchors.clear();
    await _habits.clear();
    await _people.clear();
    await _meta.clear();
    await _selections.clear();
  }
}
