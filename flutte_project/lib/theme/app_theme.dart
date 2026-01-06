import 'package:flutter/material.dart';

class AppTheme {
  // OPTION 2: Emerald + Slate
  static const Color _primary = Color(0xFF059669); // emerald-600
  static const Color _primaryDark = Color(0xFF047857); // emerald-700
  static const Color _bg = Color(0xFFF8FAFC); // slate-50
  static const Color _surface = Color(0xFFFFFFFF); // white
  static const Color _text = Color(0xFF0F172A); // slate-900
  static const Color _text2 = Color(0xFF334155); // slate-700
  static const Color _muted = Color(0xFF64748B); // slate-500
  static const Color _border = Color(0xFFE2E8F0); // slate-200
  static const Color _soft = Color(0xFFECFDF5); // emerald-50

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    // ✅ ÉP FONT LOCAL – FIX NHẢY FONT WEB
    fontFamily: 'Roboto',

    // Background tổng
    scaffoldBackgroundColor: _bg,

    // Primary
    primaryColor: _primary,

    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _primaryDark,
      surface: _surface,
      background: _bg,
      brightness: Brightness.light,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: _bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: _text,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: _text,
      ),
    ),

    // Text
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: _text,
        height: 1.2,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: _text,
        height: 1.2,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: _text2, height: 1.25),
      bodySmall: TextStyle(fontSize: 12, color: _muted, height: 1.25),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: _border,
      thickness: 1,
      space: 1,
    ),

    // Card (phẳng, viền nhẹ, bo tinh)
    cardTheme: CardThemeData(
      color: _surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _border),
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
      ),
      labelStyle: const TextStyle(color: _muted),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)), // slate-400
    ),

    // Elevated Button (CTA emerald)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
    ),

    // Outlined Button (secondary)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _text,
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
    ),

    // Chip (tag)
    chipTheme: ChipThemeData(
      backgroundColor: _soft,
      selectedColor: _soft,
      disabledColor: _border,
      labelStyle: const TextStyle(
        color: Color(0xFF065F46), // emerald-800
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Color(0xFF065F46),
        fontWeight: FontWeight.w700,
      ),
      side: const BorderSide(color: Color(0xFFA7F3D0)), // emerald-200
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _text,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
