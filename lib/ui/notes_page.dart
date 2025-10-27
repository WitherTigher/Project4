import 'package:flutter/material.dart';
import '../data/notes_db.dart';
import '../data/remote_api.dart';
import '../data/sync_manager.dart';
import '../models/note.dart';

/// Single-screen UI that demonstrates:
/// - Local CRUD via SQLite
/// - "Dirty" state for unsynced changes
/// - Manual Sync with a mock remote store
class NotesPage extends StatefulWidget {
  final bool online; // passed from app shell (toggle)
  //used for to toggle online functions
  final VoidCallback onToggleOnline;
  //used to toggle the themes
  final VoidCallback onToggleTheme;
  //used to check for dark and light mode
  final bool darkMode;
  //makes a calback so we can use the notes created function
  final VoidCallback notesCreated;
  //makes a callback so we can use the notes deleted function
  final VoidCallback notesDeleted;
  //these finals are used to keep track of the counters
  final int deleteamount;
  final int createdamount;
  //I use this to make everything required.
  const NotesPage({
    super.key,
    required this.online,
    required this.onToggleOnline,
    required this.onToggleTheme,
    required this.darkMode,
    required this.notesCreated,
    required this.notesDeleted,
    required this.deleteamount,
    required this.createdamount,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _db = NotesDb(); // DAO: all DB work goes through here
  late final _sync = SyncManager(_db);

  List<Note> _notes = []; // current list displayed in the UI
  bool _busy = true; // show a spinner while loading/syncing
  String _status = '—'; // status line for sync results

  @override
  void initState() {
    super.initState();
    // Seed a welcome note if DB is empty, then load UI
    _seedIfEmpty().then((_) => _refresh());
  }

  /// Add a single welcome note the first time the app runs
  Future<void> _seedIfEmpty() async {
    final all = await _db.getAll();
    if (all.isEmpty) {
      await _db.upsert(
        Note(
          id: null,
          uuid: generateUuid(),
          title: 'Welcome note',
          body: 'Try going offline, edit notes, then sync when online.',
          updatedAt: DateTime.now(),
          dirty: true, // mark dirty so students see the flag right away
        ),
      );
    }
  }

  /// Re-query all notes and refresh the list UI
  Future<void> _refresh() async {
    final items = await _db.getAll();
    setState(() {
      _notes = items;
      _busy = false;
    });
  }

  /// Add a new note or edit an existing one via a simple dialog
  Future<void> _addOrEdit({Note? note}) async {
    final result = await showDialog<Note>(
      context: context,
      builder: (_) => _NoteEditorDialog(note: note),
    );
    if (result == null) return;

    // Any local change becomes dirty and gets a fresh updatedAt
    final n = result.copyWith(updatedAt: DateTime.now(), dirty: true);
    await _db.upsert(n);
    await _refresh();
    //this if checks to see if the note is the note is being edited.
    //since the not will note be empty when being edited but will be empty on
    //creation since there is no data in it yet
    if (note == null) {
      //if its new update the notes created counter
      widget.notesCreated();
    }
    //this if mounted is used to make sure a the widiget is still in the tree
    //and is used to prevent erros
    if (!mounted) return;
    //then if we pass the if show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        //with the text creating or altering
        content: Text('Creating/Altering'),
        //and have that snackbar stick around for 2 seconds
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Delete locally; if online, also delete on the "server"
  Future<void> _delete(Note n) async {
    await _db.deleteByUuid(n.uuid);
    if (widget.online) {
      await RemoteApi.delete(n.uuid);
    }
    await _refresh();
    //widget.notes deleted is called as we are deleting a note
    widget.notesDeleted();
    //this if mounted is used to make sure a the widiget is still in the tree
    //and is used to prevent erros
    if (!mounted) return;
    //since we passed we show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        //with the text Deleting
        content: Text('Deleting'),
        //and have that snackbar stick around for 2 seconds
        duration: Duration(seconds: 2),
      ),
    );
  }

  //this function is used to clear the notes page I made this from a modifyed delete function
  Future<void> clear() async {
    //I make a database call to my clear field option
    await _db.clearfield();
    //if the widget is onle
    if (widget.online) {
      //then await for the remote api to run .clear
      await RemoteApi.clear();
    }
    //then refresh
    await _refresh();
    //then if mounted
    if (!mounted) return;
    //show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        //with the text clearing everyting away
        content: Text('Clearing everything away'),
        //and have that snackbar stick around for 2 seconds
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Run one sync pass and display a human-friendly status summary
  Future<void> _syncNow() async {
    setState(() {
      _busy = true;
      _status = 'Syncing...';
    });
    final report = await _sync.sync(online: widget.online);
    await _refresh();
    setState(() => _status = report.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project 4'),
        actions: [
          // Simple Online/Offline switch in the AppBar
          Row(
            children: [
              //this padding is uesed to show a the notes created with the current amount
              Padding(
                padding: EdgeInsets.only(right: 6),
                child: Text('Notes Created: ${widget.createdamount}'),
              ),
              //this padding is uesed to show a the notes deleted with the current amount
              Padding(
                padding: EdgeInsets.only(right: 6),
                child: Text('Notes Deleted: ${widget.deleteamount}'),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Text('Offline'),
              ),
              Switch(
                value: widget.online,
                onChanged: (_) => widget.onToggleOnline(),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6, right: 12),
                child: Text('Online'),
              ),
              //the folowing code is used to make a switch to toggle light and dark mode
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Text('LightMode'),
              ),
              Switch(
                value: widget.darkMode,
                onChanged: (_) => widget.onToggleTheme(),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6, right: 12),
                child: Text('DarkMode'),
              ),
            ],
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top row: status message + Sync button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Status: $_status',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      //thse icone is used to put a clear button with a delete icon by the sync button
                      FilledButton.icon(
                        onPressed: clear,
                        icon: const Icon(Icons.delete),
                        label: const Text('Clear'),
                      ),
                      SizedBox(width: 4),
                      FilledButton.icon(
                        onPressed: _syncNow,
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Notes list (swipe to delete, edit button to modify)
                Expanded(
                  child: _notes.isEmpty
                      ? const Center(child: Text('No notes yet. Tap + to add.'))
                      : ListView.builder(
                          itemCount: _notes.length,
                          itemBuilder: (context, i) {
                            final n = _notes[i];
                            return Dismissible(
                              key: ValueKey(n.uuid),
                              background: Container(color: Colors.red),
                              onDismissed: (_) => _delete(n),
                              child: ListTile(
                                title: Text(n.title),
                                subtitle: Text(
                                  // Show dirty flag and last update time for teaching
                                  '${n.body}\nUpdated: ${n.updatedAt.toLocal()}'
                                  '${n.dirty ? '  • dirty' : ''}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _addOrEdit(note: n),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

      // FAB to add a note quickly
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Add note'),
      ),
    );
  }
}

/// Simple dialog to create or edit a note.
/// Returns a Note (without changing updatedAt/dirty—caller decides that).
class _NoteEditorDialog extends StatefulWidget {
  final Note? note;
  const _NoteEditorDialog({required this.note});

  @override
  State<_NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<_NoteEditorDialog> {
  // Pre-fill fields if editing
  late final TextEditingController _title = TextEditingController(
    text: widget.note?.title ?? '',
  );
  late final TextEditingController _body = TextEditingController(
    text: widget.note?.body ?? '',
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'New note' : 'Edit note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Title'),
            controller: _title,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Body'),
            controller: _body,
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            // Build a base note (new or existing) and return it.
            // The caller will set updatedAt + dirty and upsert.
            final base =
                widget.note ??
                Note(
                  id: null,
                  uuid: generateUuid(),
                  title: '',
                  body: '',
                  updatedAt: DateTime.now(),
                  dirty: true,
                );
            final note = base.copyWith(
              title: _title.text.trim().isEmpty
                  ? 'Untitled'
                  : _title.text.trim(),
              body: _body.text.trim(),
            );
            Navigator.pop(context, note);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
