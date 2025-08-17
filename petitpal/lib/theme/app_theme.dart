import 'package:flutter/material.dart';

ThemeData highContrastDarkTheme() {
  const bg = Color(0xFF0B0F14);
  const surface = Color(0xFF121826);
  const primary = Color(0xFF8FDBFF);
  const accent = Color(0xFFFFE073);
  const onBg = Colors.white;
  const onPrimary = Colors.black;

  final colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: onPrimary,
    secondary: accent,
    onSecondary: Colors.black,
    error: Color(0xFFFF6B6B),
    onError: Colors.black,
    background: bg,
    onBackground: onBg,
    surface: surface,
    onSurface: onBg,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: bg,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 18, height: 1.3),
      bodyMedium: TextStyle(fontSize: 16, height: 1.3),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
    ).apply(bodyColor: onBg, displayColor: onBg),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        minimumSize: const Size(200, 64),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: TextStyle(color: onBg.withOpacity(0.6)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );

  return base;
}
