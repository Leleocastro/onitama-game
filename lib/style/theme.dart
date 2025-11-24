import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color.fromARGB(255, 168, 25, 25);
  static const Color primaryDark = Color.fromARGB(255, 90, 55, 52);
  static const Color primaryLight = Color.fromARGB(255, 141, 102, 99);
  static const Color accent = Color.fromARGB(255, 211, 134, 18);
  static const Color background = Color.fromARGB(255, 239, 234, 234);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  static final ThemeData themeData = ThemeData(
    primaryColor: primary,
    primaryColorDark: primaryDark,
    primaryColorLight: primaryLight,
    primaryTextTheme: GoogleFonts.onestTextTheme(),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: GoogleFonts.onest(fontSize: 16),
      ),
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: _getMaterialColor(primary),
    ).copyWith(secondary: accent, surface: background),
    scaffoldBackgroundColor: background,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}

MaterialColor _getMaterialColor(Color color) {
  final red = color.red;
  final green = color.green;
  final blue = color.blue;

  return MaterialColor(color.value, {
    50: Color.fromRGBO(red, green, blue, .1),
    100: Color.fromRGBO(red, green, blue, .2),
    200: Color.fromRGBO(red, green, blue, .3),
    300: Color.fromRGBO(red, green, blue, .4),
    400: Color.fromRGBO(red, green, blue, .5),
    500: Color.fromRGBO(red, green, blue, .6),
    600: Color.fromRGBO(red, green, blue, .7),
    700: Color.fromRGBO(red, green, blue, .8),
    800: Color.fromRGBO(red, green, blue, .9),
    900: Color.fromRGBO(red, green, blue, 1),
  });
}
