import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'encryption_service.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  /// Tin nhắn bị khóa (xóa) 30 phút sau khi NGƯỜI NHẬN đọc.
  static const readLockDuration = Duration(minutes: 30);

  /// Trần bảo mật cứng: dù chưa ai đọc, tin nhắn vẫn bị xóa sau 24 giờ.
  static const hardSecurityCeiling = Duration(hours: 24);

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

  /// Danh sách cuộc trò chuyện được LƯU LẠI vĩnh viễn (không bị ảnh hưởng
  /// bởi việc tin nhắn tự xóa), để người dùng không cần tìm số điện thoại
  /// lại từ đầu mỗi lần vào app.
  Stream<List<ChatModel>> streamChatsFor(String myPhone) {
    return _db
        .collection('chats')
        .where('members', arrayContains: myPhone)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatModel.fromMap(d.id, d.data())).toList());
  }

  /// Stream tin nhắn thô (chưa giải mã).
  /// - Tin đã quá hạn (now >= expireAt) bị lọc bỏ ngay phía client để
  ///   "biến mất" tức thì, ĐỒNG THỜI bị xóa CỨNG khỏi Firestore ngay lúc
  ///   này (không chờ TTL job chạy nền, có thể mất tới 24h) - đáp ứng yêu
  ///   cầu bảo mật "phải xóa khỏi bộ nhớ".
  /// - expireAt ban đầu = sentAt + 24h (trần bảo mật cứng).
  /// - Khi người nhận đọc tin (markRead), expireAt được RÚT NGẮN lại
  ///   thành readAt + 30 phút.
  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      final result = <MessageModel>[];
      for (final d in snap.docs) {
        final m = MessageModel.fromMap(d.id, d.data());
        if (now.isBefore(m.expireAt)) {
          result.add(m);
        } else {
          // Quá hạn (đã đọc quá 30 phút, hoặc quá trần bảo mật 24h):
          // xóa cứng khỏi Firestore ngay, không chờ TTL nền.
          d.reference.delete().catchError((_) {});
        }
      }
      return result;
    });
  }

  /// Gửi tin nhắn đã mã hóa bằng [sharedKey] (suy ra từ ECDH, xem KeyService).
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
      // Trần bảo mật cứng: xóa sau 24h dù chưa ai đọc.
      'expireAt': Timestamp.fromDate(now.add(hardSecurityCeiling)),
    });
    await chatRef.update({
      'lastMessagePreview': 'Tin nhắn đã mã hóa',
      'lastUpdated': now.toIso8601String(),
    });
  }

  /// Đánh dấu các tin nhắn của đối phương trong [chatId] là "đã xem" và
  /// RÚT NGẮN thời gian tồn tại còn 30 phút kể từ lúc này.
  Future<void> markRead(String chatId, List<MessageModel> messages, String myPhone) async {
    final now = DateTime.now();
    final newExpireAt = Timestamp.fromDate(now.add(readLockDuration));
    final batch = _db.batch();
    var any = false;
    for (final m in messages) {
      if (m.senderId != myPhone && m.readAt == null) {
        any = true;
        final ref = _db.collection('chats').doc(chatId).collection('messages').doc(m.id);
        batch.update(ref, {
          'readAt': now.toIso8601String(),
          'expireAt': newExpireAt,
        });
      }
    }
    if (any) await batch.commit();
  }
}
