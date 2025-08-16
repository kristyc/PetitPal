// lib/src/voice/voice_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../config/strings_config.dart';
import '../../config/theme_config.dart';
import '../../providers/voice_provider.dart';
import '../widgets/speech_preview_widget.dart';
import '../widgets/voice_button_widget.dart';

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVoice();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: AppThemeConfig.animationDuration,
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeVoice() async {
    try {
      final hasPermission = await _ensureMicPermission();
      if (hasPermission) {
        await ref.read(voiceProvider.notifier).initialize();
      } else {
        _showPermissionError();
      }
    } catch (e) {
      _handleVoiceError(e.toString());
    }
  }

  // Fixed: Explicitly return bool from async function
  Future<bool> _ensureMicPermission() async {
    try {
      final status = await Permission.microphone.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      }
      
      if (status.isPermanentlyDenied) {
        await _showPermissionDialog();
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('Permission error: $e');
      return false;
    }
  }

  Future<void> _showPermissionDialog() async {
    if (!mounted) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(StringsConfig.permissionDialogTitle),
          content: Text(StringsConfig.permissionDialogMessage),
          actions: <Widget>[
            TextButton(
              child: Text(StringsConfig.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(StringsConfig.openSettings),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionError() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(StringsConfig.microphonePermissionError),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: StringsConfig.tryAgain,
          onPressed: _initializeVoice,
        ),
      ),
    );
  }

  void _handleVoiceError(String error) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${StringsConfig.voiceError}: $error'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _startListening() async {
    try {
      final hasPermission = await _ensureMicPermission();
      if (!hasPermission) {
        _showPermissionError();
        return;
      }

      await ref.read(voiceProvider.notifier).startListening();
      _animationController.repeat(reverse: true);
    } catch (e) {
      _handleVoiceError(e.toString());
    }
  }

  Future<void> _stopListening() async {
    try {
      await ref.read(voiceProvider.notifier).stopListening();
      _animationController.stop();
      _animationController.reset();
    } catch (e) {
      _handleVoiceError(e.toString());
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppThemeConfig.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Title
              Text(
                StringsConfig.appTitle,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: AppThemeConfig.spacingXLarge),
              
              // Speech Preview Widget
              SpeechPreviewWidget(
                recognizedText: voiceState.recognizedText,
                isListening: voiceState.isListening,
                isProcessing: voiceState.isProcessing,
              ),
              
              SizedBox(height: AppThemeConfig.spacingXLarge),
              
              // Voice Button
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: voiceState.isListening ? _pulseAnimation.value : 1.0,
                    child: VoiceButtonWidget(
                      isListening: voiceState.isListening,
                      isProcessing: voiceState.isProcessing,
                      onPressed: voiceState.isListening ? _stopListening : _startListening,
                    ),
                  );
                },
              ),
              
              SizedBox(height: AppThemeConfig.spacingLarge),
              
              // Status Text
              Text(
                _getStatusText(voiceState),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: AppThemeConfig.spacingMedium),
              
              // Error Display
              if (voiceState.hasError)
                Container(
                  padding: EdgeInsets.all(AppThemeConfig.paddingMedium),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppThemeConfig.borderRadius),
                  ),
                  child: Text(
                    voiceState.errorMessage ?? StringsConfig.unknownError,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(VoiceState voiceState) {
    if (voiceState.hasError) {
      return StringsConfig.voiceErrorOccurred;
    }
    
    if (voiceState.isProcessing) {
      return StringsConfig.processing;
    }
    
    if (voiceState.isListening) {
      return StringsConfig.listening;
    }
    
    if (voiceState.isSpeaking) {
      return StringsConfig.speaking;
    }
    
    return StringsConfig.tapToTalk;
  }
}