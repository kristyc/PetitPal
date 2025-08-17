import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dev_settings.dart';

final listeningProvider = StateProvider<bool>((ref) => false);
final transcriptProvider = StateProvider<String>((ref) => '');
final replyProvider = StateProvider<String>((ref) => '');
final answeringProvider = StateProvider<bool>((ref) => false);

// API key storage; simple provider (Settings screen handles persistence)
final openAiKeyProvider = StateProvider<String?>((ref) => DevSettings.openAiKey);

final voiceProvider = StateNotifierProvider<VoiceController, String>(
  (ref) => VoiceController()..load(),
);

class VoiceController extends StateNotifier<String> {
  VoiceController() : super('alloy');
  static const _key = 'openai_tts_voice';
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? 'alloy';
  }
  Future<void> save(String voice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, voice);
    state = voice;
  }
}
