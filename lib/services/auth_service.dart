import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import 'key_service.dart';

/// Dịch vụ xác thực đơn giản dùng Firestore + SharedPreferences.
/// LƯU Ý: Đây là giải pháp DEMO, mật khẩu lưu dạng plaintext trong Firestore.
/// App thật cần dùng Firebase Auth hoặc hash mật khẩu (bcrypt/argon2) phía server.
class AuthService {
  final _db = FirebaseFirestore.instance;
  final _keyService = KeyService();
  static const _prefsPhoneKey = 'logged_in_phone';

  String _normalize(String phone) => phone.trim().replaceAll(RegExp(r'[^0-9+]'), '');

  Future<String?> register(String phone, String password, String displayName) async {
    final id = _normalize(phone);
    if (id.isEmpty || password.isEmpty || displayName.isEmpty) {
      return 'Vui lòng nhập đầy đủ thông tin';
    }
    final docRef = _db.collection('users').doc(id);
    final existing = await docRef.get();
    if (existing.exists) {
      return 'Số điện thoại này đã được đăng ký';
    }
    final user = AppUser(
      id: id,
      phone: id,
      displayName: displayName,
      password: password,
      createdAt: DateTime.now(),
    );
    await docRef.set(user.toMap());
    // Sinh cặp khóa E2EE cho thiết bị này và công bố public key lên Firestore.
    await _keyService.ensurePublished(id);
    await _saveSession(id);
    return null; // null = thành công
  }

  Future<String?> login(String phone, String password) async {
    final id = _normalize(phone);
    final doc = await _db.collection('users').doc(id).get();
    if (!doc.exists) {
      return 'Số điện thoại chưa được đăng ký';
    }
    final data = doc.data()!;
    if (data['password'] != password) {
      return 'Mật khẩu không đúng';
    }
    // Đảm bảo thiết bị này có khóa E2EE và public key đã được công bố
    // (trường hợp đăng nhập lần đầu trên thiết bị mới).
    await _keyService.ensurePublished(id);
    await _saveSession(id);
    return null;
  }

  /// Đặt lại mật khẩu mới cho một số điện thoại đã đăng ký.
  /// LƯU Ý: Vì app chưa dùng Blaze (không có SMS OTP thật), bước này
  /// chỉ xác minh số điện thoại đã tồn tại trong hệ thống rồi cho đặt
  /// mật khẩu mới trực tiếp - không có xác thực OTP. Đây là giải pháp
  /// tạm thời cho bản demo, không nên dùng cho ứng dụng thật.
  Future<String?> resetPassword(String phone, String newPassword) async {
    final id = _normalize(phone);
    if (id.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    if (newPassword.isEmpty || newPassword.length < 4) {
      return 'Mật khẩu mới phải có ít nhất 4 ký tự';
    }
    final docRef = _db.collection('users').doc(id);
    final doc = await docRef.get();
    if (!doc.exists) {
      return 'Số điện thoại chưa được đăng ký';
    }
    await docRef.update({'password': newPassword});
    return null;
  }

  Future<void> _saveSession(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsPhoneKey, phone);
  }

  Future<String?> getSessionPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsPhoneKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsPhoneKey);
  }

  Future<AppUser?> findUserByPhone(String phone) async {
    final id = _normalize(phone);
    final doc = await _db.collection('users').doc(id).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }
}
