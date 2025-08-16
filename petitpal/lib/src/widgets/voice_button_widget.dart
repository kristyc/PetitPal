// lib/src/widgets/voice_button_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme_config.dart';
import '../../config/strings_config.dart';

class VoiceButtonWidget extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final VoidCallback onPressed;

  const VoiceButtonWidget({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.onPressed,
  });

  @override
  State<VoiceButtonWidget> createState() => _VoiceButtonWidgetState();
}

class _VoiceButtonWidgetState extends State<VoiceButtonWidget>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _pulseController;
  late Animation<double> _rippleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Ripple animation for listening state
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    // Pulse animation for processing state
    _pulseController = AnimationController(
      duration: AppThemeConfig.animationDuration,
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(VoiceButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isListening && !oldWidget.isListening) {
      _rippleController.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _rippleController.stop();
      _rippleController.reset();
    }

    if (widget.isProcessing && !oldWidget.isProcessing) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isProcessing && oldWidget.isProcessing) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast = _isHighContrastTheme(theme);
    
    return Semantics(
      button: true,
      enabled: true,
      label: _getAccessibilityLabel(),
      hint: _getAccessibilityHint(),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_rippleAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Container(
              width: AppThemeConfig.largeTouchTarget * 2,
              height: AppThemeConfig.largeTouchTarget * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getButtonColor(theme),
                boxShadow: [
                  if (!isHighContrast)
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: widget.isListening ? 20 : 10,
                      spreadRadius: widget.isListening ? 5 : 0,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple effect for listening
                  if (widget.isListening)
                    Container(
                      width: AppThemeConfig.largeTouchTarget * 2 * _rippleAnimation.value,
                      height: AppThemeConfig.largeTouchTarget * 2 * _rippleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(
                            1.0 - _rippleAnimation.value,
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  
                  // Main button content
                  Transform.scale(
                    scale: widget.isProcessing ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: AppThemeConfig.largeTouchTarget * 1.5,
                      height: AppThemeConfig.largeTouchTarget * 1.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                        border: isHighContrast 
                            ? Border.all(
                                color: theme.colorScheme.onPrimary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Icon(
                        _getIcon(),
                        size: AppThemeConfig.textSizeXLarge + 8,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isHighContrastTheme(ThemeData theme) {
    return theme.colorScheme.background == AppThemeConfig.highContrastBackground;
  }

  Color _getButtonColor(ThemeData theme) {
    if (widget.isListening) {
      return theme.colorScheme.primary.withOpacity(0.1);
    }
    return theme.colorScheme.surface;
  }

  IconData _getIcon() {
    if (widget.isListening) {
      return Icons.stop;
    } else if (widget.isProcessing) {
      return Icons.hourglass_bottom;
    }
    return Icons.mic;
  }

  String _getAccessibilityLabel() {
    if (widget.isListening) {
      return 'Stop listening';
    } else if (widget.isProcessing) {
      return 'Processing your request';
    }
    return 'Start voice input';
  }

  String _getAccessibilityHint() {
    if (widget.isListening) {
      return 'Tap to stop listening';
    } else if (widget.isProcessing) {
      return 'Please wait while processing';
    }
    return 'Tap to start talking to PetitPal';
  }

  void _handleTap() {
    if (widget.isProcessing) return; // Don't allow interaction while processing
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Call the onPressed callback
    widget.onPressed();
  }
}
