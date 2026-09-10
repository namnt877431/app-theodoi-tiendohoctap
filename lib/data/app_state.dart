import 'package:flutter/foundation.dart';

import 'models/models.dart';
import 'repositories/hoc_tap_repository.dart';

/// Trạng thái dùng chung cho toàn app: ai đang đăng nhập, đang xem con nào,
/// và bộ nhớ đệm của thời khóa biểu / báo cáo / nhắc nhở.
class AppState extends ChangeNotifier {
  AppState(this._repo);

  final HocTapRepository _repo;
  HocTapRepository get repo => _repo;

  NguoiDung? _nguoiDung;
  NguoiDung? get nguoiDung => _nguoiDung;
  bool get daDangNhap => _nguoiDung != null;

  List<NguoiDung> _dsCon = const [];
  List<NguoiDung> get dsCon => _dsCon;

  NguoiDung? _conDangXem;

  /// Học sinh mà màn hình đang nói tới: với phụ huynh là đứa con đang chọn,
  /// với học sinh là chính mình.
  NguoiDung? get hocSinhHienTai =>
      _nguoiDung?.vaiTro == VaiTro.hocSinh ? _nguoiDung : _conDangXem;

  List<TietHoc> _tkb = const [];
  List<TietHoc> get tkb => _tkb;

  List<BaoCao> _baoCao = const [];
  List<BaoCao> get baoCao => _baoCao;

  List<NhacNho> _nhacNho = const [];
  List<NhacNho> get nhacNho => _nhacNho;
  int get soNhacNhoChuaDoc => _nhacNho.where((n) => !n.daDoc).length;

  bool _dangTai = false;
  bool get dangTai => _dangTai;

  int _dem = 0;
  String _id(String tienTo) =>
      '${tienTo}_${DateTime.now().millisecondsSinceEpoch}_${_dem++}';

  List<MonHoc> get monHoc => _repo.monHoc;
  List<GiaoVien> get giaoVien => _repo.giaoVien;

  MonHoc? mon(String? id) => _repo.monHoc.where((m) => m.id == id).firstOrNull;
  GiaoVien? gv(String? id) => _repo.giaoVien.where((g) => g.id == id).firstOrNull;

  String tenMon(String? id) => mon(id)?.ten ?? 'Môn khác';
  String vietTatMon(String? id) => mon(id)?.vietTat ?? '—';
  String? tenGv(String? id) => gv(id)?.hoTen;

  List<GiaoVien> gvTheoLoai(LoaiBaiTap loai) =>
      _repo.giaoVien.where((g) => g.loai == loai).toList();

  // ---------------------------------------------------------------- phiên

  Future<void> dangNhap(VaiTro vaiTro) async {
    _dangTai = true;
    notifyListeners();

    _nguoiDung = await _repo.dangNhap(vaiTro);
    if (_nguoiDung != null && _nguoiDung!.vaiTro == VaiTro.phuHuynh) {
      _dsCon = await _repo.danhSachCon(_nguoiDung!.id);
      _conDangXem = _dsCon.firstOrNull;
    }
    await taiLai();

    _dangTai = false;
    notifyListeners();
  }

  void dangXuat() {
    _nguoiDung = null;
    _conDangXem = null;
    _dsCon = const [];
    _tkb = const [];
    _baoCao = const [];
    _nhacNho = const [];
    notifyListeners();
  }

  Future<void> chonCon(NguoiDung con) async {
    _conDangXem = con;
    notifyListeners();
    await taiLai();
  }

  /// Nạp lại toàn bộ dữ liệu của học sinh đang xem.
  Future<void> taiLai() async {
    final hs = hocSinhHienTai;
    if (hs == null) return;
    _tkb = await _repo.thoiKhoaBieu(hs.id);
    _baoCao = await _repo.baoCao(hs.id);
    // Cả hai vai trò đều xem cùng một dòng nhắc nhở gửi tới học sinh:
    // học sinh thấy lời nhắc mình nhận, phụ huynh thấy lời mình đã gửi.
    _nhacNho = await _repo.nhacNho(hs.id);
    notifyListeners();
  }

  // ------------------------------------------------------- thời khóa biểu

