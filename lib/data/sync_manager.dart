import '../models/note.dart';
import 'notes_db.dart';
import 'remote_api.dart';

/// Value class to report what the sync did (great for UI & logging)
class SyncReport {
  final int pushed;
  final int pulled;
  final int conflictsResolved;
  final int skipped;
  const SyncReport({
    required this.pushed,
    required this.pulled,
    required this.conflictsResolved,
    required this.skipped,
  });

  @override
  String toString() =>
      'Pushed $pushed · Pulled $pulled · Resolved $conflictsResolved · Skipped $skipped';
}

/// Coordinates local ↔ remote data and applies a conflict strategy.
/// Strategy used: LAST-WRITE-WINS via `updatedAt`.
class SyncManager {
  final NotesDb db;
  SyncManager(this.db);

  /// Perform one sync pass.
  /// - If offline: do nothing and return zeros.
  /// - If online:
  ///   1) PUSH all dirty local notes to remote (then mark clean).
  ///   2) PULL all remote notes and merge:
  ///      - If remote is newer → override local (conflict +1).
  ///      - If local is newer → keep local (skipped +1).
  Future<SyncReport> sync({required bool online}) async {
    if (!online) {
      return const SyncReport(
        pushed: 0,
        pulled: 0,
        conflictsResolved: 0,
        skipped: 0,
      );
    }

    int pushed = 0, pulled = 0, conflicts = 0, skipped = 0;

    // 1) PUSH local dirty notes
    final dirty = await db.dirtyNotes();
    for (final n in dirty) {
      await RemoteApi.upsert(n);
      pushed++;
    }
    await db.markAllClean(dirty.map((e) => e.uuid).toSet());

    // 2) PULL remote → merge into local
    final remote = await RemoteApi.listAll();
    final local = await db.getAll();
    final localByUuid = {for (final n in local) n.uuid: n};

    for (final r in remote) {
      final l = localByUuid[r.uuid];
      if (l == null) {
        // Remote note we don't have → insert locally (marked clean)
        await db.upsert(r.copyWith(dirty: false));
        pulled++;
      } else if (r.updatedAt.isAfter(l.updatedAt)) {
        // Remote is newer → take remote (conflict)
        await db.upsert(r.copyWith(dirty: false));
        conflicts++;
      } else {
        // Local is newer (was pushed already if dirty) → no change
        skipped++;
      }
    }

    return SyncReport(
      pushed: pushed,
      pulled: pulled,
      conflictsResolved: conflicts,
      skipped: skipped,
    );
  }
}
