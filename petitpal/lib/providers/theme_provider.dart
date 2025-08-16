import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/internal_config.dart';

// Theme state model
class ThemeState {
  final ThemeData currentTheme;
  final String themeId;
  final bool isLoading;
  final String? error;

  ThemeState({
    required this.currentTheme,
    this.themeId = 'modern_light',
    this.isLoading = false,
    this.error,
  });

  ThemeState copyWith({
    ThemeData? currentTheme,
    String? themeId,
    bool? isLoading,
    String? error,
  }) {
    return ThemeState(
      currentTheme: currentTheme ?? this.currentTheme,
      themeId: themeId ?? this.themeId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Theme provider notifier
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState(currentTheme: _getDefaultTheme()));

  SharedPreferences? _prefs;

  // Load saved theme
  Future<void> loadTheme() async {
    state = state.copyWith(isLoading: true);

    try {
      _prefs = await SharedPreferences.getInstance();
      final savedThemeId = _prefs?.getString(InternalConfig.storageKeySelectedTheme) ?? 
                          InternalConfig.defaultThemeId;
      
      final theme = _getThemeById(savedThemeId);
      state = state.copyWith(
        currentTheme: theme,
        themeId: savedThemeId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load theme: ${e.toString()}',
      );
    }
  }

  // Set new theme
  Future<void> setTheme(String themeId) async {
    try {
      final theme = _getThemeById(themeId);
      await _prefs?.setString(InternalConfig.storageKeySelectedTheme, themeId);
      
      state = state.copyWith(
        currentTheme: theme,
        themeId: themeId,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to set theme: ${e.toString()}',
      );
    }
  }

  // Get theme by ID
  static ThemeData _getThemeById(String themeId) {
    switch (themeId) {
      case 'modern_light':
        return _modernLightTheme;
      case 'modern_dark':
        return _modernDarkTheme;
      case 'high_contrast_light':
        return _highContrastLightTheme;
      case 'high_contrast_dark':
        return _highContrastDarkTheme;
      default:
        return _getDefaultTheme();
    }
  }

  static ThemeData _getDefaultTheme() => _modernLightTheme;

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Theme definitions
final _modernLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6750A4),
    brightness: Brightness.light,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(88, 88), // Large touch targets for seniors
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
);

final _modernDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6750A4),
    brightness: Brightness.dark,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(88, 88), // Large touch targets for seniors
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
);

final _highContrastLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF000000),
    onPrimary: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
    background: Color(0xFFFFFFFF),
    onBackground: Color(0xFF000000),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF000000)),
    displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF000000)),
    displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF000000)),
    headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Color(0xFF000000)),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF000000)),
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF000000)),
    bodyLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.normal, color: Color(0xFF000000)),
    bodyMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Color(0xFF000000)),
    bodySmall: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Color(0xFF000000)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(100, 100), // Extra large for high contrast
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF000000),
      foregroundColor: const Color(0xFFFFFFFF),
    ),
  ),
);

final _highContrastDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF000000),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFFFFFFF),
    background: Color(0xFF000000),
    onBackground: Color(0xFFFFFFFF),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
    displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
    displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
    headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF)),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF)),
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF)),
    bodyLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.normal, color: Color(0xFFFFFFFF)),
    bodyMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Color(0xFFFFFFFF)),
    bodySmall: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Color(0xFFFFFFFF)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(100, 100), // Extra large for high contrast
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFFFFFFFF),
      foregroundColor: const Color(0xFF000000),
    ),
  ),
);

// Provider definition
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

// Convenience providers
final currentThemeProvider = Provider<ThemeData>((ref) {
  return ref.watch(themeProvider).currentTheme;
});

final currentThemeIdProvider = Provider<String>((ref) {
  return ref.watch(themeProvider).themeId;
});
