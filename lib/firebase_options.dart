// File này thường được TỰ ĐỘNG SINH RA khi bạn chạy lệnh `flutterfire configure`.
// Nội dung placeholder dưới đây sẽ bị ghi đè - hãy chạy flutterfire configure
// theo hướng dẫn trong README.md TRƯỚC KHI build ứng dụng thật.
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
    apiKey: 'THAY_BANG_API_KEY_CUA_BAN',
    appId: 'THAY_BANG_APP_ID_CUA_BAN',
    messagingSenderId: 'THAY_BANG_SENDER_ID',
    projectId: 'THAY_BANG_PROJECT_ID',
    storageBucket: 'THAY_BANG_PROJECT_ID.appspot.com',
  );
}
