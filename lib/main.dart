import 'package:flutter/material.dart';
import 'ui/notes_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Ensure Flutter engine is ready before any async work (e.g., opening a DB)
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit(); // initialize the FFI version
  databaseFactory = databaseFactoryFfi; // tell sqflite to use it

  runApp(const OfflineFirstApp());
}

/// Simple app shell that holds an "online/offline" toggle in state
class OfflineFirstApp extends StatefulWidget {
  const OfflineFirstApp({super.key});
  @override
  State<OfflineFirstApp> createState() => _OfflineFirstAppState();
}

class _OfflineFirstAppState extends State<OfflineFirstApp> {
  // Simulated connectivity flag for demo purposes
  bool _online = true;
  //is used to toggle theme changes used shared prefrence
  bool darkmode = false;
  //keeps track of notes created
  int counterNote = 0;
  //keeps track of notes deleted
  int deleteNote = 0;
  //added another override to initstate for the shared prefrences
  @override
  void initState() {
    //use super.initstate
    super.initState();
    //loads the theme option bellow
    _loadTheme();
    //loads the counter option bellow
    _loadCounter();
  }

  //use _loadtheme to sync get the theme for the apps styling
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => darkmode = prefs.getBool('darkMode') ?? false);
  }

  //uses set theme to set the theme for the  apps styling
  Future<void> _setTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    setState(() => darkmode = value);
  }

  //this function loads both of the countes and sets there states
  Future<void> _loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      counterNote = prefs.getInt('counterNote') ?? 0;
      deleteNote = prefs.getInt('deleteNote') ?? 0;
    });
  }

  //this function keeps track of each note made and seets the state
  Future<void> notesMade() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => counterNote++);
    await prefs.setInt('counterNote', counterNote);
  }

  //this function keeps track of each note removed and seets the state
  Future<void> notesRemoved() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => deleteNote++);
    await prefs.setInt('deleteNote', deleteNote);
  }

  //this overide builds the whole app
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project 4 Persistance demo',
      theme: ThemeData(
        //uses the brightness switch
        brightness: darkmode ? Brightness.dark : Brightness.light,
        //color schemeSeed with the color indigo
        colorSchemeSeed: Colors.indigo,
        //uses material3 set to true
        useMaterial3: true,
      ),
      // Pass current online state and a toggle callback to the UI and pass the theme and counters
      //as well as the dark mode and set states
      home: NotesPage(
        //pass dark mode
        darkMode: darkmode,
        //pass the on toggle theme like we do for the online
        onToggleTheme: () => _setTheme(!darkmode),
        //pass in the toggle for online
        online: _online,
        //pass in the toggle for online
        onToggleOnline: () => setState(() => _online = !_online),
        //passes in the notes created with the notes made function
        notesCreated: notesMade,
        //passes in the notes deleted with the notes removed function
        notesDeleted: notesRemoved,
        //passing in the counters
        deleteamount: deleteNote,
        createdamount: counterNote,
      ),
    );
  }
}
