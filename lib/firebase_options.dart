// File này được cập nhật với thông tin Firebase project thật (mini-chat-demo).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Chưa cấu hình cho Web. Hãy chạy flutterfire configure.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Nền tảng chưa được hỗ trợ. Hãy chạy flutterfire configure.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCdBNObTIxplRbRLglG7JmmZ_TCa_UHuo8',
    appId: '1:1084260212587:android:474a0dc852c08d22d8b62e',
    messagingSenderId: '1084260212587',
    projectId: 'mini-chat-demo',
    storageBucket: 'mini-chat-demo.firebasestorage.app',
  );
}
