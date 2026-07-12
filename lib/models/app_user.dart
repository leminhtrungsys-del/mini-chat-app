class AppUser {
  final String id; // doc id = số điện thoại đã chuẩn hoá
  final String phone;
  final String displayName;
  final String password; // CHỈ DÙNG CHO DEMO - không lưu mật khẩu dạng plaintext trong app thật
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.phone,
    required this.displayName,
    required this.password,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'displayName': displayName,
        'password': password,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        id: id,
        phone: map['phone'] ?? '',
        displayName: map['displayName'] ?? '',
        password: map['password'] ?? '',
        createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      );
}
