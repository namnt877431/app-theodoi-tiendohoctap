import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'kenh_thong_bao.dart';

/// Kênh thật, chạy trên Firebase Cloud Messaging.
///
/// Firebase chỉ làm đúng một việc: đưa tin từ Edge Function xuống máy. Không
/// có dữ liệu nào của app đi qua Firebase ngoài tiêu đề và nội dung của chính
/// cái thông báo đó.
///
/// Tin gửi dạng `notification` nên khi app ở nền hay đã tắt, Android tự hiện
/// — không cần handler chạy nền. Khi app đang mở thì [tinDen] phát ra để giao
/// diện tự nạp lại và báo một dòng.
class FcmKenh implements KenhThongBao {
  FcmKenh._();

  /// Khởi động Firebase. Trả về null khi máy không có cấu hình
  /// (`google-services.json` chưa đặt vào project) — app vẫn chạy bình
  /// thường, chỉ không có thông báo đẩy.
  static Future<FcmKenh?> khoiDong() async {
    try {
      await Firebase.initializeApp();
      return FcmKenh._();
    } catch (e) {
      debugPrint('Không khởi động được Firebase ($e) — tắt thông báo đẩy. '
          'Xem phần "Thông báo đẩy" trong README.');
      return null;
    }
  }

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  @override
  Future<String?> layToken() async {
    try {
      final quyen = await _fcm.requestPermission();
      if (quyen.authorizationStatus == AuthorizationStatus.denied) return null;
      return await _fcm.getToken();
    } catch (e) {
      // Máy không có Google Play services (Huawei đời mới, máy ảo trần).
      debugPrint('Không lấy được token FCM ($e).');
      return null;
    }
  }

  @override
  Stream<String> get tokenMoi => _fcm.onTokenRefresh;

  @override
  Stream<TinDen> get tinDen => FirebaseMessaging.onMessage.map(
        (m) => TinDen(
          tieuDe: m.notification?.title ?? '',
          noiDung: m.notification?.body ?? '',
          duLieu: m.data.map((k, v) => MapEntry(k, '$v')),
        ),
      );

  @override
  Future<void> xoaToken() async {
    try {
      await _fcm.deleteToken();
    } catch (_) {
      // Không có mạng thì thôi; hàng thiet_bi trên máy chủ đã bị xóa trước đó.
    }
  }
}
