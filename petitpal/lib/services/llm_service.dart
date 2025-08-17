import 'dart:convert';
import 'dart:typed_data';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/device_id.dart';

class VoiceChatResult {
  final String? transcript;
  final String? reply;
  final List<int>? audioBytes;
  final String? audioMime;
  VoiceChatResult({this.transcript, this.reply, this.audioBytes, this.audioMime});
}

class LlmService {
  static Future<String> chat({
    required String text,
    required String openAiApiKey,
  }) async {
    final deviceId = await DeviceId.get();
    final url = Uri.parse('${AppConfig.normalizedWorkerBaseUrl}/api/chat');

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Device-ID': deviceId,
        'Authorization': 'Bearer ' + openAiApiKey.trim(),
      },
      body: jsonEncode({
        'text': text,
        'model': AppConfig.defaultModel,
      }),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['text'] as String? ?? '(No text)';
    } else if (resp.statusCode == 401) {
      throw Exception('Missing or invalid API key (401). Please set your key in Settings.');
    } else {
      throw Exception('LLM error: HTTP ${resp.statusCode} - ${resp.body}');
    }
  }

  static Future<VoiceChatResult> voiceChat({
    required Uint8List audio,
    required String mimeType,
    required String openAiApiKey,
  }) async {
    final deviceId = await DeviceId.get();
    final url = Uri.parse('${AppConfig.normalizedWorkerBaseUrl}/api/voice_chat');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': mimeType,
        'X-Device-ID': deviceId,
        'Authorization': 'Bearer ' + openAiApiKey.trim(),
      },
      body: audio,
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return VoiceChatResult(
        transcript: data['transcript'] as String?,
        reply: data['text'] as String?,
        audioBytes: (data['audio_b64'] as String?) != null ? base64Decode((data['audio_b64'] as String)) : null,
        audioMime: data['audio_mime'] as String?,
      );
    } else if (resp.statusCode == 401) {
      throw Exception('Missing or invalid API key (401). Please set your key in Settings.');
    } else {
      throw Exception('Voice chat error: HTTP ${resp.statusCode} - ${resp.body}');
    }
  }
}
