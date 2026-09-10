# Sổ liên lạc — app theo dõi tiến độ học tập

App Android (Flutter) cho ba vai trò: **phụ huynh**, **học sinh**, **quản trị**.

- **Phụ huynh** xem báo cáo học tập từng ngày của con, tách theo hạng mục *bài tập
  trên lớp* và *bài tập học thêm* (gom tiếp theo từng thầy cô), nhập/sửa thời khóa
  biểu, và gửi nhắc nhở lên app của con.
- **Học sinh** nhập thời khóa biểu, viết báo cáo hằng ngày kèm ảnh bài làm (không
  bắt buộc), cập nhật trạng thái, và đọc lời nhắc của bố mẹ.
- **Quản trị** quản lý tài khoản, khóa/mở, liên kết phụ huynh với học sinh, và
  xem danh mục môn học cùng thầy cô.

Hướng thiết kế và lý do đằng sau từng quyết định: xem [DESIGN.md](DESIGN.md).

## Chạy thử

```bash
flutter pub get
flutter run              # cắm máy Android hoặc mở emulator
flutter run -d chrome    # xem nhanh trên trình duyệt
```

Lần chạy đầu cần mạng vì `google_fonts` tải font về máy. Muốn chạy hoàn toàn
offline thì tải file `.ttf` của Be Vietnam Pro và Bricolage Grotesque vào
`assets/fonts/`, khai báo trong `pubspec.yaml`, rồi đổi `AppType` sang dùng
`TextStyle(fontFamily: ...)`.

Ở màn mở app, chọn vai trò là vào thẳng — chưa có bước đăng nhập vì tầng dữ liệu
đang là bản mock.

## Trạng thái hiện tại

Đợt này dựng **design system + toàn bộ màn hình cho ba vai trò**, chạy trên dữ
liệu mẫu trong bộ nhớ (`lib/data/mock/seed.dart` — lớp 9A2, hai tuần báo cáo,
tám thầy cô, trong đó ba người dạy thêm).

Thao tác thêm/sửa/xóa đều chạy thật và cập nhật ngay lên giao diện, nhưng **mất
khi tắt app** — đúng như mong đợi ở giai đoạn dựng giao diện.

## Cấu trúc

```
lib/
  core/
    theme/      tokens.dart (màu, nhịp, bán kính) · typography.dart · app_theme.dart
    widgets/    trang_vo.dart (trang vở có lề mang nghĩa) · common.dart
    utils/      ngay.dart (định dạng ngày giờ tiếng Việt)
  data/
    models/     NguoiDung · MonHoc · GiaoVien · TietHoc · BaoCao · NhacNho
    repositories/
                hoc_tap_repository.dart  ← hợp đồng dữ liệu
                mock_repository.dart     ← bản in-memory hiện dùng
    mock/       seed.dart
    app_state.dart   ChangeNotifier: phiên đăng nhập + bộ nhớ đệm
  features/
    auth/       chọn vai trò
    parent/     trang chủ · báo cáo · nhắc nhở · soạn nhắc nhở
    student/    trang chủ · lịch sử báo cáo
    shared/     thời khóa biểu · soạn/sửa tiết · soạn báo cáo · chi tiết báo cáo · hồ sơ
    admin/      tổng quan · người dùng · liên kết · môn & thầy cô
```

## Bước tiếp theo: ghép Firebase

Toàn bộ giao diện chỉ nói chuyện với interface `HocTapRepository`. Việc ghép
backend là **viết thêm một lớp cài đặt interface đó**, không phải sửa màn hình.

1. Tạo project trên [Firebase Console](https://console.firebase.google.com),
   thêm app Android với package `vn.hoctap.theodoi_hoctap`.
2. Cài công cụ và sinh cấu hình:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage firebase_messaging
   ```
3. Viết `lib/data/repositories/firebase_repository.dart` cài `HocTapRepository`:
   - `dangNhap` → Firebase Auth (email/mật khẩu hoặc số điện thoại)
   - `baoCao`, `thoiKhoaBieu`, `nhacNho` → collection Firestore
   - ảnh bài làm → Firebase Storage, lưu URL vào trường `anh`
   - nhắc nhở → Cloud Messaging để hiện thông báo đẩy trên máy học sinh
4. Trong [lib/main.dart](lib/main.dart), đổi đúng một dòng:
   ```dart
   create: (_) => AppState(FirebaseRepository()),
   ```

Gợi ý cấu trúc Firestore:

```
nguoiDung/{uid}            hoTen, vaiTro, lop, truong, conIds[]
hocSinh/{hsId}/tietHoc/{id}    thu, tiet, buoi, monId, giaoVienId, loai
hocSinh/{hsId}/baoCao/{id}     ngay, loai, monId, giaoVienId, noiDung,
                               trangThai, anh[], soPhut, nhanXetPhuHuynh
hocSinh/{hsId}/nhacNho/{id}    tuId, noiDung, hanLuc, daDoc
monHoc/{id} · giaoVien/{id}
```

Luật bảo mật cần chặn phụ huynh đọc dữ liệu học sinh không nằm trong `conIds`
của mình — đây là điểm nhạy cảm nhất của hệ thống.

## Kiểm thử

```bash
flutter analyze
flutter test
```
