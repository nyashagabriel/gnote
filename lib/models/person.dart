import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../core/timezone.dart';

part 'person.g.dart';

// ─────────────────────────────────────────────────────────────
// GNOTE — PERSON MODEL
//
// People thou appoints as Motivators or Meditators.
// The random engine picks from this list.
// App notifies thee — thou sends the WhatsApp message.
// lastSelectedAt prevents the same person being picked twice in a row.
//
// Hive type ID: 4
// ─────────────────────────────────────────────────────────────

@HiveType(typeId: 4)
class GPerson extends HiveObject {
  @HiveField(0)
  final String id; // UUID

  @HiveField(1)
  final String userId; // ties to GUser.id — thy house, thy list

  @HiveField(2)
  final String name; // display name

  @HiveField(3)
  final String whatsappNumber; // international format e.g. +2637XXXXXXXX

  @HiveField(4)
  final String role; // 'Motivator' or 'Meditator' from GStrings

  @HiveField(5)
  final String messageTemplate; // personal message with {name} placeholder

  @HiveField(6)
  DateTime? lastSelectedAt; // prevents back-to-back selection

  @HiveField(7)
  int timesSelected; // how many times this person has been picked

  @HiveField(8)
  final DateTime createdAt;

  GPerson({
    required this.id,
    required this.userId,
    required this.name,
    required this.whatsappNumber,
    required this.role,
    required this.messageTemplate,
    this.lastSelectedAt,
    this.timesSelected = 0,
    required this.createdAt,
  });

  // ── Resolve message — replaces {name} with actual name ────
  String get resolvedMessage => messageTemplate.replaceAll('{name}', name);

  // ── Was this person selected today? ───────────────────────
  bool get selectedToday {
    if (lastSelectedAt == null) return false;
    return isSameLocalDay(asLocal(lastSelectedAt!), localNow());
  }

  // ── fromJson ──────────────────────────────────────────────
  // ── fromJson — null-safe via GJson ────────────────────────
  factory GPerson.fromJson(Map<String, dynamic> json) => GPerson(
        id: GJson.str(json, 'id'),
        userId: GJson.str(json, 'user_id'),
        name: GJson.str(json, 'name'),
        whatsappNumber: GJson.str(json, 'whatsapp_number'),
        role: GJson.str(json, 'role', fallback: 'Motivator'),
        messageTemplate: GJson.str(json, 'message_template'),
        lastSelectedAt: GJson.dateTimeOrNull(json, 'last_selected_at'),
        timesSelected: GJson.integer(json, 'times_selected'),
        createdAt: GJson.dateTime(json, 'created_at'),
      );

  // ── toJson ────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'whatsapp_number': whatsappNumber,
        'role': role,
        'message_template': messageTemplate,
        'last_selected_at': lastSelectedAt?.toIso8601String(),
        'times_selected': timesSelected,
        'created_at': createdAt.toIso8601String(),
      };

  // ── copyWith ──────────────────────────────────────────────
  GPerson copyWith({
    DateTime? lastSelectedAt,
    int? timesSelected,
    String? messageTemplate,
  }) =>
      GPerson(
        id: id,
        userId: userId,
        name: name,
        whatsappNumber: whatsappNumber,
        role: role,
        messageTemplate: messageTemplate ?? this.messageTemplate,
        lastSelectedAt: lastSelectedAt ?? this.lastSelectedAt,
        timesSelected: timesSelected ?? this.timesSelected,
        createdAt: createdAt,
      );
}
