import '../models/models.dart';

/// Lỗi đã được dịch sang câu người dùng đọc được. Tầng giao diện chỉ cần hiện
/// `loi.thongDiep`, không phải đoán mã lỗi của Firebase.
class LoiHocTap implements Exception {
  const LoiHocTap(this.thongDiep, {this.ma});
  final String thongDiep;
  final String? ma;

  @override
  String toString() => thongDiep;
}

/// Hợp đồng dữ liệu của toàn app.
///
/// Có hai bản cài đặt: `MockRepository` chạy trong bộ nhớ để xem giao diện và
/// để test, `FirebaseRepository` nói chuyện với Firebase thật. Tầng giao diện
/// chỉ biết interface này nên đổi bản cài đặt không phải sửa màn hình nào.
abstract interface class HocTapRepository {
  // ------------------------------------------------------------ phiên đăng nhập

  /// Phát ra hồ sơ người đang đăng nhập, hoặc null khi đã đăng xuất.
  /// App lắng nghe luồng này để tự đưa người dùng về màn đăng nhập khi phiên
  /// hết hạn hoặc tài khoản bị khóa.
  Stream<NguoiDung?> phien();

  Future<NguoiDung> dangNhap(String email, String matKhau);

  Future<NguoiDung> dangKy({
    required String hoTen,
    required String email,
    required String matKhau,
    required VaiTro vaiTro,
    String? lop,
    String? truong,
    String? soDienThoai,
  });

  Future<void> guiEmailDatLaiMatKhau(String email);
  Future<void> dangXuat();

  // ------------------------------------------------------------------ danh mục

  Future<List<MonHoc>> taiMonHoc();
  Future<List<GiaoVien>> taiGiaoVien();

  // ---------------------------------------------------------------- người dùng

  Future<NguoiDung?> hoSo(String id);
  Future<List<NguoiDung>> danhSachNguoiDung();
  Future<List<NguoiDung>> danhSachCon(String phuHuynhId);
  Future<void> luuNguoiDung(NguoiDung nd);
  Future<void> lienKet(String phuHuynhId, String hocSinhId);
  Future<void> huyLienKet(String phuHuynhId, String hocSinhId);

  // -------------------------------------------------------------------- mã mời

  /// Học sinh sinh mã sáu số cho bố mẹ nhập. Mã cũ của cùng học sinh bị vô hiệu.
  Future<MaMoi> taoMaMoi(String hocSinhId);

  /// Phụ huynh nhập mã để nối vào tài khoản con. Trả về hồ sơ học sinh vừa nối.
  /// Ném [LoiHocTap] nếu mã sai, hết hạn hoặc đã dùng.
  Future<NguoiDung> dungMaMoi(String ma, String phuHuynhId);

  // ---------------------------------------------------------- thời khóa biểu

  Future<List<TietHoc>> thoiKhoaBieu(String hocSinhId);
  Future<void> luuTietHoc(TietHoc tiet);
  Future<void> xoaTietHoc(String hocSinhId, String tietId);

  // ------------------------------------------------------------------ báo cáo

  Future<List<BaoCao>> baoCao(String hocSinhId, {DateTime? ngay});
  Future<void> luuBaoCao(BaoCao bc);
  Future<void> xoaBaoCao(String hocSinhId, String id);

  // ----------------------------------------------------------------- nhắc nhở

  Future<List<NhacNho>> nhacNho(String hocSinhId);
  Future<void> guiNhacNho(NhacNho nn);
  Future<void> danhDauDaDoc(String hocSinhId, String nhacNhoId);

  // ---------------------------------------------------------------------- ảnh

  /// Đưa ảnh bài làm lên kho và trả về đường dẫn để lưu vào báo cáo.
  Future<String> taiAnhLen(String hocSinhId, String duongDanCucBo);

  Future<void> xoaAnh(String duongDan);
}
