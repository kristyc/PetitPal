import 'package:flutter/material.dart';
import 'themes.dart';

class ThemeChoice {
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final ThemeMode mode;
  ThemeChoice({required this.lightTheme, required this.darkTheme, required this.mode});
}

class ThemeController extends ChangeNotifier {
  ThemeChoice _choice = ThemeChoice(lightTheme: buildModernLight(), darkTheme: buildHighContrastDark(), mode: ThemeMode.system);
  ThemeChoice get choice => _choice;
  void setTheme(String id) {
    switch (id) {
      case 'high_contrast_light':
        _choice = ThemeChoice(lightTheme: buildHighContrastLight(), darkTheme: buildHighContrastDark(), mode: ThemeMode.light);
        break;
      case 'high_contrast_dark':
        _choice = ThemeChoice(lightTheme: buildHighContrastLight(), darkTheme: buildHighContrastDark(), mode: ThemeMode.dark);
        break;
      case 'modern_light':
        _choice = ThemeChoice(lightTheme: buildModernLight(), darkTheme: buildModernDark(), mode: ThemeMode.light);
        break;
      case 'modern_dark':
        _choice = ThemeChoice(lightTheme: buildModernLight(), darkTheme: buildModernDark(), mode: ThemeMode.dark);
        break;
      case 'modern_elegant':
        _choice = ThemeChoice(lightTheme: buildModernElegant(), darkTheme: buildModernElegantDark(), mode: ThemeMode.system);
        break;
      case 'vibrant_contemporary':
        _choice = ThemeChoice(lightTheme: buildVibrantContemporary(), darkTheme: buildVibrantContemporaryDark(), mode: ThemeMode.system);
        break;
      case 'warm_minimalist':
        _choice = ThemeChoice(lightTheme: buildWarmMinimalist(), darkTheme: buildWarmMinimalistDark(), mode: ThemeMode.system);
        break;
      case 'large_text_friendly':
        _choice = ThemeChoice(lightTheme: buildLargeTextFriendly(), darkTheme: buildLargeTextFriendlyDark(), mode: ThemeMode.system);
        break;
      default:
        _choice = ThemeChoice(lightTheme: buildModernLight(), darkTheme: buildHighContrastDark(), mode: ThemeMode.system);
    }
    notifyListeners();
  }
}
