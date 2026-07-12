class MessageModel {
  final String id;
  final String senderId;
  final String cipherText;
  final DateTime sentAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.cipherText,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'cipherText': cipherText,
        'sentAt': sentAt.toIso8601String(),
      };

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) => MessageModel(
        id: id,
        senderId: map['senderId'] ?? '',
        cipherText: map['cipherText'] ?? '',
        sentAt: DateTime.tryParse(map['sentAt'] ?? '') ?? DateTime.now(),
      );
}
