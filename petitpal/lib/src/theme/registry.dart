import 'package:flutter/material.dart';

class PetitTokens extends ThemeExtension<PetitTokens> {
  final double cornerRadius;
  final Duration motionFast;
  final Duration motionComfort;
  final double borderWidth;
  final Color voiceHint;

  const PetitTokens({
    required this.cornerRadius,
    required this.motionFast,
    required this.motionComfort,
    required this.borderWidth,
    required this.voiceHint,
  });

  @override
  ThemeExtension<PetitTokens> copyWith({
    double? cornerRadius,
    Duration? motionFast,
    Duration? motionComfort,
    double? borderWidth,
    Color? voiceHint,
  }) => PetitTokens(
    cornerRadius: cornerRadius ?? this.cornerRadius,
    motionFast: motionFast ?? this.motionFast,
    motionComfort: motionComfort ?? this.motionComfort,
    borderWidth: borderWidth ?? this.borderWidth,
    voiceHint: voiceHint ?? this.voiceHint,
  );

  @override
  ThemeExtension<PetitTokens> lerp(ThemeExtension<PetitTokens>? other, double t) {
    if (other is! PetitTokens) return this;
    return this;
  }
}

class ThemeDescriptor {
  final String id;
  final String name;
  final String shortDescription;
  final String voiceDescription;
  final ThemeData Function(Brightness) build;
  final PetitTokens tokens;
  const ThemeDescriptor({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.voiceDescription,
    required this.build,
    required this.tokens,
  });
}

List<ThemeDescriptor> themesRegistry() {
  final baseTokens = PetitTokens(
    cornerRadius: 16,
    motionFast: const Duration(milliseconds: 120),
    motionComfort: const Duration(milliseconds: 180),
    borderWidth: 3,
    voiceHint: Colors.amber,
  );

  ThemeData hcLight(Brightness b) => ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0066CC),
      onPrimary: Colors.white,
      background: Colors.white,
      onBackground: Colors.black,
    ),
    visualDensity: VisualDensity.standard,
    useMaterial3: true,
    textTheme: const TextTheme(bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  ).copyWith(extensions: [baseTokens]);

  ThemeData hcDark(Brightness b) => ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFD700),
      background: Colors.black,
      onBackground: Colors.white,
    ),
    useMaterial3: true,
    textTheme: const TextTheme(bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  ).copyWith(extensions: [baseTokens]);

  return [
    ThemeDescriptor(
      id: "high_contrast_light",
      name: "High Contrast Light",
      shortDescription: "Large black text on white, high borders",
      voiceDescription: "Large black text on white, designed for clarity.",
      build: hcLight,
      tokens: baseTokens,
    ),
    ThemeDescriptor(
      id: "high_contrast_dark",
      name: "High Contrast Dark",
      shortDescription: "Pure black background with bright accents",
      voiceDescription: "White text on black for maximum contrast.",
      build: hcDark,
      tokens: baseTokens,
    ),
    // TODO: Add the remaining 6 themes similarly (Modern Light/Dark, Modern Elegant, Vibrant Contemporary, Warm Minimalist, Large Text Friendly)
  ];
}
