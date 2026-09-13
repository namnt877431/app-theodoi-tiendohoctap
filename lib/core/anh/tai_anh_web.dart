import 'package:web/web.dart' as web;

Future<String> taiAnhVeMay({String? duongDan, String? url}) async {
  final dich = url ?? duongDan;
  if (dich == null) return 'Không có ảnh để tải.';
  web.window.open(dich, '_blank');
  return 'Đã mở ảnh ở tab mới — bấm chuột phải hoặc giữ tay để lưu.';
}
