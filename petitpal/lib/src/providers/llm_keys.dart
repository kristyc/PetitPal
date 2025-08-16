import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LlmKeys {
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  static const _kOpenAI = 'llm_openai_key';
  static const _kGemini = 'llm_gemini_key';
  static const _kXAI = 'llm_xai_key';
  static const _kDeepSeek = 'llm_deepseek_key';
  static const _kSelected = 'llm_selected_provider';

  static Future<void> save({
    String? provider,
    String? openai,
    String? gemini,
    String? xai,
    String? deepseek,
  }) async {
    if (openai != null) await _storage.write(key: _kOpenAI, value: openai);
    if (gemini != null) await _storage.write(key: _kGemini, value: gemini);
    if (xai != null) await _storage.write(key: _kXAI, value: xai);
    if (deepseek != null) await _storage.write(key: _kDeepSeek, value: deepseek);
    if (provider != null) {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kSelected, provider);
    }
  }

  static Future<Map<String, String>> loadAll() async {
    final m = <String, String>{};
    final o = await _storage.read(key: _kOpenAI); if (o != null) m['openai'] = o;
    final g = await _storage.read(key: _kGemini); if (g != null) m['gemini'] = g;
    final x = await _storage.read(key: _kXAI); if (x != null) m['xai'] = x;
    final d = await _storage.read(key: _kDeepSeek); if (d != null) m['deepseek'] = d;
    return m;
  }

  static Future<String?> selectedProvider() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kSelected);
  }

  static Future<String?> keyFor(String provider) async {
    switch (provider) {
      case 'openai': return await _storage.read(key: _kOpenAI);
      case 'gemini': return await _storage.read(key: _kGemini);
      case 'xai': return await _storage.read(key: _kXAI);
      case 'deepseek': return await _storage.read(key: _kDeepSeek);
      default: return null;
    }
  }
}
