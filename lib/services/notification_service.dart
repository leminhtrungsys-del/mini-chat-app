import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Theo dõi tin nhắn mới trên TẤT CẢ cuộc trò chuyện của người dùng và
/// hiển thị thông báo hệ thống (local notification) khi có tin nhắn mới.
/// Nội dung tin nhắn KHÔNG bao giờ được đưa vào thông báo (giữ đúng cam kết
/// mã hóa đầu-cuối, tránh rò rỉ nội dung ra thanh thông báo).
///
/// LƯU Ý QUAN TRỌNG: Đây là thông báo cục bộ (local notification), CHỈ hoạt
/// động khi app đang chạy (foreground hoặc vừa chuyển nền gần đây). App
/// KHÔNG dùng Firebase Cloud Messaging (FCM) nên sẽ KHÔNG nhận được thông
/// báo nếu app đã bị tắt hẳn (vuốt khỏi danh sách ứng dụng gần đây) - việc
/// gửi push thật khi app đã tắt cần gói Blaze (Cloud Functions) để chạy
/// server gửi FCM.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _db = FirebaseFirestore.instance;
  bool _initialized = false;

  /// chatId của màn hình chat đang mở trực tiếp (nếu có) - dùng để không
  /// hiện thông báo cho cuộc trò chuyện người dùng đang xem.
  static String? currentOpenChatId;

  StreamSubscription? _chatsSub;
  final Map<String, StreamSubscription> _msgSubs = {};
  final Map<String, String> _lastSeenMessageId = {};

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> startListening(String myPhone) async {
    await init();
    await stopListening();
    _chatsSub = _db
        .collection('chats')
        .where('members', arrayContains: myPhone)
        .snapshots()
        .listen((chatsSnap) {
      for (final chatDoc in chatsSnap.docs) {
        final chatId = chatDoc.id;
        if (_msgSubs.containsKey(chatId)) continue;
        final members = List<String>.from(chatDoc.data()['members'] ?? []);
        final otherPhone = members.firstWhere((m) => m != myPhone, orElse: () => '');
        _msgSubs[chatId] = _db
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('sentAt', descending: true)
            .limit(1)
            .snapshots()
            .listen((msgSnap) => _onLatestMessage(chatId, otherPhone, myPhone, msgSnap));
      }
    });
  }

  void _onLatestMessage(
    String chatId,
    String otherPhone,
    String myPhone,
    QuerySnapshot<Map<String, dynamic>> msgSnap,
  ) {
    if (msgSnap.docs.isEmpty) return;
    final doc = msgSnap.docs.first;
    final data = doc.data();
    final senderId = data['senderId'] as String? ?? '';
    final prevId = _lastSeenMessageId[chatId];
    _lastSeenMessageId[chatId] = doc.id;

    // Lần đầu tải dữ liệu của cuộc trò chuyện này - chỉ ghi nhận, không
    // thông báo (tránh spam thông báo cho tin nhắn cũ khi vừa mở app).
    if (prevId == null) return;
    if (prevId == doc.id) return;
    if (senderId == myPhone) return; // tin nhắn của chính mình

    // Tin nhắn mới từ đối phương -> đánh dấu "đã nhận".
    doc.reference.update({'deliveredAt': DateTime.now().toIso8601String()}).catchError((_) {});

    // Nếu đang mở đúng cuộc trò chuyện này thì không cần bắn thông báo.
    if (currentOpenChatId == chatId) return;

    _showNotification(chatId, otherPhone);
  }

  Future<void> _showNotification(String chatId, String otherPhone) async {
    const androidDetails = AndroidNotificationDetails(
      'tchat_messages',
      'Tin nhắn mới',
      channelDescription: 'Thông báo khi có tin nhắn mới trong Tchat',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      chatId.hashCode,
      'Tchat',
      'Bạn có tin nhắn mới từ $otherPhone',
      details,
    );
  }

  Future<void> stopListening() async {
    await _chatsSub?.cancel();
    _chatsSub = null;
    for (final s in _msgSubs.values) {
      await s.cancel();
    }
    _msgSubs.clear();
    _lastSeenMessageId.clear();
  }
}
