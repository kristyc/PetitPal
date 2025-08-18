
// lib/src/widgets/thinking_bg_wrapper.dart
//
// Wrap your screen with this to show the "Simple Lava Lamp" background
// from the `dynamic_background` package ONLY while the app is "Thinking".
//
// Usage:
//   ThinkingBgWrapper(
//     isThinking: /* your existing thinking flag */,
//     child: YourScreenContent(...),
//   )
//
// Note: respects the current theme background color for non-thinking states.
//
// Accessibility: if the OS asks to reduce motion, the animation is suppressed.

import 'package:dynamic_background/dynamic_background.dart';
import 'package:flutter/material.dart';

class ThinkingBgWrapper extends StatelessWidget {
  final bool isThinking;
  final Widget child;
  final Color? baseBackground;

  const ThinkingBgWrapper({
    super.key,
    required this.isThinking,
    required this.child,
    this.baseBackground,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bgColor = baseBackground ?? Theme.of(context).colorScheme.background;

    // When not thinking (or if user prefers reduced motion), render the original background color.
    if (!isThinking || reduceMotion) {
      return Container(color: bgColor, child: child);
    }

    // Simple Lava Lamp — tuned for a subtle, warm "deep orange" ambience.
    return DynamicBg(
      duration: const Duration(seconds: 35),
      painterData: LavaPainterData(
        width: 240.0,
        widthTolerance: 70.0,
        growAndShrink: true,
        growthRate: 10.0,
        growthRateTolerance: 5.0,
        blurLevel: 22.0,
        numBlobs: 5,
        backgroundColor: bgColor,
        // Deep orange shades (primary emphasis). Tweak to taste.
        colors: const [
          Color(0xFFFF7043), // approx. Deep Orange 400
          Color(0xFFFF8A65), // approx. Deep Orange 300
          Color(0xFFFFAB91), // approx. Deep Orange 200
        ],
        allSameColor: false,
        fadeBetweenColors: true,
        changeColorsTogether: false,
        speed: 20.0,
        speedTolerance: 5.0,
      ),
      child: child,
    );
  }
}
