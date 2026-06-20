import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get currentTheme {
    final baseTheme = _isDarkMode ? ThemeData.dark() : ThemeData.light();
    return baseTheme.copyWith(
      colorScheme: _isDarkMode
          ? const ColorScheme.dark(
              primary: Color(0xFF006A61),
              secondary: Color(0xFF86F2E4),
              onSecondary: Color(0xFF0B1C30),
              surface: Color(0xFF0B1C30),
              error: Color(0xFFBA1A1A),
            )
          : const ColorScheme.light(
              primary: Color(0xFF006A61),
              secondary: Color(0xFF0B1C30),
              onSecondary: Colors.white,
              surface: Color(0xFFF8F9FF),
              error: Color(0xFFBA1A1A),
            ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(textStyle: baseTheme.textTheme.displayLarge),
        displayMedium: GoogleFonts.outfit(textStyle: baseTheme.textTheme.displayMedium),
        displaySmall: GoogleFonts.outfit(textStyle: baseTheme.textTheme.displaySmall),
        headlineLarge: GoogleFonts.outfit(textStyle: baseTheme.textTheme.headlineLarge),
        headlineMedium: GoogleFonts.outfit(textStyle: baseTheme.textTheme.headlineMedium),
        headlineSmall: GoogleFonts.outfit(textStyle: baseTheme.textTheme.headlineSmall),
        titleLarge: GoogleFonts.outfit(textStyle: baseTheme.textTheme.titleLarge),
        titleMedium: GoogleFonts.outfit(textStyle: baseTheme.textTheme.titleMedium),
        titleSmall: GoogleFonts.outfit(textStyle: baseTheme.textTheme.titleSmall),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _isDarkMode ? const Color(0xFF13253B) : Colors.white,
        foregroundColor: _isDarkMode ? Colors.white : const Color(0xFF0B1C30),
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          color: _isDarkMode ? Colors.white : const Color(0xFF0B1C30),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: IconThemeData(
          color: _isDarkMode ? Colors.white : const Color(0xFF0B1C30),
        ),
      ),
    );
  }
}
