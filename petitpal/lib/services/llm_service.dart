import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../utils/markdown.dart';
import '../config/app_config.dart';

class VoiceChatResult {
  final String? transcript;
  final String? reply;
  final Uint8List? audioBytes;
  final String? audioMime;
  VoiceChatResult({this.transcript, this.reply, this.audioBytes, this.audioMime});
}

class LlmService {
  /// Verify key via the worker's /api/verify_key endpoint.
  static Future<bool> verifyApiKey({required String openAiApiKey}) async {
    final base = AppConfig.normalizedWorkerBaseUrl;
    final uri = Uri.parse('$base/api/verify_key');
    try {
      final r = await http.get(uri, headers: {
        'Authorization': 'Bearer $openAiApiKey',
      });
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Voice sample via GET /api/tts_sample?voice=...&text=...
  static Future<Uint8List> ttsSample({
    required String openAiApiKey,
    required String voice,
    required String text,
  }) async {
    final base = AppConfig.normalizedWorkerBaseUrl;
    final uri = Uri.parse('$base/api/tts_sample?voice=${Uri.encodeComponent(voice)}&text=${Uri.encodeComponent(text)}');
    final r = await http.get(uri, headers: {
      'Authorization': 'Bearer $openAiApiKey',
      'Accept': 'audio/mpeg,application/json',
    });
    if (r.statusCode != 200) {
      throw Exception('TTS sample error: HTTP ${r.statusCode} - ${r.body}');
    }
    return Uint8List.fromList(r.bodyBytes);
  }

  /// Send recorded audio bytes to /api/voice_chat (octet-stream).
  static Future<VoiceChatResult> voiceChat({
    required List<int> audio,
    required String mimeType, // e.g. 'audio/aac' or 'audio/m4a'
    required String openAiApiKey,
    String? voice,
    String? appLocale, // pass like 'en-US' when available
  }) async {
    final base = AppConfig.normalizedWorkerBaseUrl;
    final uri = Uri.parse('$base/api/voice_chat');

    final r = await http.post(uri,
      headers: {
        'Authorization': 'Bearer $openAiApiKey',
        'Content-Type': mimeType,
        if (voice != null) 'X-TTS-Voice': voice,
        if (appLocale != null) 'X-App-Locale': appLocale,
        'Accept': 'application/json',
      },
      body: Uint8List.fromList(audio),
    );

    if (r.statusCode != 200) {
      throw Exception('Worker /api/voice_chat error: HTTP ${r.statusCode} - ${r.body}');
    }

    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;

    final reply = MarkdownUtils.clean((data['text'] as String?) ?? '');
    final transcript = data['transcript'] as String?;

    Uint8List? audioBytes;
    final a = data['audio_b64'];
    if (a is String) {
      audioBytes = Uint8List.fromList(base64.decode(a));
    }
    final audioMime = data['audio_mime'] as String?;

    return VoiceChatResult(transcript: transcript, reply: reply, audioBytes: audioBytes, audioMime: audioMime);
  }
}
