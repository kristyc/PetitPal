import 'package:flutter/material.dart';
ThemeData buildHighContrastLight() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066CC), brightness: Brightness.light),
  textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
  useMaterial3: true,
);
ThemeData buildHighContrastDark() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFD700), brightness: Brightness.dark),
  textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
  useMaterial3: true,
);
ThemeData buildModernLight() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3182CE), brightness: Brightness.light),
  useMaterial3: true,
);
ThemeData buildModernDark() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF63B3ED), brightness: Brightness.dark),
  useMaterial3: true,
);
ThemeData buildModernElegant() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF319795), brightness: Brightness.light),
  useMaterial3: true,
);
ThemeData buildModernElegantDark() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF319795), brightness: Brightness.dark),
  useMaterial3: true,
);
ThemeData buildVibrantContemporary() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9F7AEA), brightness: Brightness.light),
  useMaterial3: true,
);
ThemeData buildVibrantContemporaryDark() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9F7AEA), brightness: Brightness.dark),
  useMaterial3: true,
);
ThemeData buildWarmMinimalist() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF68D391), brightness: Brightness.light),
  useMaterial3: true,
);
ThemeData buildWarmMinimalistDark() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF68D391), brightness: Brightness.dark),
  useMaterial3: true,
);
ThemeData buildLargeTextFriendly() => ThemeData(
  textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 22, height: 1.6)),
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22543D), brightness: Brightness.light),
  useMaterial3: true,
);
ThemeData buildLargeTextFriendlyDark() => ThemeData(
  textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 22, height: 1.6)),
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22543D), brightness: Brightness.dark),
  useMaterial3: true,
);
