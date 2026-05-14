import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Bolt',
      colorSchemeSeed: Colors.blue,
    );
  }
}
