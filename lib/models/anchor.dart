import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../core/timezone.dart';

part 'anchor.g.dart';

// ─────────────────────────────────────────────────────────────
// GNOTE — ANCHOR MODEL
//
// One sentence. One per day. The reason thou woke up.
// Hive type ID: 2
//
// fromJson uses GJson helpers — safe against null columns from Supabase.
// ─────────────────────────────────────────────────────────────

@HiveType(typeId: 2)
class GAnchor extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String content; // max 160 chars

  @HiveField(3)
  final DateTime date; // one anchor per calendar day

  @HiveField(4)
  final DateTime createdAt;

  GAnchor({
    required this.id,
    required this.userId,
    required this.content,
    required this.date,
    required this.createdAt,
  });

  bool get isToday {
    return isSameLocalDay(asLocal(date), localNow());
  }

  // ── fromJson — null-safe via GJson ────────────────────────
  // BUG FIX: was `json['id'] as String` etc — crashes if Supabase
  // returns null for any column. GJson.str falls back to '' safely.
  factory GAnchor.fromJson(Map<String, dynamic> json) => GAnchor(
        id: GJson.str(json, 'id'),
        userId: GJson.str(json, 'user_id'),
        content: GJson.str(json, 'content'),
        date: GJson.dateTime(json, 'date'),
        createdAt: GJson.dateTime(json, 'created_at'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'content': content,
        'date': date.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
