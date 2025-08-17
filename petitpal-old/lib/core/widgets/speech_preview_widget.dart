import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/internal_config.dart';
import '../../config/strings_config.dart';

class SpeechPreviewWidget extends StatelessWidget {
  final String text;
  final bool isListening;
  final double height;

  const SpeechPreviewWidget({
    Key? key,
    required this.text,
    required this.isListening,
    this.height = 120,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isHighContrast = _isHighContrastTheme(theme);

    return AnimatedContainer(
      duration: InternalConfig.animationDuration,
      height: height,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isListening ? theme.colorScheme.primary : Colors.transparent,
          width: isHighContrast ? 3 : 2,
        ),
        boxShadow: isListening
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (text.isEmpty && isListening)
                _buildListeningIndicator(theme)
              else if (text.isEmpty)
                Text(
                  'Tap the button to start talking',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: _getTextSize(isHighContrast),
                  ),
                )
              else
                Text(
                  text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: _getTextSize(isHighContrast),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    )
        .animate(target: isListening ? 1.0 : 0.0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.02, 1.02),
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
        );
  }

  Widget _buildListeningIndicator(ThemeData theme) {
    return Row(
      children: [
        Text(
          StringsConfig.listeningText,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: _getTextSize(false),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 8),
        ..._buildAnimatedDots(theme),
      ],
    );
  }

  List<Widget> _buildAnimatedDots(ThemeData theme) {
    return List.generate(3, (index) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .scale(
              delay: Duration(milliseconds: index * 200),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              begin: const Offset(1, 1),
              end: const Offset(1.5, 1.5),
            )
            .then()
            .scale(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              begin: const Offset(1.5, 1.5),
              end: const Offset(1, 1),
            ),
      );
    }).toList();
  }

  double _getTextSize(bool isHighContrast) {
    return isHighContrast ? 22.0 : 18.0;
  }

  bool _isHighContrastTheme(ThemeData theme) {
    // Check if this is a high contrast theme based on colors
    final backgroundColor = theme.colorScheme.background;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    // Pure black background with white text = high contrast dark
    if (backgroundColor == Colors.black && textColor == Colors.white) {
      return true;
    }

    // Very light background with dark text = high contrast light
    if (backgroundColor.computeLuminance() > 0.9 &&
        textColor.computeLuminance() < 0.2) {
      return true;
    }
    return false;
  }
}