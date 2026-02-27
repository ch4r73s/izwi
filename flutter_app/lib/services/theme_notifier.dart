// import 'package:flutter/material.dart';
// import 'package:outgoing_notifications/screens/themes/themes.dart';

// class ThemeNotifier extends ChangeNotifier {
//   ThemeData _currentTheme = lightTheme;

//   final bool _isDarkMode = false;
//   bool get isDarkMode => _isDarkMode;

//   ThemeData get currentTheme => _currentTheme;

//   void toggleTheme() {
//     _currentTheme = (_currentTheme == lightTheme) ? darkTheme : lightTheme;
//     print('Theme toggled: $currentTheme.'); // Debug line
//     notifyListeners();
//   }
//   // bool _isDarkMode = false;

//   // bool get isDarkMode => _isDarkMode;

//   // ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

//   // void toggleTheme() {
//   //   _isDarkMode = !_isDarkMode;
//   //   print('Theme toggled: $_isDarkMode'); // Debug line
//   //   notifyListeners();
//   // }
// }

import 'package:flutter/material.dart';
import 'package:outgoing_notifications/screens/themes/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _themeKey = 'themeMode';
  ThemeData _currentTheme;
  bool _isDarkMode;

  ThemeNotifier()
      : _currentTheme = ThemeData.light(),
        _isDarkMode = false {
    _loadTheme();
  }

  ThemeData get currentTheme => _currentTheme;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _currentTheme = (_currentTheme == lightTheme) ? darkTheme : lightTheme;
    print('Theme toggled: $currentTheme.'); // Debug line
    _saveTheme();
    notifyListeners();
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _currentTheme = _isDarkMode ? ThemeData.dark() : ThemeData.light();
    notifyListeners();
  }

  void _saveTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_themeKey, _isDarkMode);
  }
}
