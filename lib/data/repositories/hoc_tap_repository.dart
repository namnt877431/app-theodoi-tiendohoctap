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
    String? truongId,
    String? soDienThoai,
  });

  Future<void> guiEmailDatLaiMatKhau(String email);
  Future<void> dangXuat();

  // ------------------------------------------------------------------ danh mục

  /// Tỉnh và trường đọc được cả khi chưa đăng nhập — màn đăng ký cần chúng.
  Future<List<Tinh>> taiTinh();
  Future<List<Truong>> taiTruong();
  Future<List<MonHoc>> taiMonHoc();

  /// Trả về mọi thầy cô người này được thấy: danh mục chung, cộng thầy dạy
  /// thêm riêng của mình (hoặc của con mình). Quản trị thấy tất cả.
  Future<List<GiaoVien>> taiGiaoVien();

  // Quản trị sửa danh mục. Thầy dạy thêm riêng (`chuId` có giá trị) thì học
  // sinh và phụ huynh cũng thêm/sửa/xóa được — phân quyền nằm ở tầng dữ liệu.
  Future<void> luuTinh(Tinh t);
  Future<void> xoaTinh(String id);
  Future<void> luuTruong(Truong t);
  Future<void> xoaTruong(String id);
  Future<void> luuMonHoc(MonHoc m);
  Future<void> xoaMonHoc(String id);
  Future<void> luuGiaoVien(GiaoVien gv);
  Future<void> xoaGiaoVien(String id);

  // ---------------------------------------------------------------- bài học

  /// Danh mục bài học của một khối lớp, mọi môn, theo thứ tự trong sách.
  /// Ai đăng nhập cũng đọc được; rỗng khi khối đó chưa nạp dữ liệu.
  Future<List<BaiHoc>> taiBaiHoc(int lop);

  /// Quản trị sửa tóm tắt, câu hỏi (hoặc thêm bài lẻ). Ghi đè theo id.
  Future<void> luuBaiHoc(BaiHoc bh);
  Future<void> xoaBaiHoc(String id);

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

  // ------------------------------------------------------------------ sổ điểm

  Future<List<DiemThi>> diemThi(String hocSinhId);

  /// Ghi đè theo id — con hay bố mẹ ghi đều qua đây.
  Future<void> luuDiemThi(DiemThi d);
  Future<void> xoaDiemThi(String hocSinhId, String id);

  // -------------------------------------------------------------- phần thưởng

  Future<List<PhanThuong>> phanThuong(String hocSinhId);

  /// Ghi đè theo id — tạo mới, sửa, đánh dấu đã trao, treo lại đều qua đây.
  Future<void> luuPhanThuong(PhanThuong pt);
  Future<void> xoaPhanThuong(String hocSinhId, String id);

  // ----------------------------------------------------------------- thiết bị

  /// Ghi token thông báo đẩy của máy này cho người đang đăng nhập. Gọi mỗi
  /// lần mở app và mỗi lần FCM cấp token mới — ghi đè, không nhân bản.
  Future<void> luuThietBi(String token);

  /// Bỏ máy này khỏi danh sách nhận — gọi TRƯỚC khi đăng xuất, vì sau đó
  /// không còn phiên để luật phân quyền cho xóa.
  Future<void> xoaThietBi(String token);

  // ---------------------------------------------------------------------- ảnh

  /// Đưa ảnh bài làm lên kho và trả về đường dẫn để lưu vào báo cáo.
  Future<String> taiAnhLen(String hocSinhId, String duongDanCucBo);

  Future<void> xoaAnh(String duongDan);

  /// Đổi đường dẫn đã lưu thành một địa chỉ xem được.
  ///
  /// Kho ảnh để riêng tư nên không có link vĩnh viễn — mỗi lần xem phải xin
  /// một URL ký có hạn. Trả về null khi không lấy được, giao diện hiện ô báo
  /// mất ảnh thay vì một khoảng trống.
  Future<String?> urlAnh(String duongDan);
}
