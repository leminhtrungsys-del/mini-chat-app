import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý cặp khóa X25519 (ECDH) để mã hóa đầu-cuối (E2EE) THẬT.
///
/// Nguyên tắc quan trọng: khóa RIÊNG TƯ (private key) chỉ được sinh ra và
/// lưu trên chính thiết bị (SharedPreferences) — KHÔNG BAO GIỜ được gửi lên
/// Firestore hay bất kỳ server nào. Chỉ có khóa CÔNG KHAI (public key) mới
/// được công bố lên Firestore, vì public key vốn không cần giữ bí mật.
///
/// Khi 2 người dùng chat với nhau, mỗi bên tự tính ra một "shared secret"
/// giống hệt nhau bằng thuật toán ECDH (Diffie-Hellman trên đường cong
/// X25519), dựa trên: khóa riêng tư của MÌNH + khóa công khai của ĐỐI
/// PHƯƠNG. Giá trị shared secret này không bao giờ đi qua mạng — cả 2 thiết
/// bị tự tính ra cùng một kết quả một cách độc lập. Đây chính là bản chất
/// của E2EE thật, khác với bản mô phỏng derive-từ-chatId trước đây.
class KeyService {
  static const _privKeyPrefsKey = 'e2ee_private_key_v1';
  static const _pubKeyPrefsKey = 'e2ee_public_key_v1';

  final _algorithm = X25519();
  final _db = FirebaseFirestore.instance;

  Future<SimpleKeyPair> _getOrCreateKeyPair() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPriv = prefs.getString(_privKeyPrefsKey);
    final storedPub = prefs.getString(_pubKeyPrefsKey);
    if (storedPriv != null && storedPub != null) {
      return SimpleKeyPairData(
        base64Decode(storedPriv),
        publicKey: SimplePublicKey(base64Decode(storedPub), type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );
    }
    final keyPair = await _algorithm.newKeyPair();
    final privBytes = await keyPair.extractPrivateKeyBytes();
    final pubKey = await keyPair.extractPublicKey();
    await prefs.setString(_privKeyPrefsKey, base64Encode(privBytes));
    await prefs.setString(_pubKeyPrefsKey, base64Encode(pubKey.bytes));
    return keyPair;
  }

  /// Đảm bảo thiết bị hiện tại đã có cặp khóa, và khóa CÔNG KHAI đã được
  /// công bố lên Firestore để người khác có thể tính shared secret khi chat.
  Future<void> ensurePublished(String myPhoneId) async {
    final keyPair = await _getOrCreateKeyPair();
    final pubKey = await keyPair.extractPublicKey();
    await _db.collection('users').doc(myPhoneId).set(
      {'publicKey': base64Encode(pubKey.bytes)},
      SetOptions(merge: true),
    );
  }

  Future<SimplePublicKey?> getPublicKeyOf(String phoneId) async {
    final doc = await _db.collection('users').doc(phoneId).get();
    final data = doc.data();
    final raw = data == null ? null : data['publicKey'] as String?;
    if (raw == null) return null;
    return SimplePublicKey(base64Decode(raw), type: KeyPairType.x25519);
  }

  /// Tính khóa AES dùng chung cho 1 cuộc trò chuyện, suy ra từ ECDH giữa
  /// khóa riêng tư của mình và khóa công khai của [otherPhoneId].
  Future<SecretKey> deriveSharedKey(String otherPhoneId) async {
    final keyPair = await _getOrCreateKeyPair();
    final otherPublicKey = await getPublicKeyOf(otherPhoneId);
    if (otherPublicKey == null) {
      throw Exception(
          'Người dùng $otherPhoneId chưa có khóa công khai (chưa từng đăng nhập trên app).');
    }
    final sharedSecret = await _algorithm.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: otherPublicKey,
    );
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: const <int>[],
      info: utf8.encode('tchat-e2ee-v1'),
    );
  }
}
