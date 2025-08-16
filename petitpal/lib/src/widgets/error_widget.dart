// lib/src/widgets/error_widget.dart
import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../config/strings_config.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDisplayWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.all(AppThemeConfig.paddingMedium),
      padding: EdgeInsets.all(AppThemeConfig.paddingLarge),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppThemeConfig.borderRadius),
        border: Border.all(
          color: theme.colorScheme.error,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: AppThemeConfig.textSizeXLarge,
            color: theme.colorScheme.onErrorContainer,
          ),
          
          SizedBox(height: AppThemeConfig.spacingMedium),
          
          Text(
            errorMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (onRetry != null || onDismiss != null)
            SizedBox(height: AppThemeConfig.spacingLarge),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (onDismiss != null)
                TextButton(
                  onPressed: onDismiss,
                  child: Text(StringsConfig.cancel),
                ),
              
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  child: Text(StringsConfig.tryAgain),
                ),
            ],
          ),
        ],
      ),
    );
  }
}