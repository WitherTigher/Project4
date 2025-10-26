import 'package:flutter/foundation.dart';

/// Domain model for a Note
/// - `id` is the local SQLite autoincrement id (optional).
/// - `uuid` is a stable logical id (used for sync with the "server").
/// - `dirty` indicates local changes not yet synced.
/// - `updatedAt` is used for conflict resolution (last-write-wins in this demo).
class Note {
  final int? id;
  final String uuid;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;

  const Note({
    this.id,
    required this.uuid,
    required this.title,
    required this.body,
    required this.updatedAt,
    required this.dirty,
  });

  /// Copy helper to create a modified Note while keeping immutability
  Note copyWith({
    int? id,
    String? uuid,
    String? title,
    String? body,
    DateTime? updatedAt,
    bool? dirty,
  }) => Note(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    body: body ?? this.body,
    updatedAt: updatedAt ?? this.updatedAt,
    dirty: dirty ?? this.dirty,
  );

  /// Convert Note → Map for SQLite (booleans stored as 0/1)
  Map<String, dynamic> toMap() => {
    'id': id,
    'uuid': uuid,
    'title': title,
    'body': body,
    'updatedAt': updatedAt.toIso8601String(),
    'dirty': dirty ? 1 : 0,
  };

  /// Factory constructor to map a DB row (Map) → Note instance
  factory Note.fromMap(Map<String, dynamic> m) => Note(
    id: m['id'] as int?,
    uuid: m['uuid'] as String,
    title: m['title'] as String,
    body: m['body'] as String,
    updatedAt: DateTime.parse(m['updatedAt'] as String),
    dirty: (m['dirty'] as int) == 1,
  );
}

/// Tiny UUID-ish helper for demo (timestamp + random key)
String generateUuid() =>
    '${DateTime.now().microsecondsSinceEpoch}-${UniqueKey()}';
