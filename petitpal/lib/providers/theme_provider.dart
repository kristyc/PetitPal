import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final ThemeData currentTheme;
  final String themeId;
  final bool isDarkMode;

  const ThemeState({
    required this.currentTheme,
    required this.themeId,
    required this.isDarkMode,
  });

  ThemeState copyWith({
    ThemeData? currentTheme,
    String? themeId,
    bool? isDarkMode,
  }) {
    return ThemeState(
      currentTheme: currentTheme ?? this.currentTheme,
      themeId: themeId ?? this.themeId,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState(
    currentTheme: _getDefaultTheme(),
    themeId: 'modern_light',
    isDarkMode: false,
  ));

  static ThemeData _getDefaultTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
  }

  static ThemeData _getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    );
  }

  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeId = prefs.getString('theme_id') ?? 'modern_light';
      final isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      
      state = ThemeState(
        currentTheme: isDarkMode ? _getDarkTheme() : _getDefaultTheme(),
        themeId: themeId,
        isDarkMode: isDarkMode,
      );
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  Future<void> setTheme(String themeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_id', themeId);
      
      final isDarkMode = themeId.contains('dark');
      await prefs.setBool('is_dark_mode', isDarkMode);
      
      state = ThemeState(
        currentTheme: isDarkMode ? _getDarkTheme() : _getDefaultTheme(),
        themeId: themeId,
        isDarkMode: isDarkMode,
      );
    } catch (e) {
      print('Error setting theme: $e');
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
