import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/internal_config.dart';

class WorkerApi {
  final String deviceId;
  WorkerApi(this.deviceId);

  Map<String, String> _headers({Map<String, String>? extra}) => {
    "Content-Type": "application/json",
    "X-Device-ID": deviceId,
    ...?extra,
  };

  Future<Map<String, dynamic>> health() async {
    final r = await http.get(Uri.parse("${InternalConfig.workerBaseUrl}/health"));
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveEncryptedBackup(Map<String, dynamic> encrypted) async {
    final r = await http.post(
      Uri.parse("${InternalConfig.workerBaseUrl}/api/keys/save"),
      headers: _headers(),
      body: jsonEncode(encrypted),
    );
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> chat({
    required String text,
    String? providerHint,
    Map<String, String>? liveKeys, // TEMP: keys passed only for the live call; never stored
  }) async {
    final body = {
      "text": text,
      if (providerHint != null) "provider_hint": providerHint,
      if (liveKeys != null) "live_keys": liveKeys,
    };
    final r = await http.post(
      Uri.parse("${InternalConfig.workerBaseUrl}/api/chat"),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
