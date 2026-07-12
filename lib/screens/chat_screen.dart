import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/encryption_service.dart';
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
  bool _sending = false;

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    await _chatService.sendMessage(widget.chatId, widget.myPhone, text);
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
                Text('Tin nhắn được mã hóa', style: TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.streamMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text('Hãy gửi tin nhắn đầu tiên!'));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final plainText = EncryptionService.decryptText(m.cipherText, widget.chatId);
                    final isMe = m.senderId == widget.myPhone;
                    final time =
                        '${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}';
                    return ChatBubble(text: plainText, isMe: isMe, time: time);
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
}
