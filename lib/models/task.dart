import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';

part 'task.g.dart';

// ─────────────────────────────────────────────────────────────
// GNOTE — TASK MODEL
//
// Handles both Daily 3 and Capture list.
// isCapture flag separates them — no need for two models.
//
// SMART fields enforced:
//   what      → Specific
//   doneWhen  → Measurable
//   by        → Time-bound
//   category  → Relevant
//   isDone    → Achievable (tracked here)
//
// Hive type ID: 1
// ─────────────────────────────────────────────────────────────

@HiveType(typeId: 1)
class GTask extends HiveObject {

  @HiveField(0)
  final String id;              // UUID

  @HiveField(1)
  final String userId;          // ties to GUser.id

  @HiveField(2)
  final String what;            // SMART: Specific — what exactly

  @HiveField(3)
  final String doneWhen;        // SMART: Measurable — how you know it's done

  @HiveField(4)
  final DateTime by;            // SMART: Time-bound — deadline today

  @HiveField(5)
  final String category;        // SMART: Relevant — from GCategories

  @HiveField(6)
  bool isDone;                  // mutable — toggled on completion

  @HiveField(7)
  final bool isCapture;         // true = capture list, false = Daily 3

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  DateTime? completedAt;        // null until done — tells you when, not just if

  GTask({
    required this.id,
    required this.userId,
    required this.what,
    required this.doneWhen,
    required this.by,
    required this.category,
    this.isDone = false,
    this.isCapture = false,
    required this.createdAt,
    this.completedAt,
  });

  // ── fromJson ──────────────────────────────────────────────
  // ── fromJson — null-safe via GJson ────────────────────────
  factory GTask.fromJson(Map<String, dynamic> json) => GTask(
    id:          GJson.str(json, 'id'),
    userId:      GJson.str(json, 'user_id'),
    what:        GJson.str(json, 'what'),
    doneWhen:    GJson.str(json, 'done_when'),
    by:          GJson.dateTime(json, 'by'),
    category:    GJson.str(json, 'category', fallback: 'other'),
    isDone:      GJson.boolean(json, 'is_done'),
    isCapture:   GJson.boolean(json, 'is_capture'),
    createdAt:   GJson.dateTime(json, 'created_at'),
    completedAt: GJson.dateTimeOrNull(json, 'completed_at'),
  );

  // ── toJson ────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id':           id,
    'user_id':      userId,
    'what':         what,
    'done_when':    doneWhen,
    'by':           by.toIso8601String(),
    'category':     category,
    'is_done':      isDone,
    'is_capture':   isCapture,
    'created_at':   createdAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
  };

  // ── copyWith ──────────────────────────────────────────────
  GTask copyWith({
    bool? isDone,
    DateTime? completedAt,
    String? category,
  }) =>
      GTask(
        id:          id,
        userId:      userId,
        what:        what,
        doneWhen:    doneWhen,
        by:          by,
        category:    category   ?? this.category,
        isDone:      isDone     ?? this.isDone,
        isCapture:   isCapture,
        createdAt:   createdAt,
        completedAt: completedAt ?? this.completedAt,
      );
}
