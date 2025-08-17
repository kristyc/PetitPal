// lib/src/widgets/speech_preview_widget.dart
import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../config/strings_config.dart';

class SpeechPreviewWidget extends StatelessWidget {
  final String recognizedText;
  final bool isListening;
  final bool isProcessing;

  const SpeechPreviewWidget({
    super.key,
    required this.recognizedText,
    required this.isListening,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast = _isHighContrastTheme(theme);
    
    return AnimatedContainer(
      duration: AppThemeConfig.animationDuration,
      height: 120,
      margin: EdgeInsets.all(AppThemeConfig.paddingMedium),
      padding: EdgeInsets.all(AppThemeConfig.paddingMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppThemeConfig.borderRadiusLarge),
        border: Border.all(
          color: isListening 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withOpacity(0.3),
          width: isListening ? 3 : 1,
        ),
        boxShadow: [
          if (!isHighContrast)
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Row(
            children: [
              AnimatedContainer(
                duration: AppThemeConfig.animationDurationFast,
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(theme),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: AppThemeConfig.spacingSmall),
              Text(
                _getStatusText(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppThemeConfig.spacingSmall),
          
          // Speech text preview
          Expanded(
            child: SingleChildScrollView(
              child: AnimatedDefaultTextStyle(
                duration: AppThemeConfig.animationDuration,
                style: TextStyle(
                  fontSize: _getTextSize(isHighContrast),
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                  height: 1.4,
                ),
                child: Text(
                  _getDisplayText(),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isHighContrastTheme(ThemeData theme) {
    // Check if this is the high contrast theme
    return theme.colorScheme.background == AppThemeConfig.highContrastBackground;
  }

  double _getTextSize(bool isHighContrast) {
    if (isHighContrast) {
      return AppThemeConfig.textSizeLarge + 2; // Extra large for accessibility
    }
    return AppThemeConfig.textSizeMedium + 2;
  }

  Color _getStatusColor(ThemeData theme) {
    if (isListening) {
      return theme.colorScheme.primary;
    } else if (isProcessing) {
      return theme.colorScheme.secondary;
    }
    return theme.colorScheme.outline;
  }

  String _getStatusText() {
    if (isListening) {
      return StringsConfig.listening;
    } else if (isProcessing) {
      return StringsConfig.processing;
    }
    return 'Ready';
  }

  String _getDisplayText() {
    if (recognizedText.isEmpty) {
      if (isListening) {
        return StringsConfig.listening;
      } else if (isProcessing) {
        return StringsConfig.processing;
      }
      return StringsConfig.tapToTalk;
    }
    return recognizedText;
  }
}