import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
    this.deliveredAt,
    this.readAt,
  });

  Widget _statusIcon() {
    if (readAt != null) {
      return const Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent);
    }
    if (deliveredAt != null) {
      return const Icon(Icons.done_all, size: 14, color: Colors.white70);
    }
    return const Icon(Icons.done, size: 14, color: Colors.white70);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppColors.bubbleMe : AppColors.bubbleOther,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.black45,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _statusIcon(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
