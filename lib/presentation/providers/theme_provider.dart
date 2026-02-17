import 'dart:html' as html;
import 'package:flutter/material.dart';

/// Manages light/dark theme switching with persistence via localStorage.
/// Uses dart:html localStorage directly (web-only app) to avoid adding
/// shared_preferences which triggers git dependency conflicts.
class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'theme_mode';
  ThemeMode _themeMode;

  ThemeProvider()
      : _themeMode = _loadFromStorage();

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    html.window.localStorage[_storageKey] = _themeMode.name;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    html.window.localStorage[_storageKey] = mode.name;
    notifyListeners();
  }

  static ThemeMode _loadFromStorage() {
    final saved = html.window.localStorage[_storageKey];
    if (saved == 'dark') return ThemeMode.dark;
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.light;
  }
}
