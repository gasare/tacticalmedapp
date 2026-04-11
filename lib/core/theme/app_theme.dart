import 'package:flutter/material.dart';

class AppTheme {
  // Light, stark tactical base
  static const Color primaryLight = Color(0xFFF9FAFB); // Clean White Base
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure White Cards
  static const Color tacticalGreen = Color(0xFF4A5D23); // Primary Olive Military
  static const Color darkTacticalGreen = Color(0xFF2C3E2D); // Subdued Green
  static const Color criticalRed = Color(0xFFDC2626); // Modern Red
  static const Color textPrimary = Color(0xFF111827); // Near Black
  static const Color textSecondary = Color(0xFF6B7280); // Slate Gray
  static const Color borderDark = Color(0x33000000); // 20% Black Border

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: primaryLight,
      colorScheme: const ColorScheme.light(
        primary: tacticalGreen,
        secondary: darkTacticalGreen,
        error: criticalRed,
        surface: surfaceLight,
        // ignore: deprecated_member_use
        background: primaryLight,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleSmall: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: tacticalGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: borderDark, width: 1)),
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tacticalGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Modern rounded
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tacticalGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: surfaceLight,
        elevation: 2,
        shadowColor: Color(0x1A000000), // 10% black
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Color(0x0D000000), width: 1), // 5% black
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: tacticalGreen, width: 2), // thicker focus
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: criticalRed, width: 1),
        ),
      ),
    );
  }

  static ThemeData get tacticalDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000), // Pure OLED black
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8B0000), // Dark Red
        secondary: Color(0xFF556B2F), // Muted Green
        error: Color(0xFFFF5252),
        surface: Color(0xFF121212), // Very dark grey for cards
        // ignore: deprecated_member_use
        background: Color(0xFF000000),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleSmall: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.grey, fontSize: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000),
        foregroundColor: Color(0xFF8B0000),
        centerTitle: true,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Color(0xFF8B0000), width: 1)),
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: Color(0xFF8B0000)),
        iconTheme: IconThemeData(color: Color(0xFF8B0000)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B0000),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF8B0000),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF121212),
        elevation: 2,
        shadowColor: Color(0x66000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(color: Colors.grey),
        labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF8B0000), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF000000),
        selectedItemColor: Color(0xFF8B0000),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
