import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeNotifier() {
    _loadTheme();
  }

  void _loadTheme() async {
    final box = Hive.box('settingsBox');
    _isDarkMode = box.get('isDarkMode', defaultValue: true);
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final box = Hive.box('settingsBox');
    await box.put('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}
