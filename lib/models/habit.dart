import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';

part 'habit.g.dart';

// ─────────────────────────────────────────────────────────────
// GNOTE — HABIT MODEL
//
// One active habit at a time. Did it or didn't.
// Hive type ID: 3
//
// fromJson uses GJson helpers — null-safe against Supabase nulls.
// ─────────────────────────────────────────────────────────────

@HiveType(typeId: 3)
class GHabit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  int streak;

  @HiveField(4)
  DateTime? lastChecked;

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  final DateTime createdAt;

  GHabit({
    required this.id,
    required this.userId,
    required this.name,
    this.streak = 0,
    this.lastChecked,
    this.isActive = false,
    required this.createdAt,
  });

  bool get doneToday {
    if (lastChecked == null) return false;
    final now = DateTime.now();
    return lastChecked!.year == now.year &&
        lastChecked!.month == now.month &&
        lastChecked!.day == now.day;
  }

  bool get streakAlive {
    if (lastChecked == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return doneToday ||
        (lastChecked!.year == yesterday.year &&
            lastChecked!.month == yesterday.month &&
            lastChecked!.day == yesterday.day);
  }

  // ── fromJson — null-safe via GJson ────────────────────────
  factory GHabit.fromJson(Map<String, dynamic> json) => GHabit(
        id: GJson.str(json, 'id'),
        userId: GJson.str(json, 'user_id'),
        name: GJson.str(json, 'name'),
        streak: GJson.integer(json, 'streak'),
        lastChecked: GJson.dateTimeOrNull(json, 'last_checked'),
        isActive: GJson.boolean(json, 'is_active'),
        createdAt: GJson.dateTime(json, 'created_at'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'streak': streak,
        'last_checked': lastChecked?.toIso8601String(),
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  GHabit copyWith({
    int? streak,
    DateTime? lastChecked,
    bool? isActive,
  }) =>
      GHabit(
        id: id,
        userId: userId,
        name: name,
        streak: streak ?? this.streak,
        lastChecked: lastChecked ?? this.lastChecked,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}
