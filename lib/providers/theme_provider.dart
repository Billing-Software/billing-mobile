import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Design tokens
  static const Color _primaryColor = Color(0xFF006A61);
  static const Color _surfaceLight = Color(0xFFF6F7F9);
  static const Color _textPrimary = Color(0xFF1A1C1E);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _dividerColor = Color(0xFFF0F0F0);
  static const Color _errorColor = Color(0xFFDC2626);
  static const Color _borderColor = Color(0xFFE5E7EB);

  static const Color _surfaceDark = Color(0xFF111318);
  static const Color _cardDark = Color(0xFF1A1D23);
  static const Color _textPrimaryDark = Color(0xFFE8E8ED);
  static const Color _textSecondaryDark = Color(0xFF9CA3AF);

  ThemeData get currentTheme {
    final baseTheme = _isDarkMode ? ThemeData.dark() : ThemeData.light();

    final bgColor = _isDarkMode ? _surfaceDark : _surfaceLight;
    final cardColor = _isDarkMode ? _cardDark : Colors.white;
    final textColor = _isDarkMode ? _textPrimaryDark : _textPrimary;
    final subtextColor = _isDarkMode ? _textSecondaryDark : _textSecondary;
    final divider = _isDarkMode ? const Color(0xFF2A2D35) : _dividerColor;
    final appBarBg = _isDarkMode ? _cardDark : Colors.white;

    return baseTheme.copyWith(
      scaffoldBackgroundColor: bgColor,
      colorScheme: _isDarkMode
          ? ColorScheme.dark(
              primary: _primaryColor,
              secondary: const Color(0xFF86F2E4),
              onSecondary: _textPrimary,
              surface: _surfaceDark,
              error: _errorColor,
            )
          : ColorScheme.light(
              primary: _primaryColor,
              secondary: _textPrimary,
              onSecondary: Colors.white,
              surface: _surfaceLight,
              error: _errorColor,
            ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(textStyle: baseTheme.textTheme.displayLarge, color: textColor),
        displayMedium: GoogleFonts.inter(textStyle: baseTheme.textTheme.displayMedium, color: textColor),
        displaySmall: GoogleFonts.inter(textStyle: baseTheme.textTheme.displaySmall, color: textColor),
        headlineLarge: GoogleFonts.inter(textStyle: baseTheme.textTheme.headlineLarge, color: textColor, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.inter(textStyle: baseTheme.textTheme.headlineMedium, color: textColor, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.inter(textStyle: baseTheme.textTheme.headlineSmall, color: textColor, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.inter(textStyle: baseTheme.textTheme.titleLarge, color: textColor, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.inter(textStyle: baseTheme.textTheme.titleMedium, color: textColor, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.inter(textStyle: baseTheme.textTheme.titleSmall, color: subtextColor, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(textStyle: baseTheme.textTheme.bodyLarge, color: textColor),
        bodyMedium: GoogleFonts.inter(textStyle: baseTheme.textTheme.bodyMedium, color: textColor),
        bodySmall: GoogleFonts.inter(textStyle: baseTheme.textTheme.bodySmall, color: subtextColor),
        labelLarge: GoogleFonts.inter(textStyle: baseTheme.textTheme.labelLarge, color: textColor, fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.inter(textStyle: baseTheme.textTheme.labelMedium, color: subtextColor),
        labelSmall: GoogleFonts.inter(textStyle: baseTheme.textTheme.labelSmall, color: subtextColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textColor, size: 22),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: subtextColor,
          height: 1.3,
        ),
        iconColor: _textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        minVerticalPadding: 12,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFFD1D5DB);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryColor;
          return const Color(0xFFE5E7EB);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFFADB5BD),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _borderColor, width: 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _errorColor, width: 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _errorColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: const BorderSide(color: _borderColor),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: _textPrimary,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryColor;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
