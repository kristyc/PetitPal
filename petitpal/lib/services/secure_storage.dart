import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _openAiKey = 'openai_api_key';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveOpenAIKey(String key) async {
    await _storage.write(key: _openAiKey, value: key.trim());
  }

  static Future<String?> getOpenAIKey() {
    return _storage.read(key: _openAiKey);
  }
}
