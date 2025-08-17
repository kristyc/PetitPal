import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

class VoiceProviderState {
  final VoiceState state;
  final String recognizedText;
  final String lastError;
  final bool isListening;
  final bool isSpeaking;

  const VoiceProviderState({
    this.state = VoiceState.idle,
    this.recognizedText = '',
    this.lastError = '',
    this.isListening = false,
    this.isSpeaking = false,
  });

  VoiceProviderState copyWith({
    VoiceState? state,
    String? recognizedText,
    String? lastError,
    bool? isListening,
    bool? isSpeaking,
  }) {
    return VoiceProviderState(
      state: state ?? this.state,
      recognizedText: recognizedText ?? this.recognizedText,
      lastError: lastError ?? this.lastError,
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}

class VoiceNotifier extends StateNotifier<VoiceProviderState> {
  VoiceNotifier() : super(const VoiceProviderState());

  void startListening() {
    state = state.copyWith(
      state: VoiceState.listening,
      isListening: true,
      recognizedText: '',
      lastError: '',
    );
  }

  void stopListening() {
    state = state.copyWith(
      state: VoiceState.idle,
      isListening: false,
    );
  }

  void updateRecognizedText(String text) {
    state = state.copyWith(recognizedText: text);
  }

  void setProcessing() {
    state = state.copyWith(
      state: VoiceState.processing,
      isListening: false,
    );
  }

  void startSpeaking() {
    state = state.copyWith(
      state: VoiceState.speaking,
      isSpeaking: true,
    );
  }

  void stopSpeaking() {
    state = state.copyWith(
      state: VoiceState.idle,
      isSpeaking: false,
    );
  }

  void setError(String error) {
    state = state.copyWith(
      state: VoiceState.error,
      lastError: error,
      isListening: false,
      isSpeaking: false,
    );
  }

  void reset() {
    state = const VoiceProviderState();
  }
}

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceProviderState>((ref) {
  return VoiceNotifier();
});
