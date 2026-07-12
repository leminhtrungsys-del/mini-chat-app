import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String myPhone;
  final VoidCallback onTap;

  const ChatTile({super.key, required this.chat, required this.myPhone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final other = chat.otherMember(myPhone);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF2563EB),
        child: Text(
          other.isNotEmpty ? other.substring(other.length - 2) : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(other, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        chat.lastMessagePreview.isEmpty ? 'Bắt đầu trò chuyện' : chat.lastMessagePreview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${chat.lastUpdated.hour.toString().padLeft(2, '0')}:${chat.lastUpdated.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(fontSize: 12, color: Colors.black45),
      ),
    );
  }
}
