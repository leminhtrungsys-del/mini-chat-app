import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import '../services/chat_service.dart';
import '../services/encryption_service.dart';
import '../services/key_service.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String myPhone;
  final String otherPhone;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.myPhone,
    required this.otherPhone,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _chatService = ChatService();
  final _keyService = KeyService();
  bool _sending = false;
  SecretKey? _sharedKey;
  String? _keyError;

  @override
  void initState() {
    super.initState();
    _loadSharedKey();
  }

  Future<void> _loadSharedKey() async {
    try {
      await _keyService.ensurePublished(widget.myPhone);
      final key = await _keyService.deriveSharedKey(widget.otherPhone);
      if (!mounted) return;
      setState(() => _sharedKey = key);
    } catch (e) {
      if (!mounted) return;
      setState(() => _keyError = e.toString());
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending || _sharedKey == null) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    await _chatService.sendMessage(widget.chatId, widget.myPhone, text, _sharedKey!);
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.otherPhone),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.lock, size: 12, color: Colors.black45),
                SizedBox(width: 4),
                Text(
                  'Mã hóa đầu-cuối (E2EE) · Tự xóa sau 30 phút',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_keyError != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Không thể thiết lập mã hóa: $_keyError',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _sharedKey == null && _keyError == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<MessageModel>>(
                    stream: _chatService.streamMessages(widget.chatId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final rawMessages = snapshot.data ?? [];
                      if (rawMessages.isEmpty) {
                        return const Center(child: Text('Hãy gửi tin nhắn đầu tiên!'));
                      }
                      if (_sharedKey == null) {
                        return const Center(child: Text('Chưa thể giải mã tin nhắn.'));
                      }
                      return FutureBuilder<List<_DecryptedMessage>>(
                        future: _decryptAll(rawMessages, _sharedKey!),
                        builder: (context, decryptedSnap) {
                          if (!decryptedSnap.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final messages = decryptedSnap.data!;
                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final m = messages[index];
                              final isMe = m.senderId == widget.myPhone;
                              final time =
                                  '${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}';
                              return ChatBubble(text: m.plainText, isMe: isMe, time: time);
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<_DecryptedMessage>> _decryptAll(
    List<MessageModel> raw,
    SecretKey key,
  ) async {
    final result = <_DecryptedMessage>[];
    for (final m in raw) {
      final plain = await EncryptionService.decryptText(m.cipherText, key);
      result.add(_DecryptedMessage(senderId: m.senderId, plainText: plain, sentAt: m.sentAt));
    }
    return result;
  }
}

class _DecryptedMessage {
  final String senderId;
  final String plainText;
  final DateTime sentAt;

  _DecryptedMessage({required this.senderId, required this.plainText, required this.sentAt});
}
