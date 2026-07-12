import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// LƯU Ý QUAN TRỌNG VỀ E2EE:
/// Đây là bản MÔ PHỎNG mã hóa đầu-cuối để demo cho mục đích học tập.
/// Khóa AES được suy ra (derive) trực tiếp từ chatId bằng SHA-256, nghĩa là
/// bất kỳ ai biết chatId (kể cả server Firestore nếu bị xâm nhập) đều có thể
/// tính lại được khóa. Đây KHÔNG phải E2EE thực sự vì khóa không nằm độc
/// quyền trên thiết bị người dùng.
///
/// Để nâng cấp lên E2EE thật:
/// 1. Mỗi thiết bị tự sinh cặp khóa ECDH (X25519) khi cài đặt lần đầu,
///    khóa riêng tư (private key) KHÔNG BAO GIỜ rời khỏi thiết bị.
/// 2. Trao đổi khóa công khai (public key) qua server, mỗi bên tự tính ra
///    một "shared secret" giống nhau mà server không biết được.
/// 3. Dùng shared secret đó làm khóa AES-GCM để mã hóa/giải mã từng tin nhắn.
/// Gợi ý package cho bước này: `cryptography` hoặc `pointycastle`.
class EncryptionService {
  static enc.Key _deriveKey(String chatId) {
    final hash = sha256.convert(utf8.encode('mini_chat_salt_$chatId'));
    return enc.Key(Uint8List.fromList(hash.bytes));
  }

  static String encryptText(String plainText, String chatId) {
    final key = _deriveKey(chatId);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String decryptText(String cipherPackage, String chatId) {
    try {
      final parts = cipherPackage.split(':');
      if (parts.length != 2) return '[Không thể giải mã]';
      final key = _deriveKey(chatId);
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (_) {
      return '[Không thể giải mã]';
    }
  }
}
