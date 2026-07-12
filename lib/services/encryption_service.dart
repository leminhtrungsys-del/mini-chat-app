import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// Mã hóa/giải mã tin nhắn bằng AES-256-GCM, với khóa được suy ra từ ECDH
/// (X25519) giữa 2 thiết bị (xem KeyService). Đây là mã hóa đầu-cuối (E2EE)
/// THẬT: khóa dùng để giải mã không bao giờ được lưu hay gửi lên Firestore
/// hoặc bất kỳ server nào — chỉ tồn tại tạm thời trong bộ nhớ của từng thiết
/// bị khi đang mở màn hình chat. Firestore chỉ lưu phần văn bản đã mã hóa
/// (ciphertext), hoàn toàn vô nghĩa nếu không có khóa riêng tư của 1 trong 2
/// người tham gia cuộc trò chuyện.
class EncryptionService {
  static final AesGcm _algorithm = AesGcm.with256bits();

  static Future<String> encryptText(String plainText, SecretKey key) async {
    final nonce = _algorithm.newNonce();
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
    );
    final payload = {
      'n': base64Encode(secretBox.nonce),
      'c': base64Encode(secretBox.cipherText),
      'm': base64Encode(secretBox.mac.bytes),
    };
    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  static Future<String> decryptText(String cipherPackage, SecretKey key) async {
    try {
      final payload = jsonDecode(utf8.decode(base64Decode(cipherPackage))) as Map;
      final secretBox = SecretBox(
        base64Decode(payload['c'] as String),
        nonce: base64Decode(payload['n'] as String),
        mac: Mac(base64Decode(payload['m'] as String)),
      );
      final clear = await _algorithm.decrypt(secretBox, secretKey: key);
      return utf8.decode(clear);
    } catch (_) {
      return '[Không thể giải mã]';
    }
  }
}
