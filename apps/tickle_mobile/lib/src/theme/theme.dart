import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Preset Colors for Counters
  static const List<CounterColorPreset> presets = [
    CounterColorPreset(
      name: 'Emerald',
      primary: Color(0xFF10B981),
      secondary: Color(0xFF059669),
      hex: '#10B981',
    ),
    CounterColorPreset(
      name: 'Ocean Blue',
      primary: Color(0xFF3B82F6),
      secondary: Color(0xFF2563EB),
      hex: '#3B82F6',
    ),
    CounterColorPreset(
      name: 'Sunset Amber',
      primary: Color(0xFFF59E0B),
      secondary: Color(0xFFD97706),
      hex: '#F59E0B',
    ),
    CounterColorPreset(
      name: 'Coral Red',
      primary: Color(0xFFEF4444),
      secondary: Color(0xFFDC2626),
      hex: '#EF4444',
    ),
    CounterColorPreset(
      name: 'Amethyst',
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFF7C3AED),
      hex: '#8B5CF6',
    ),
    CounterColorPreset(
      name: 'Mint Green',
      primary: Color(0xFF14B8A6),
      secondary: Color(0xFF0D9488),
      hex: '#14B8A6',
    ),
    CounterColorPreset(
      name: 'Rose Pink',
      primary: Color(0xFFEC4899),
      secondary: Color(0xFFDB2777),
      hex: '#EC4899',
    ),
    CounterColorPreset(
      name: 'Charcoal',
      primary: Color(0xFF4B5563),
      secondary: Color(0xFF1F2937),
      hex: '#4B5563',
    ),
  ];

  static CounterColorPreset getPresetByHex(String hex) {
    return presets.firstWhere(
      (p) => p.hex.toLowerCase() == hex.toLowerCase(),
      orElse: () => presets[0],
    );
  }

  // General App Colors - Light
  static const Color lightBg = Color(0xFFF2F2F7); // iOS native group background
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF8E8E93);
  static const Color lightBorder = Color(0xFFE5E5EA);

  // General App Colors - Dark
  static const Color darkBg = Color(0xFF000000); // Pure iPhone OLED black
  static const Color darkSurface = Color(0xFF1C1C1E); // iOS native dark card background
  static const Color darkCard = Color(0xFF1C1C1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkBorder = Color(0xFF2C2C2E);
}

class CounterColorPreset {
  final String name;
  final Color primary;
  final Color secondary;
  final String hex;

  const CounterColorPreset({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.hex,
  });
}

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF3B82F6),
      scaffoldBackgroundColor: AppColors.lightBg,
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xE6FFFFFF),
        selectedItemColor: Color(0xFF3B82F6),
        unselectedItemColor: AppColors.lightTextSecondary,
        elevation: 8,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 34,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
        bodyLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF3B82F6),
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xE61C1C1E),
        selectedItemColor: Color(0xFF3B82F6),
        unselectedItemColor: AppColors.darkTextSecondary,
        elevation: 8,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 34,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
        bodyLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}
