import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../utils/constants.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  final String myPhone;
  const SearchScreen({super.key, required this.myPhone});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _auth = AuthService();
  final _chatService = ChatService();
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final phone = _ctrl.text.trim();
    if (phone.isEmpty) return;
    if (phone == widget.myPhone) {
      setState(() => _error = 'Bạn không thể nhắn tin cho chính mình');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = await _auth.findUserByPhone(phone);
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Không tìm thấy người dùng với số điện thoại này';
      });
      return;
    }
    final chatId = await _chatService.getOrCreateChat(widget.myPhone, user.phone);
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            ChatScreen(chatId: chatId, myPhone: widget.myPhone, otherPhone: user.phone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tìm người dùng'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nhập số điện thoại',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _search,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Tìm & Bắt đầu chat', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
