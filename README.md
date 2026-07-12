# Mini Chat App (Flutter + Firebase Firestore)

Ứng dụng chat 1-1 tối giản: đăng ký/đăng nhập bằng số điện thoại, tìm người dùng
theo số điện thoại, chat real-time, tin nhắn được mã hóa (mô phỏng E2EE).

> ⚠️ Đây là bản DEMO để học tập. Xem mục "Giới hạn bảo mật" bên dưới trước khi
> dùng cho dữ liệu thật.

## 1. Cấu trúc dự án

```
lib/
  main.dart                  # Điểm khởi động, khởi tạo Firebase
  firebase_options.dart      # Sẽ được flutterfire configure ghi đè
  models/
    app_user.dart
    chat_model.dart
    message_model.dart
  services/
    auth_service.dart        # Đăng ký/đăng nhập qua Firestore
    chat_service.dart        # Tạo phòng chat, gửi/nhận tin nhắn real-time
    encryption_service.dart  # Mã hóa AES mô phỏng E2EE
  screens/
    login_screen.dart
    home_screen.dart
    search_screen.dart
    chat_screen.dart
  widgets/
    chat_bubble.dart
    chat_tile.dart
  utils/
    constants.dart
firestore.rules              # Rules Firestore (bản demo, cần siết lại khi lên production)
```

## 2. Cài đặt môi trường (làm 1 lần)

1. Cài Flutter SDK: https://docs.flutter.dev/get-started/install
   Kiểm tra: `flutter doctor` (đảm bảo Android toolchain OK).
