import 'package:flutter/material.dart';

ThemeData defaultTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C3CB0)),
  useMaterial3: true,
);

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
    surface: Colors.blue.shade100,
  ),
  scaffoldBackgroundColor: Colors.blue.shade100,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF0D1B2A)),
    bodyMedium: TextStyle(color: Color(0xFF0D1B2A)),
    bodySmall: TextStyle(color: Color(0xFF3A4A5C)),
    titleLarge: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.w700),
    titleMedium: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.w600),
    labelLarge: TextStyle(color: Color(0xFF0D1B2A)),
    labelMedium: TextStyle(color: Color(0xFF3A4A5C)),
    labelSmall: TextStyle(color: Color(0xFF3A4A5C)),
    headlineLarge: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.w800),
    headlineMedium: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.w700),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: Colors.blue.shade800),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.blue.shade800,
      side: BorderSide(color: Colors.blue.shade700),
    ),
  ),
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
    surface: Color(0xFF0D1B2A),
  ),
  scaffoldBackgroundColor: Colors.blue.shade900,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFE8EDF2)),
    bodyMedium: TextStyle(color: Color(0xFFE8EDF2)),
    bodySmall: TextStyle(color: Color(0xFFB0BEC5)),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    labelLarge: TextStyle(color: Color(0xFFE8EDF2)),
    labelMedium: TextStyle(color: Color(0xFFB0BEC5)),
    labelSmall: TextStyle(color: Color(0xFFB0BEC5)),
    headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
  ),
  iconTheme: const IconThemeData(color: Color(0xFFE8EDF2)),
  listTileTheme: const ListTileThemeData(
    textColor: Color(0xFFE8EDF2),
    iconColor: Color(0xFFE8EDF2),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade300,
      foregroundColor: Color(0xFF0D1B2A),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: Colors.blue.shade300,
      foregroundColor: Color(0xFF0D1B2A),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: Colors.blue.shade200),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.blue.shade200,
      side: BorderSide(color: Colors.blue.shade300),
    ),
  ),
);
