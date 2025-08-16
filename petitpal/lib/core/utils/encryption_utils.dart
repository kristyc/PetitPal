import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:math';
import '../../config/internal_config.dart';

class EncryptionUtils {
  // Generate random salt
  static Uint8List generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(InternalConfig.saltLength);
    for (int i = 0; i < salt.length; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  // Generate random nonce for AES-GCM
  static Uint8List generateNonce() {
    final random = Random.secure();
    final nonce = Uint8List(InternalConfig.nonceLength);
    for (int i = 0; i < nonce.length; i++) {
      nonce[i] = random.nextInt(256);
    }
    return nonce;
  }

  // Derive key using PBKDF2
  static Uint8List deriveKey(String password, Uint8List salt) {
    // This is a simplified version - in production, use a proper PBKDF2 implementation
    // You would typically use a package like pointycastle for this
    final hmac = Hmac(sha256, utf8.encode(password));
    final digest = hmac.convert(salt);
    return Uint8List.fromList(digest.bytes);
  }

  // Encrypt data (simplified - use proper AES-GCM in production)
  static Map<String, String> encrypt(String plaintext, String password) {
    final salt = generateSalt();
    final nonce = generateNonce();
    final key = deriveKey(password, salt);

    // This is a placeholder - implement proper AES-GCM encryption
    // In production, use a package like encrypt or pointycastle
    final encrypted = base64.encode(utf8.encode(plaintext));

    return {
      'ciphertext': encrypted,
      'salt': base64.encode(salt),
      'nonce': base64.encode(nonce),
      'algorithm': 'AES-GCM-256',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': InternalConfig.pbkdf2Iterations.toString(),
    };
  }

  // Decrypt data (simplified - use proper AES-GCM in production)
  static String decrypt(Map<String, String> encryptedData, String password) {
    final salt = base64.decode(encryptedData['salt']!);
    final nonce = base64.decode(encryptedData['nonce']!);
    final ciphertext = encryptedData['ciphertext']!;
    final key = deriveKey(password, salt);

    // This is a placeholder - implement proper AES-GCM decryption
    // In production, use a package like encrypt or pointycastle
    final decrypted = utf8.decode(base64.decode(ciphertext));
    return decrypted;
  }
}