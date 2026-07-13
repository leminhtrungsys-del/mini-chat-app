import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String cipherText;
  final DateTime sentAt;

  /// Thời điểm tin nhắn hết hạn và bị xóa cứng khỏi Firestore.
  /// Ban đầu = sentAt + 24h (trần bảo mật cứng). Khi người nhận đọc tin,
  /// giá trị này được rút ngắn lại thành readAt + 30 phút.
  final DateTime expireAt;

  /// Thời điểm tin nhắn đồng bộ tới thiết bị người nhận ("đã nhận").
  final DateTime? deliveredAt;

  /// Thời điểm người nhận mở và xem tin nhắn ("đã xem").
  final DateTime? readAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.cipherText,
    required this.sentAt,
    required this.expireAt,
    this.deliveredAt,
    this.readAt,
  });

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'cipherText': cipherText,
        'sentAt': sentAt.toIso8601String(),
      };

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    final expireRaw = map['expireAt'];
    final expireAt = expireRaw is Timestamp
        ? expireRaw.toDate()
        : DateTime.now().add(const Duration(hours: 24));
    final deliveredRaw = map['deliveredAt'];
    final readRaw = map['readAt'];
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      cipherText: map['cipherText'] ?? '',
      sentAt: DateTime.tryParse(map['sentAt'] ?? '') ?? DateTime.now(),
      expireAt: expireAt,
      deliveredAt: deliveredRaw is String ? DateTime.tryParse(deliveredRaw) : null,
      readAt: readRaw is String ? DateTime.tryParse(readRaw) : null,
    );
  }
}