2. Cài Node.js (để dùng Firebase CLI) rồi cài Firebase CLI:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```
3. Cài FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

## 3. Tạo dự án Flutter và dán mã nguồn

```bash
flutter create mini_chat_app
cd mini_chat_app
```

- Xoá toàn bộ nội dung thư mục `lib/` vừa tạo.
- Copy toàn bộ thư mục `lib/` và file `pubspec.yaml`, `firestore.rules` từ gói mã nguồn này vào đúng vị trí trong dự án `mini_chat_app` vừa tạo (ghi đè `pubspec.yaml`).

Cài dependencies:
```bash
flutter pub get
```

## 4. Tạo Firebase Project và bật Firestore

1. Vào https://console.firebase.google.com → **Add project** → đặt tên bất kỳ (VD: `mini-chat-demo`).
2. Trong project, vào **Build → Firestore Database → Create database** → chọn **Start in test mode** (hoặc production, vì ta sẽ tự deploy `firestore.rules`).
3. Chọn khu vực gần bạn (VD: `asia-southeast1`).

## 5. Kết nối Flutter app với Firebase project

Trong thư mục dự án (`mini_chat_app`), chạy:
```bash
flutterfire configure
```
- Chọn project Firebase vừa tạo.
- Khi được hỏi chọn platform, tick **android** (và ios/web nếu cần).
- Lệnh này sẽ tự động sinh lại file `lib/firebase_options.dart` với thông tin thật của project bạn (ghi đè file placeholder có sẵn) và tự thêm file cấu hình `android/app/google-services.json`.

## 6. Deploy Firestore rules

```bash
firebase init firestore
# Khi hỏi file rules, trỏ tới firestore.rules đã có sẵn (hoặc ghi đè theo)
firebase deploy --only firestore:rules
```

## 7. Chạy thử ứng dụng

Kết nối điện thoại Android (bật USB debugging) hoặc mở máy ảo (emulator), sau đó:
```bash
flutter run
```
Thử tạo 2 tài khoản với 2 số điện thoại khác nhau (2 thiết bị/2 emulator hoặc
2 lần cài app), tìm số điện thoại của nhau để bắt đầu chat.

## 8. Build file APK để cài đặt

Build bản release (khuyên dùng để cài thử máy thật):
```bash
flutter build apk --release
```
File APK xuất ra tại:
```
build/app/outputs/flutter-apk/app-release.apk
```
Copy file này sang điện thoại Android và cài đặt (cần bật "Cài đặt ứng dụng
không rõ nguồn gốc" trong Settings của điện thoại).

Nếu muốn 1 file APK universal thay vì tách theo kiến trúc CPU:
```bash
flutter build apk --release --target-platform android-arm,android-arm64,android-x64 --split-per-abi=false
```

## 8b. Build APK tự động qua GitHub Actions (KHÔNG cần cài Flutter trên máy bạn)

Dự án đã kèm sẵn file `.github/workflows/build-apk.yml`. Cách dùng:

1. Vẫn cần làm bước 5 (chạy `flutterfire configure` trên 1 máy có Flutter,
   HOẶC nhờ ai đó làm giúp) để có file `lib/firebase_options.dart` thật và
   thư mục `android/` với `google-services.json` — nếu chưa có 2 thứ này,
   workflow sẽ build lỗi vì thiếu cấu hình Firebase.
2. Tạo 1 repository mới (riêng tư hoặc công khai) trên https://github.com
3. Đẩy toàn bộ thư mục dự án (đã có `firebase_options.dart` + `android/google-services.json`) lên repo đó:
   ```bash
   git init
   git add .
   git commit -m "Mini chat app"
   git branch -M main
   git remote add origin https://github.com/<ten-ban>/<ten-repo>.git
   git push -u origin main
   ```
4. Vào tab **Actions** trên trang GitHub của repo → workflow "Build APK" sẽ tự chạy.
5. Khi chạy xong (khoảng 3-6 phút), vào job vừa chạy → mục **Artifacts** ở cuối trang → tải file `mini-chat-app-release-apk.zip` → giải nén ra là file `app-release.apk`, chép sang điện thoại để cài.

> Lưu ý: nếu chưa từng dùng git/GitHub, đây là bước duy nhất cần làm quen —
> không cần cài Flutter hay Android Studio trên máy bạn, GitHub sẽ build hộ.

## 9. Giới hạn bảo mật (đọc trước khi dùng thật)

- **Xác thực**: mật khẩu lưu dạng plaintext trong Firestore để demo đơn giản.
  App thật nên dùng Firebase Authentication (Phone Auth thật với OTP SMS, hoặc
  Email/Password) và không tự lưu mật khẩu.
- **Firestore rules**: bản kèm theo cho phép đọc/ghi tự do (`allow read, write: if true`)
  để chạy được ngay không cần đăng nhập Firebase Auth. Trước khi phát hành,
  cần bật Firebase Auth thật và đổi rules sang kiểm tra `request.auth != null`
  và so khớp `request.auth.uid` với thành viên của chat.
- **Mã hóa (E2EE)**: khóa AES trong `encryption_service.dart` được suy ra
  (derive) từ `chatId`, nghĩa là bất kỳ ai truy cập được Firestore đều có thể
  tính lại khóa và giải mã — đây là mã hóa "tại chỗ" (encryption at rest theo
  kiểu mô phỏng), KHÔNG phải E2EE thật. File đó có ghi chú chi tiết cách nâng
  cấp lên E2EE thật bằng trao đổi khóa ECDH (X25519) giữa 2 thiết bị.

## 10. Sự cố thường gặp

- `flutterfire configure` báo lỗi thiếu Android package name: mở
  `android/app/build.gradle`, kiểm tra `applicationId`, đảm bảo khớp khi tạo app
  Android trong Firebase console (thường flutterfire tự làm việc này).
- Build APK báo lỗi thiếu `google-services.json`: chạy lại bước 5
  (`flutterfire configure`) để chắc chắn file này được tạo trong
  `android/app/`.
- App chạy nhưng không nhận tin nhắn real-time: kiểm tra lại rules Firestore
  đã deploy đúng (bước 6) và thiết bị có kết nối internet.
