// lib/config/theme_config.dart
import 'package:flutter/material.dart';

class AppThemeConfig {
  // Spacing
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  
  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border Radius
  static const double borderRadius = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusButton = 24.0;
  
  // Animation
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  
  // Touch Targets (Accessibility)
  static const double minTouchTarget = 48.0;
  static const double largeTouchTarget = 80.0; // For seniors
  
  // Text Sizes
  static const double textSizeSmall = 12.0;
  static const double textSizeMedium = 16.0;
  static const double textSizeLarge = 20.0;
  static const double textSizeXLarge = 24.0;
  static const double textSizeXXLarge = 32.0;
  
  // Colors - Light Theme
  static const Color lightPrimary = Color(0xFF6366F1);
  static const Color lightSecondary = Color(0xFF10B981);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightError = Color(0xFFEF4444);
  
  // Colors - Dark Theme
  static const Color darkPrimary = Color(0xFF818CF8);
  static const Color darkSecondary = Color(0xFF34D399);
  static const Color darkBackground = Color(0xFF1F2937);
  static const Color darkSurface = Color(0xFF374151);
  static const Color darkError = Color(0xFFF87171);
  
  // Colors - High Contrast
  static const Color highContrastBackground = Color(0xFF000000);
  static const Color highContrastSurface = Color(0xFF000000);
  static const Color highContrastText = Color(0xFFFFFFFF);
  static const Color highContrastPrimary = Color(0xFFFFFFFF);
  
  // Create Theme Data
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      background: lightBackground,
      surface: lightSurface,
      error: lightError,
    ),
    textTheme: _getTextTheme(false),
    elevatedButtonTheme: _getElevatedButtonTheme(false),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      background: darkBackground,
      surface: darkSurface,
      error: darkError,
    ),
    textTheme: _getTextTheme(true),
    elevatedButtonTheme: _getElevatedButtonTheme(true),
  );
  
  static ThemeData highContrastTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: highContrastPrimary,
      secondary: highContrastPrimary,
      background: highContrastBackground,
      surface: highContrastSurface,
      onBackground: highContrastText,
      onSurface: highContrastText,
      error: highContrastText,
    ),
    textTheme: _getTextTheme(true, isHighContrast: true),
    elevatedButtonTheme: _getElevatedButtonTheme(true, isHighContrast: true),
  );
  
  static TextTheme _getTextTheme(bool isDark, {bool isHighContrast = false}) {
    final baseSize = isHighContrast ? 2.0 : 0.0;
    final color = isDark ? Colors.white : Colors.black;
    
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: textSizeXXLarge + baseSize,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      headlineMedium: TextStyle(
        fontSize: textSizeXLarge + baseSize,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: TextStyle(
        fontSize: textSizeLarge + baseSize,
        fontWeight: FontWeight.normal,
        color: color,
      ),
      bodyMedium: TextStyle(
        fontSize: textSizeMedium + baseSize,
        fontWeight: FontWeight.normal,
        color: color,
      ),
    );
  }
  
  static ElevatedButtonThemeData _getElevatedButtonTheme(bool isDark, {bool isHighContrast = false}) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(isHighContrast ? largeTouchTarget : minTouchTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusButton),
        ),
        textStyle: TextStyle(
          fontSize: isHighContrast ? textSizeLarge : textSizeMedium,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}