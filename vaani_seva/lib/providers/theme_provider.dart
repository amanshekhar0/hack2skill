import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      // If it's system, flip it to the opposite of what the system currently is
      // But since we can't contextually check system here safely without context,
      // we just default to light (assuming they are toggling out of dark)
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}
