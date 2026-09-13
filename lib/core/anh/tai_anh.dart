import 'tai_anh_stub.dart'
    if (dart.library.io) 'tai_anh_io.dart'
    if (dart.library.js_interop) 'tai_anh_web.dart' as nen;

/// Đưa một tấm ảnh về máy người dùng.
///
/// Điện thoại: lưu vào thư viện ảnh (album "Sổ liên lạc"). Web: mở ảnh ở
/// tab mới để trình duyệt tự lo phần tải — link ký từ kho là khác nguồn nên
/// không ép tải thẳng được. Trả về câu để hiện lên thanh báo.
///
/// [duongDan] là file trên máy (ảnh vừa chụp) hoặc null; [url] là link xem
/// được (blob:, http). Cần ít nhất một trong hai.
Future<String> taiAnhVeMay({String? duongDan, String? url}) => nen.taiAnhVeMay(duongDan: duongDan, url: url);
