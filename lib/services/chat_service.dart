import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'encryption_service.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  /// Tin nhắn tự động biến mất sau khoảng thời gian này.
  static const messageLifetime = Duration(minutes: 30);

  String _chatIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<String> getOrCreateChat(String myPhone, String otherPhone) async {
    final chatId = _chatIdFor(myPhone, otherPhone);
    final chatRef = _db.collection('chats').doc(chatId);
    final existing = await chatRef.get();
    if (!existing.exists) {
      await chatRef.set({
        'members': [myPhone, otherPhone],
        'lastMessagePreview': '',
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }
    return chatId;
  }

  Stream<List<ChatModel>> streamChatsFor(String myPhone) {
    return _db
        .collection('chats')
        .where('members', arrayContains: myPhone)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatModel.fromMap(d.id, d.data())).toList());
  }

  /// Stream tin nhắn thô (chưa giải mã). Tin đã quá hạn (> messageLifetime)
  /// sẽ bị lọc bỏ ngay phía client để "biến mất" tức thì, đồng thời Firestore
  /// TTL policy (cấu hình trên field `expireAt`) sẽ tự xóa vĩnh viễn khỏi
  /// database trong vòng tối đa 24 giờ sau khi hết hạn.
  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.id, d.data()))
            .where((m) => DateTime.now().difference(m.sentAt) < messageLifetime)
            .toList());
  }

  /// Gửi tin nhắn đã mã hóa bằng [sharedKey] (suy ra từ ECDH, xem KeyService).
  /// Kèm field `expireAt` (Timestamp) để Firestore TTL tự xóa sau khi hết hạn.
  Future<void> sendMessage(
    String chatId,
    String senderId,
    String plainText,
    SecretKey sharedKey,
  ) async {
    final cipherText = await EncryptionService.encryptText(plainText, sharedKey);
    final now = DateTime.now();
    final chatRef = _db.collection('chats').doc(chatId);
    await chatRef.collection('messages').add({
      'senderId': senderId,
      'cipherText': cipherText,
      'sentAt': now.toIso8601String(),
      'expireAt': Timestamp.fromDate(now.add(messageLifetime)),
    });
    await chatRef.update({
      'lastMessagePreview': 'Tin nhắn đã mã hóa',
      'lastUpdated': now.toIso8601String(),
    });
  }
}
