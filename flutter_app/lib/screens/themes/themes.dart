import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.blue.shade100,
  primaryColor: Colors.white,
  // Color? primaryColorDark,
  // Color? primaryColorLight,
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.blue.shade900,
  primaryColor: Colors.blue,
);
