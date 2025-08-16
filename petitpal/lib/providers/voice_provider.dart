import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/services/analytics_service.dart' as analytics;

// Voice state model
class VoiceState {
  final bool isListening;
  final bool isProcessing;
  final bool isSpeaking;
  final String recognizedText;
  final String? error;
  final bool hasPermission;
  final bool isInitialized;

  VoiceState({
    this.isListening = false,
    this.isProcessing = false,
    this.isSpeaking = false,
    this.recognizedText = '',
    this.error,
    this.hasPermission = false,
    this.isInitialized = false,
  });

  VoiceState copyWith({
    bool? isListening,
    bool? isProcessing,
    bool? isSpeaking,
    String? recognizedText,
    String? error,
    bool? hasPermission,
    bool? isInitialized,
  }) {
    return VoiceState(
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      recognizedText: recognizedText ?? this.recognizedText,
      error: error ?? this.error,
      hasPermission: hasPermission ?? this.hasPermission,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// Voice provider notifier
class VoiceNotifier extends StateNotifier<VoiceState> {
  VoiceNotifier() : super(VoiceState());

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  // Initialize voice services
  Future<void> initializeVoice() async {
    if (_isInitialized) return;

    try {
      // Request microphone permission
      final permissionStatus = await Permission.microphone.request();
      final hasPermission = permissionStatus == PermissionStatus.granted;

      if (!hasPermission) {
        state = state.copyWith(
          error: 'Microphone permission is required for voice features',
          hasPermission: false,
        );
        return;
      }

      // Initialize speech to text
      final speechAvailable = await _speechToText.initialize(
        onError: (error) {
          if (kDebugMode) {
            print('❌ Speech recognition error: ${error.errorMsg}');
          }
          state = state.copyWith(
            error: 'Speech recognition error: ${error.errorMsg}',
            isListening: false,
          );
          analytics.AnalyticsService().trackSpeechRecognitionError(error.errorMsg);
        },
        onStatus: (status) {
          if (kDebugMode) {
            print('🗣️ Speech status: $status');
          }
        },
      );

      if (!speechAvailable) {
        state = state.copyWith(
          error: 'Speech recognition not available on this device',
          hasPermission: hasPermission,
        );
        return;
      }

      // Initialize text to speech
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5); // Slower rate for seniors
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Set TTS callbacks
      _flutterTts.setStartHandler(() {
        state = state.copyWith(isSpeaking: true);
      });

      _flutterTts.setCompletionHandler(() {
        state = state.copyWith(isSpeaking: false);
      });

      _flutterTts.setErrorHandler((msg) {
        if (kDebugMode) {
          print('❌ TTS error: $msg');
        }
        state = state.copyWith(
          error: 'Text-to-speech error: $msg',
          isSpeaking: false,
        );
      });

      _isInitialized = true;
      state = state.copyWith(
        hasPermission: hasPermission,
        isInitialized: true,
        error: null,
      );

      if (kDebugMode) {
        print('✅ Voice services initialized successfully');
      }

    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize voice services: ${e.toString()}',
        hasPermission: false,
        isInitialized: false,
      );
      
      if (kDebugMode) {
        print('❌ Voice initialization failed: $e');
      }
    }
  }

  // Start listening for speech
  Future<void> startListening() async {
    if (!state.isInitialized || !state.hasPermission) {
      await initializeVoice();
      if (!state.isInitialized) return;
    }

    if (state.isListening) return;

    try {
      state = state.copyWith(
        isListening: true,
        recognizedText: '',
        error: null,
      );

      await _speechToText.listen(
        onResult: (result) {
          state = state.copyWith(
            recognizedText: result.recognizedWords,
          );
          
          if (result.finalResult) {
            _handleSpeechResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        onSoundLevelChange: (level) {
          // Could be used for visual feedback
        },
      );

      // Track analytics
      analytics.AnalyticsService().trackVoiceInteractionStart();

    } catch (e) {
      state = state.copyWith(
        isListening: false,
        error: 'Failed to start listening: ${e.toString()}',
      );
      
      if (kDebugMode) {
        print('❌ Failed to start listening: $e');
      }
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (!state.isListening) return;

    try {
      await _speechToText.stop();
      state = state.copyWith(isListening: false);
      
      if (kDebugMode) {
        print('🛑 Stopped listening');
      }
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        error: 'Failed to stop listening: ${e.toString()}',
      );
    }
  }

  // Handle speech recognition result
  void _handleSpeechResult(String recognizedText) async {
    if (recognizedText.trim().isEmpty) return;

    state = state.copyWith(
      isListening: false,
      isProcessing: true,
    );

    try {
      // TODO: Process the recognized text with LLM
      // For now, just echo back the text
      final response = 'You said: $recognizedText';
      
      await speak(response);
      
      // Track analytics
      analytics.AnalyticsService().trackQuestionAsked('echo', recognizedText.length);
      analytics.AnalyticsService().trackVoiceInteractionComplete(true);
      
      state = state.copyWith(isProcessing: false);
      
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to process speech: ${e.toString()}',
      );
      
      analytics.AnalyticsService().trackVoiceInteractionComplete(false);
      
      if (kDebugMode) {
        print('❌ Failed to process speech: $e');
      }
    }
  }

  // Speak text using TTS
  Future<void> speak(String text) async {
    if (!state.isInitialized) {
      await initializeVoice();
      if (!state.isInitialized) return;
    }

    try {
      // Stop any current speech
      await _flutterTts.stop();
      
      // Speak the text
      await _flutterTts.speak(text);
      
      // Track analytics
      analytics.AnalyticsService().trackTtsSpoken('flutter_tts', text.length);
      
      if (kDebugMode) {
        print('🔊 Speaking: $text');
      }
      
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to speak: ${e.toString()}',
        isSpeaking: false,
      );
      
      if (kDebugMode) {
        print('❌ Failed to speak: $e');
      }
    }
  }

  // Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      state = state.copyWith(isSpeaking: false);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to stop speaking: $e');
      }
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Dispose resources
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
  }
}

// Provider definition
final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  return VoiceNotifier();
});

// Convenience providers
final isListeningProvider = Provider<bool>((ref) {
  return ref.watch(voiceProvider).isListening;
});

final recognizedTextProvider = Provider<String>((ref) {
  return ref.watch(voiceProvider).recognizedText;
});

final hasVoicePermissionProvider = Provider<bool>((ref) {
  return ref.watch(voiceProvider).hasPermission;
});