  List<TietHoc> tkbTheoThu(int thu) {
    final ds = _tkb.where((t) => t.thu == thu).toList()
      ..sort((a, b) {
        final c = a.buoi.index.compareTo(b.buoi.index);
        return c != 0 ? c : a.tiet.compareTo(b.tiet);
      });
    return ds;
  }

  TietHoc? tkbTai(int thu, int tiet, Buoi buoi) => _tkb
      .where((t) => t.thu == thu && t.tiet == tiet && t.buoi == buoi)
      .firstOrNull;

  Future<void> luuTiet(TietHoc t, {bool moi = false}) async {
    final hs = hocSinhHienTai;
    if (hs == null) return;
    await _repo.luuTietHoc(moi ? _sinhTiet(t, hs.id) : t);
    await taiLai();
  }

  TietHoc _sinhTiet(TietHoc t, String hocSinhId) => TietHoc(
        id: _id('tkb'),
        hocSinhId: hocSinhId,
        thu: t.thu,
        tiet: t.tiet,
        buoi: t.buoi,
        monId: t.monId,
        loai: t.loai,
        giaoVienId: t.giaoVienId,
        phong: t.phong,
        batDau: t.batDau,
        ketThuc: t.ketThuc,
      );

  Future<void> xoaTiet(String id) async {
    await _repo.xoaTietHoc(id);
    await taiLai();
  }

  // -------------------------------------------------------------- báo cáo

  List<BaoCao> baoCaoNgay(DateTime ngay) => _baoCao
      .where((b) =>
          b.ngay.year == ngay.year && b.ngay.month == ngay.month && b.ngay.day == ngay.day)
      .toList();

  TongKetNgay tongKet(DateTime ngay) {
    final ds = baoCaoNgay(ngay);
    return TongKetNgay(
      xong: ds.where((b) => b.trangThai == TrangThai.xong).length,
      dangLam: ds.where((b) => b.trangThai == TrangThai.dangLam).length,
      chuaLam: ds.where((b) => b.trangThai == TrangThai.chuaLam).length,
      soPhut: ds.fold(0, (t, b) => t + (b.soPhut ?? 0)),
    );
  }

  /// Chuỗi ngày liên tiếp gần nhất mà mọi bài tập đều đã xong.
  int get chuoiNgayTron {
    var chuoi = 0;
    final homNay = DateTime.now();
    for (var i = 0; i < 30; i++) {
      final ngay = DateTime(homNay.year, homNay.month, homNay.day)
          .subtract(Duration(days: i));
      final ds = baoCaoNgay(ngay);
      if (ds.isEmpty) {
        if (i == 0) continue;
        break;
      }
      if (ds.every((b) => b.trangThai == TrangThai.xong)) {
        chuoi++;
      } else {
        break;
      }
    }
    return chuoi;
  }

  BaoCao taoBaoCaoRong({required LoaiBaiTap loai}) => BaoCao(
        id: _id('bc'),
        hocSinhId: hocSinhHienTai?.id ?? '',
        ngay: DateTime.now(),
        loai: loai,
        monId: _repo.monHoc.first.id,
        noiDung: '',
        trangThai: TrangThai.chuaLam,
        taoLuc: DateTime.now(),
      );

  Future<void> luuBaoCao(BaoCao bc) async {
    await _repo.luuBaoCao(bc);
    await taiLai();
  }

  Future<void> xoaBaoCao(String id) async {
    await _repo.xoaBaoCao(id);
    await taiLai();
  }

  // ------------------------------------------------------------- nhắc nhở

  Future<void> guiNhacNho(String noiDung, {DateTime? hanLuc, String? baoCaoId}) async {
    final hs = hocSinhHienTai;
    final ph = _nguoiDung;
    if (hs == null || ph == null) return;
    await _repo.guiNhacNho(NhacNho(
      id: _id('nn'),
      tuId: ph.id,
      denId: hs.id,
      noiDung: noiDung,
      taoLuc: DateTime.now(),
      hanLuc: hanLuc,
      baoCaoId: baoCaoId,
    ));
    await taiLai();
  }

  Future<void> docNhacNho(String id) async {
    await _repo.danhDauDaDoc(id);
    await taiLai();
  }
}
