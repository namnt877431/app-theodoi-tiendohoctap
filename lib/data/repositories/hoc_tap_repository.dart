import '../models/models.dart';

/// Hợp đồng dữ liệu của toàn app. Bản mock trong `mock_repository.dart` chạy
/// hoàn toàn trong bộ nhớ; khi ghép Firebase chỉ cần viết một lớp khác
/// cài đặt đúng interface này, phần giao diện không phải sửa gì.
abstract interface class HocTapRepository {
  Future<NguoiDung?> dangNhap(VaiTro vaiTro);
  Future<List<NguoiDung>> danhSachNguoiDung();
  Future<List<NguoiDung>> danhSachCon(String phuHuynhId);

  List<MonHoc> get monHoc;
  List<GiaoVien> get giaoVien;

  Future<List<TietHoc>> thoiKhoaBieu(String hocSinhId);
  Future<void> luuTietHoc(TietHoc tiet);
  Future<void> xoaTietHoc(String tietId);

  Future<List<BaoCao>> baoCao(String hocSinhId, {DateTime? ngay});
  Future<void> luuBaoCao(BaoCao bc);
  Future<void> xoaBaoCao(String id);

  Future<List<NhacNho>> nhacNho(String nguoiNhanId);
  Future<void> guiNhacNho(NhacNho nn);
  Future<void> danhDauDaDoc(String nhacNhoId);

  Future<void> luuNguoiDung(NguoiDung nd);
  Future<void> lienKet(String phuHuynhId, String hocSinhId);
  Future<void> huyLienKet(String phuHuynhId, String hocSinhId);
}
