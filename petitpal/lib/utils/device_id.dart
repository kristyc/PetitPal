import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceId {
  static const _key = 'device_id';
  static Future<String> get() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;
    const uuid = Uuid();
    final id = uuid.v4();
    await prefs.setString(_key, id);
    return id;
  }
}
