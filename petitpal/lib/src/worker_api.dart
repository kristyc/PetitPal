import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/internal_config.dart';
import 'providers/llm_keys.dart';

class WorkerApi {
  static String? _deviceId;
  static Future<String> _ensureDevice() async { _deviceId ??= const Uuid().v4(); return _deviceId!; }

  static Future<String?> chat({required String text}) async {
    final device = await _ensureDevice();
    final provider = await LlmKeys.selectedProvider() ?? 'openai';
    final key = await LlmKeys.keyFor(provider);
    final url = Uri.parse("${InternalConfig.workerBaseUrl}/api/chat");
    final r = await http.post(url,
      headers: {
        "Content-Type": "application/json",
        "X-Device-ID": device,
        "X-Provider": provider,
        if (key != null && key.isNotEmpty) "X-Api-Key": key,
      },
      body: jsonEncode({"text": text}),
    );
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return data["summary_tts"] ?? data["text"];
    } else {
      return "I couldn't get an answer right now. (${r.statusCode})";
    }
  }
}
