import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData dark() {
    const bg = Color(0xFF0A0F1E);
    const surf = Color(0xFF121A2A);
    const primary = Color(0xFF5B8CFF);
    const secondary = Color(0xFFFF6A13);

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0B0E12), // near-black
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF5B8CFF),      // vivid blue
        onPrimary: Colors.white,         // high contrast on primary
        secondary: Color(0xFFFF6A13),    // deep orange
        onSecondary: Colors.black,
        surface: Color(0xFF111827),      // deep slate
        onSurface: Colors.white,         // ensure white on surfaces
        background: Color(0xFF0B0E12),
        onBackground: Colors.white,
        error: Color(0xFFFF4D4F),
        onError: Colors.white,
      ),
      // Force Roboto with white text for dark mode
      textTheme: GoogleFonts.robotoTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        color: Color(0xFF111827),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Color(0xFF5B8CFF),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF0F172A),
        border: OutlineInputBorder(),
        hintStyle: TextStyle(color: Colors.white70),
        labelStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
