import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/note.dart';

/// DAO (Data Access Object) for all Note-related DB operations.
/// Hides raw SQL from the UI and exposes clean methods.
class NotesDb {
  // Singleton pattern so we don’t open multiple DB connections accidentally.
  static final NotesDb _instance = NotesDb._internal();
  factory NotesDb() => _instance;
  NotesDb._internal();

  static const _dbName = 'offline_first_demo.db';
  static const table = 'notes';
  Database? _db;

  /// Lazily open (or return existing) DB instance.
  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        // Create schema: store updatedAt as ISO string; dirty as 0/1 integer.
        await db.execute('''
          CREATE TABLE $table(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            dirty INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
    );
    return _db!;
  }

  /// Read all notes ordered by most recently updated first
  Future<List<Note>> getAll() async {
    final db = await database;
    final rows = await db.query(table, orderBy: 'updatedAt DESC');
    return rows.map(Note.fromMap).toList();
  }

  /// Insert or update a note by its logical id (uuid).
  /// Returns the stored note with local `id` filled in.
  Future<Note> upsert(Note n) async {
    final db = await database;
    final map = n.toMap()..remove('id'); // id is auto-managed locally
    final existing = await db.query(
      table,
      where: 'uuid = ?',
      whereArgs: [n.uuid],
      limit: 1,
    );
    if (existing.isEmpty) {
      // New logical note → insert
      final id = await db.insert(
        table,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return n.copyWith(id: id);
    } else {
      // Existing logical note → update
      await db.update(table, map, where: 'uuid = ?', whereArgs: [n.uuid]);
      final row = await db.query(
        table,
        where: 'uuid = ?',
        whereArgs: [n.uuid],
        limit: 1,
      );
      return Note.fromMap(row.first);
    }
  }

  /// Remove a note by its logical id (uuid)
  Future<void> deleteByUuid(String uuid) async {
    final db = await database;
    await db.delete(table, where: 'uuid = ?', whereArgs: [uuid]);
  }

  /// Clear all notes and make sure they are removed from the table
  Future<void> clearfield() async {
    final db = await database;
    await db.delete(table);
  }

  /// Query only notes that are dirty (require upload)
  Future<List<Note>> dirtyNotes() async {
    final db = await database;
    final rows = await db.query(table, where: 'dirty = 1');
    return rows.map(Note.fromMap).toList();
  }

  /// Batch mark many notes clean after a successful push
  Future<void> markAllClean(Set<String> uuids) async {
    if (uuids.isEmpty) return;
    final db = await database;
    final qMarks = List.filled(uuids.length, '?').join(',');
    await db.update(
      table,
      {'dirty': 0},
      where: 'uuid IN ($qMarks)',
      whereArgs: uuids.toList(),
    );
  }
}
