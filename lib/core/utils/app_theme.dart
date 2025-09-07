import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Itinera AI
  static const Color primaryColor = Color(0xFF1B5E20); // Dark green from design
  static const Color secondaryColor = Color(0xFF4CAF50); // Lighter green
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  
  // Accent Colors
  static const Color orangeAccent = Color(0xFFFF9800); // For the airplane icon
  static const Color textPrimaryColor = Color(0xFF1A1A1A);
  static const Color textSecondaryColor = Color(0xFF757575);
  
  // Dark Colors
  static const Color primaryColorDark = Color(0xFF2E7D32);
  static const Color surfaceColorDark = Color(0xFF121212);
  static const Color backgroundColorDark = Color(0xFF121212);
  
  // Text Colors
  static const Color onPrimary = Colors.white;
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);
  
  // Chat Colors
  static const Color userMessageColor = Color(0xFF1B5E20);
  static const Color aiMessageColor = Color(0xFFE8F5E8);
  static const Color userMessageColorDark = Color(0xFF2E7D32);
  static const Color aiMessageColorDark = Color(0xFF263238);
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: onSurface,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: surfaceColor,
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: onSurface,
      ),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: onSurfaceDark,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: surfaceColorDark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: surfaceColorDark,
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: onSurfaceDark,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: onSurfaceDark,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurfaceDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: onSurfaceDark,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: onSurfaceDark,
      ),
    ),
  );
}