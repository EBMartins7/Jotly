import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:my_notes/screens/add_note_screen.dart';
import 'package:my_notes/screens/splash_screen.dart';

import 'model/note_model.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    Hive.registerAdapter(NoteAdapter());
    await Hive.openBox<Note>('notesBox');
    await Hive.openBox('settingsBox');
    print("Hive initialized and box opened successfully");
  } catch (e) {
    print("Hive initialization error: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "My Notes",
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(color: Colors.black54)
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (_) => const SplashScreen());
        }

        if (settings.name == '/home') {
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        }

        if (settings.name == '/add') {
          final args = settings.arguments as Map<String, dynamic>?;

          return MaterialPageRoute(
            builder: (_) => AddNoteScreen(
              note: args != null ? args['note'] : null
            ),
          );
        }
        return null;
      },
    );
  }
}
