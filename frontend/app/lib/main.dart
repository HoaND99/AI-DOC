import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/history_page.dart';
import 'screens/settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void updateTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Doc Summarizer',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
        fontFamily: 'Poppins',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Poppins',
      ),
      themeMode: _themeMode,
      home: HomeScreen(onThemeChanged: updateTheme, themeMode: _themeMode),
      routes: {
        '/history': (context) =>  HistoryPage(),
        '/settings': (context) => SettingsPage(
              currentThemeMode: _themeMode,
              onThemeChanged: updateTheme,
            ),
      },
    );
  }
}
