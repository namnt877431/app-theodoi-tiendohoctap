/// Đường nhận thông báo đẩy của một máy.
///
/// `AppState` chỉ biết interface này: xin token, nghe token đổi, nghe tin đến
/// khi app đang mở. Bản thật là [FcmKenh] (Firebase Cloud Messaging); test
/// dùng bản giả. Nhờ vậy phần "lưu token lên Supabase, xóa khi đăng xuất"
/// kiểm được mà không cần Firebase.
abstract interface class KenhThongBao {
  /// Xin quyền hiện thông báo rồi lấy token của máy. Null khi người dùng từ
  /// chối hoặc máy không có dịch vụ Google.
  Future<String?> layToken();

  /// FCM thỉnh thoảng cấp token mới; phải ghi đè lên máy chủ.
  Stream<String> get tokenMoi;

  /// Tin đến trong lúc app đang mở — hệ điều hành không tự hiện, app tự lo.
  Stream<TinDen> get tinDen;

  /// Bỏ token trên máy khi đăng xuất, để tài khoản sau không nhận nhầm tin.
  Future<void> xoaToken();
}

class TinDen {
  const TinDen({required this.tieuDe, required this.noiDung, this.duLieu = const {}});

  final String tieuDe;
  final String noiDung;
  final Map<String, String> duLieu;

  /// `bao_cao`, `nhan_xet`, `nhac_nho`, `nhac_toi` — xem 06_thong_bao.sql.
  String? get loai => duLieu['loai'];
}
