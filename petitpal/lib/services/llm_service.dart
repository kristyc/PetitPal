import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

import '../config.dart';
import '../utils/device_id.dart'; // assumes you have a DeviceId.get() util

class VoiceChatResult {
  final String? transcript;
  final String? reply;
  final List<int>? audioBytes;
  final String? audioMime;
  VoiceChatResult({this.transcript, this.reply, this.audioBytes, this.audioMime});
}

class LlmService {
  static String _localeTag() {
    final l = ui.PlatformDispatcher.instance.locale;
    final country = l.countryCode ?? '';
    return country.isEmpty ? l.languageCode : '${l.languageCode}-${country}';
  }

  static Future<VoiceChatResult> voiceChat({
    required Uint8List audio,
    required String mimeType,
    required String openAiApiKey,
    String? voice,
  }) async {
    final deviceId = await DeviceId.get();
    final url = Uri.parse('${AppConfig.normalizedWorkerBaseUrl}/api/voice_chat');
    final resp = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ' + openAiApiKey.trim(),
        'Content-Type': mimeType,
        'X-Device-ID': deviceId,
        'X-App-Locale': _localeTag(),
        'X-TTS-Voice': voice ?? 'alloy',
      },
      body: audio,
    );
    if (resp.statusCode != 200) {
      throw Exception('voice_chat HTTP ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return VoiceChatResult(
      transcript: data['transcript'] as String?,
      reply: data['text'] as String?,
      audioBytes: (data['audio_b64'] as String?) != null ? base64Decode(data['audio_b64'] as String) : null,
      audioMime: data['audio_mime'] as String?,
    );
  }

  static Future<Uint8List> ttsSample({
    required String openAiApiKey,
    required String voice,
    String? text,
  }) async {
    final deviceId = await DeviceId.get();
    final url = Uri.parse('${AppConfig.normalizedWorkerBaseUrl}/api/tts_sample?voice=${Uri.encodeComponent(voice)}&text=${Uri.encodeComponent(text ?? "This is a sample.")}');
    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer ' + openAiApiKey.trim(),
      'X-Device-ID': deviceId,
    });
    if (resp.statusCode == 200) {
      return resp.bodyBytes;
    } else {
      throw Exception('TTS sample error: HTTP ${resp.statusCode} - ${resp.body}');
    }
  }
}
