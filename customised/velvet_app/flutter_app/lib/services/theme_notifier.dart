import 'package:flutter/material.dart';
import 'package:outgoing_notifications/screens/themes/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { defaultTheme, light, dark }

class ThemeNotifier extends ChangeNotifier {
  static const String _themeKey = 'appThemeMode';

  AppThemeMode _mode = AppThemeMode.defaultTheme;

  ThemeNotifier() {
    _loadTheme();
  }

  AppThemeMode get mode => _mode;

  // kept for compatibility with the legacy Switch widget (now unused)
  bool get isDarkMode => _mode == AppThemeMode.dark;

  ThemeData get currentTheme => switch (_mode) {
        AppThemeMode.light => lightTheme,
        AppThemeMode.dark => darkTheme,
        _ => defaultTheme,
      };

  void setTheme(AppThemeMode mode) {
    _mode = mode;
    _saveTheme();
    notifyListeners();
  }

  // kept so nothing calling toggleTheme() breaks, but prefer setTheme()
  void toggleTheme() {
    setTheme(_mode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark);
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    _mode = switch (saved) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.defaultTheme,
    };
    notifyListeners();
  }

  void _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (_mode) {
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
      _ => 'default',
    };
    prefs.setString(_themeKey, value);
  }
}
