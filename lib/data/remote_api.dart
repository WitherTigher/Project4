import 'dart:async';
import '../models/note.dart';

/// Mock remote API for demo purposes.
/// In a real app, replace with HTTP/REST or Firestore calls.
class RemoteApi {
  // In-memory “server storage”
  static final Map<String, Note> _remoteStore = {};

  // Add a little latency so students see "sync" doing work
  static const Duration latency = Duration(milliseconds: 600);

  /// Return all remote notes
  static Future<List<Note>> listAll() async {
    await Future.delayed(latency);
    return _remoteStore.values.toList();
  }

  /// Create or update a remote note (keyed by uuid)
  static Future<void> upsert(Note n) async {
    await Future.delayed(latency);
    _remoteStore[n.uuid] = n;
  }

  /// Delete a note remotely
  static Future<void> delete(String uuid) async {
    await Future.delayed(latency);
    _remoteStore.remove(uuid);
  }

  //delete and clear all notes
  static Future<void> clear() async {
    await Future.delayed(latency);
    //use .clear to remove all entiets in a map
    _remoteStore.clear();
  }
}
