import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Keystore {
  static const _storage = FlutterSecureStorage();

  static Future<String> deviceSecret() async {
    final existing = await _storage.read(key: 'device_secret');
    if (existing != null) return existing;
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final b64 = base64Encode(bytes);
    await _storage.write(key: 'device_secret', value: b64);
    return b64;
  }

  static Future<Map<String, dynamic>> encrypt(String plaintext) async {
    final secretB64 = await deviceSecret();
    final secret = base64Decode(secretB64);
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 500000, bits: 256);
    final newKey = await pbkdf2.deriveKey(secretKey: SecretKey(secret), nonce: salt);
    final aes = AesGcm.with256bits();
    final secretKey = await newKey.extractBytes();
    final cipher = await aes.encrypt(utf8.encode(plaintext), secretKey: SecretKey(secretKey), nonce: nonce);
    return {
      'ciphertext': base64Encode(cipher.cipherText),
      'nonce': base64Encode(nonce),
      'salt': base64Encode(salt),
      'algo': 'AES-GCM-256',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': 500000,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static List<int> _randomBytes(int n) {
    final r = Random.secure();
    return List<int>.generate(n, (_) => r.nextInt(256));
  }
}
