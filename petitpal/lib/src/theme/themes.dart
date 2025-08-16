import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.dark;
  ThemeData light = _modernLight;
  ThemeData dark = _highContrastDark;
  String currentId = 'high_contrast_dark';

  ThemeController() { _restore(); }

  Future<void> _restore() async {
    final p = await SharedPreferences.getInstance();
    currentId = p.getString('theme_id') ?? currentId;
    switchTheme(currentId, persist: false);
  }

  Future<void> switchTheme(String id, {bool persist = true}) async {
    currentId = id;
    switch (id) {
      case 'high_contrast_light': light = _highContrastLight; dark = _highContrastLight; mode = ThemeMode.light; break;
      case 'high_contrast_dark': light = _highContrastDark; dark = _highContrastDark; mode = ThemeMode.dark; break;
      case 'modern_light': light = _modernLight; dark = _modernLight; mode = ThemeMode.light; break;
      case 'modern_dark': light = _modernDark; dark = _modernDark; mode = ThemeMode.dark; break;
      case 'modern_elegant': light = _modernElegant; dark = _modernElegant; mode = ThemeMode.light; break;
      case 'vibrant_contemporary': light = _vibrantContemporary; dark = _vibrantContemporary; mode = ThemeMode.light; break;
      case 'warm_minimalist': light = _warmMinimalist; dark = _warmMinimalist; mode = ThemeMode.light; break;
      case 'large_text_friendly': light = _largeTextFriendly; dark = _largeTextFriendly; mode = ThemeMode.light; break;
      default: light = _highContrastDark; dark = _highContrastDark; mode = ThemeMode.dark;
    }
    if (persist) {
      final p = await SharedPreferences.getInstance();
      await p.setString('theme_id', currentId);
    }
    notifyListeners();
  }
}

final _highContrastLight = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.highContrastLight(
    primary: Color(0xFF0066CC), onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black),
  textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
);
final _highContrastDark = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.highContrastDark(
    primary: Color(0xFFFFD700), surface: Colors.black, onSurface: Colors.white),
  textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
);
final _modernLight = ThemeData(useMaterial3: true,
  colorScheme: const ColorScheme.light(primary: Color(0xFF3182CE), surface: Color(0xFFFAFAFA), onSurface: Color(0xFF2D3748)));
final _modernDark = ThemeData(useMaterial3: true,
  colorScheme: const ColorScheme.dark(primary: Color(0xFF63B3ED), surface: Color(0xFF1A202C), onSurface: Color(0xFFF7FAFC)));
final _modernElegant = ThemeData(useMaterial3: true,
  colorScheme: const ColorScheme.light(primary: Color(0xFF319795), surface: Color(0xFFF8F9FA), onSurface: Color(0xFF1E2A4A)));
final _vibrantContemporary = ThemeData(useMaterial3: true,
  colorScheme: const ColorScheme.light(primary: Color(0xFF9F7AEA), surface: Colors.white, onSurface: Color(0xFF1A365D)));
final _warmMinimalist = ThemeData(useMaterial3: true,
  colorScheme: const ColorScheme.light(primary: Color(0xFF68D391), surface: Color(0xFFFFF8F0), onSurface: Color(0xFF744210)));
final _largeTextFriendly = ThemeData(useMaterial3: true,
  textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 22, height: 1.6, color: Color(0xFF3C2414))),
  colorScheme: const ColorScheme.light(primary: Color(0xFF22543D), surface: Color(0xFFF5F5DC), onSurface: Color(0xFF3C2414)));
