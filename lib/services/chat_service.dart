import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'encryption_service.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

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

  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> sendMessage(String chatId, String senderId, String plainText) async {
    final cipherText = EncryptionService.encryptText(plainText, chatId);
    final chatRef = _db.collection('chats').doc(chatId);
    await chatRef.collection('messages').add({
      'senderId': senderId,
      'cipherText': cipherText,
      'sentAt': DateTime.now().toIso8601String(),
    });
    await chatRef.update({
      'lastMessagePreview': 'Tin nhắn đã mã hóa',
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }
}
