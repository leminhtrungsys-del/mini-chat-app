import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import '../utils/constants.dart';
import '../widgets/chat_tile.dart';
import 'login_screen.dart';
import 'search_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  final _chatService = ChatService();
  String? _myPhone;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final phone = await _auth.getSessionPhone();
    if (phone == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    setState(() => _myPhone = phone);
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_myPhone == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trò chuyện'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SearchScreen(myPhone: _myPhone!)),
          );
        },
        child: const Icon(Icons.search, color: Colors.white),
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: _chatService.streamChatsFor(_myPhone!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có cuộc trò chuyện nào.\nNhấn nút tìm kiếm để bắt đầu.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatTile(
                chat: chat,
                myPhone: _myPhone!,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat.id,
                        myPhone: _myPhone!,
                        otherPhone: chat.otherMember(_myPhone!),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
