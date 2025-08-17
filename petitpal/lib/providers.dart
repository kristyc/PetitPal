import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/secure_storage.dart';

final openAiKeyProvider = StateNotifierProvider<OpenAiKeyController, String?>(
  (ref) => OpenAiKeyController()..load(),
);

class OpenAiKeyController extends StateNotifier<String?> {
  OpenAiKeyController() : super(null);
  Future<void> load() async {
    state = await SecureStore.getOpenAIKey();
  }
  Future<void> save(String key) async {
    await SecureStore.saveOpenAIKey(key);
    state = key.trim();
  }
}

final listeningProvider = StateProvider<bool>((ref) => false);
final transcriptProvider = StateProvider<String>((ref) => '');
final replyProvider = StateProvider<String>((ref) => '');
