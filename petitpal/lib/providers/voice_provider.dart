// lib/providers/voice_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../config/launch_config.dart';
import '../core/services/analytics_service.dart';

// Voice State
class VoiceState {
  final bool isListening;
  final bool isProcessing;
  final bool isSpeaking;
  final String recognizedText;
  final String? errorMessage;
  final bool isInitialized;
  
  const VoiceState({
    this.isListening = false,
    this.isProcessing = false,
    this.isSpeaking = false,
    this.recognizedText = '',
    this.errorMessage,
    this.isInitialized = false,
  });
  
  bool get hasError => errorMessage != null;
  
  VoiceState copyWith({
    bool? isListening,
    bool? isProcessing,
    bool? isSpeaking,
    String? recognizedText,
    String? errorMessage,
    bool? isInitialized,
  }) {
    return VoiceState(
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      recognizedText: recognizedText ?? this.recognizedText,
      errorMessage: errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// Voice Provider
class VoiceNotifier extends StateNotifier<VoiceState> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AnalyticsService _analytics;
  
  VoiceNotifier(this._analytics) : super(const VoiceState());
  
  Future<void> initialize() async {
    try {
      final speechAvailable = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );
      
      if (!speechAvailable) {
        state = state.copyWith(
          errorMessage: 'Speech recognition not available',
        );
        return;
      }
      
      await _initializeTts();
      
      state = state.copyWith(
        isInitialized: true,
        errorMessage: null,
      );
      
      if (LaunchConfig.analyticsEnabled) {
        _analytics.trackEvent('voice_initialized');
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to initialize voice: $e',
      );
    }
  }
  
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5); // Slower for seniors
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      state = state.copyWith(isSpeaking: false);
    });
    
    _flutterTts.setErrorHandler((message) {
      state = state.copyWith(
        isSpeaking: false,
        errorMessage: 'TTS Error: $message',
      );
    });
  }
  
  Future<void> startListening() async {
    if (!state.isInitialized) {
      await initialize();
    }
    
    if (!_speechToText.isAvailable) {
      state = state.copyWith(
        errorMessage: 'Speech recognition not available',
      );
      return;
    }
    
    state = state.copyWith(
      isListening: true,
      recognizedText: '',
      errorMessage: null,
    );
    
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
      listenMode: ListenMode.confirmation,
    );
    
    if (LaunchConfig.analyticsEnabled) {
      _analytics.trackEvent('voice_listening_started');
    }
  }
  
  Future<void> stopListening() async {
    await _speechToText.stop();
    state = state.copyWith(isListening: false);
    
    if (LaunchConfig.analyticsEnabled) {
      _analytics.trackEvent('voice_listening_stopped', {
        'recognized_text_length': state.recognizedText.length,
      });
    }
  }
  
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    state = state.copyWith(isSpeaking: true);
    await _flutterTts.speak(text);
    
    if (LaunchConfig.analyticsEnabled) {
      _analytics.trackEvent('voice_speaking', {
        'text_length': text.length,
      });
    }
  }
  
  void _onSpeechResult(result) {
    state = state.copyWith(
      recognizedText: result.recognizedWords,
      isProcessing: !result.finalResult,
    );
    
    if (result.finalResult) {
      state = state.copyWith(isListening: false);
      _processRecognizedText(result.recognizedWords);
    }
  }
  
  void _onSpeechError(error) {
    state = state.copyWith(
      isListening: false,
      isProcessing: false,
      errorMessage: 'Speech error: ${error.errorMsg}',
    );
    
    if (LaunchConfig.analyticsEnabled) {
      _analytics.trackEvent('speech_recognition_error', {
        'error_type': error.errorMsg,
      });
    }
  }
  
  void _onSpeechStatus(status) {
    // Handle speech status changes
    if (status == 'listening') {
      state = state.copyWith(isListening: true);
    } else if (status == 'notListening') {
      state = state.copyWith(isListening: false);
    }
  }
  
  Future<void> _processRecognizedText(String text) async {
    if (text.isEmpty) return;
    
    state = state.copyWith(isProcessing: true);
    
    try {
      // TODO: Send to LLM and get response
      // For now, just echo back
      final response = "I heard you say: $text";
      await speak(response);
      
      if (LaunchConfig.analyticsEnabled) {
        _analytics.trackEvent('question_processed', {
          'question_length': text.length,
        });
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to process speech: $e',
      );
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }
  
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider
final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  final analytics = ref.read(analyticsServiceProvider);
  return VoiceNotifier(analytics);
});

// Analytics Service Provider (placeholder)
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// lib/core/services/analytics_service.dart
class AnalyticsService {
  Future<void> trackEvent(String eventName, [Map<String, dynamic>? parameters]) async {
    // TODO: Implement Firebase Analytics
    if (LaunchConfig.verboseLogging) {
      print('Analytics Event: $eventName ${parameters ?? ''}');
    }
  }
}