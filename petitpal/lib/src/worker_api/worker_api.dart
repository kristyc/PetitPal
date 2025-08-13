import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class WorkerApi {
  static Future<Map<String, dynamic>> createInvite(String deviceId, String memberName) async {
    final r = await http.post(Uri.parse('${ApiConfig.baseUrl}/api/family/create_invite'),
      headers: {'Content-Type': 'application/json','X-Device-ID': deviceId},
      body: jsonEncode({'member_name': memberName}));
    if (r.statusCode != 200) { throw Exception('create_invite failed ${r.statusCode} ${r.body}'); }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> acceptInvite(String deviceId, String inviteToken) async {
    final r = await http.post(Uri.parse('${ApiConfig.baseUrl}/api/family/accept_invite'),
      headers: {'Content-Type': 'application/json','X-Device-ID': deviceId},
      body: jsonEncode({'invite_token': inviteToken}));
    if (r.statusCode != 200) { throw Exception('accept_invite failed ${r.statusCode} ${r.body}'); }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> saveEncryptedBackup(String deviceId, Map<String, dynamic> payload) async {
    final r = await http.post(Uri.parse('${ApiConfig.baseUrl}/api/keys/save'),
      headers: {'Content-Type': 'application/json','X-Device-ID': deviceId},
      body: jsonEncode(payload));
    if (r.statusCode != 200) { throw Exception('keys/save failed ${r.statusCode} ${r.body}'); }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
