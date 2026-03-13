import 'package:hive_flutter/hive_flutter.dart';

part 'user.g.dart';

// ─────────────────────────────────────────────────────────────
// GNOTE — USER MODEL
//
// The key to the house. No user = no data access.
// Supabase handles auth. This model stores the profile
// locally in Hive so the app works offline after first login.
//
// Hive type ID: 0 — must be unique across all models
// ─────────────────────────────────────────────────────────────

@HiveType(typeId: 0)
class GUser extends HiveObject {
  @HiveField(0)
  final String id; // Supabase auth.users UUID

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String displayName;

  @HiveField(3)
  final String? timezone; // for accurate notification timing
  // e.g. 'UTC' or device timezone label

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime lastSeen;

  GUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.timezone,
    required this.createdAt,
    required this.lastSeen,
  });

  // ── fromJson — Supabase response → GUser ──────────────────
  factory GUser.fromJson(Map<String, dynamic> json) => GUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['display_name'] as String,
        timezone: json['timezone'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        lastSeen: DateTime.parse(json['last_seen'] as String),
      );

  // ── toJson — GUser → Supabase insert/update ───────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'timezone': timezone,
        'created_at': createdAt.toIso8601String(),
        'last_seen': lastSeen.toIso8601String(),
      };

  // ── copyWith — update single fields without mutation ──────
  GUser copyWith({
    String? displayName,
    String? timezone,
    DateTime? lastSeen,
  }) =>
      GUser(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        timezone: timezone ?? this.timezone,
        createdAt: createdAt,
        lastSeen: lastSeen ?? this.lastSeen,
      );
}
