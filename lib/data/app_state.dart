import 'dart:async';

import 'package:flutter/foundation.dart';

import 'models/models.dart';
import 'repositories/hoc_tap_repository.dart';
import 'repositories/mock_repository.dart';

/// Trạng thái dùng chung cho toàn app: ai đang đăng nhập, đang xem con nào,
/// và bộ nhớ đệm của danh mục, thời khóa biểu, báo cáo, nhắc nhở.
///
/// Màn hình không bao giờ gọi thẳng repository — mọi thứ đi qua đây, nên đổi
/// từ dữ liệu mẫu sang Firebase là chuyện của một dòng trong `main.dart`.
class AppState extends ChangeNotifier {
  AppState(this._repo) : _repoThat = _repo {
    _ngePhien();
  }

  HocTapRepository _repo;

  /// Repository thật, giữ lại để quay về sau khi thoát chế độ dùng thử.
  final HocTapRepository _repoThat;

  HocTapRepository get repo => _repo;
  StreamSubscription<NguoiDung?>? _theoDoiPhien;

  bool _dungThu = false;

  /// Đang chạy trên dữ liệu mẫu trong bộ nhớ, không phải dữ liệu thật.
  bool get dungThu => _dungThu;

  /// Chưa biết người dùng đã đăng nhập hay chưa — app còn ở màn chờ.
  bool _dangKhoiTao = true;
  bool get dangKhoiTao => _dangKhoiTao;

  bool _dangTai = false;
  bool get dangTai => _dangTai;

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

  List<MonHoc> _monHoc = const [];
  List<GiaoVien> _giaoVien = const [];
  List<TietHoc> _tkb = const [];
  List<BaoCao> _baoCao = const [];
  List<NhacNho> _nhacNho = const [];

  List<MonHoc> get monHoc => _monHoc;
  List<GiaoVien> get giaoVien => _giaoVien;
  List<TietHoc> get tkb => _tkb;
  List<BaoCao> get baoCao => _baoCao;
  List<NhacNho> get nhacNho => _nhacNho;
  int get soNhacNhoChuaDoc => _nhacNho.where((n) => !n.daDoc).length;

  int _dem = 0;
  String _id(String tienTo) =>
      '${tienTo}_${DateTime.now().millisecondsSinceEpoch}_${_dem++}';

  MonHoc? mon(String? id) => _monHoc.where((m) => m.id == id).firstOrNull;
  GiaoVien? gv(String? id) => _giaoVien.where((g) => g.id == id).firstOrNull;

  String tenMon(String? id) => mon(id)?.ten ?? 'Môn khác';
  String vietTatMon(String? id) => mon(id)?.vietTat ?? '—';
  String? tenGv(String? id) => gv(id)?.hoTen;

  /// Môn đầu tiên để điền sẵn vào biểu mẫu. Trả về chuỗi rỗng khi danh mục
  /// còn trống — project Firebase mới dựng chưa có môn nào.
  String get monMacDinh => _monHoc.isEmpty ? '' : _monHoc.first.id;

  List<GiaoVien> gvTheoLoai(LoaiBaiTap loai) =>
      _giaoVien.where((g) => g.loai == loai).toList();

  @override
  void dispose() {
    _theoDoiPhien?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- phiên

  void _ngePhien() {
    _theoDoiPhien?.cancel();
    _theoDoiPhien = _repo.phien().listen((nd) async {
      _nguoiDung = nd;
      if (nd == null) {
        _xoaBoNho();
      } else {
        await _napSauDangNhap(nd);
      }
      _dangKhoiTao = false;
      notifyListeners();
    });
  }

  Future<void> _napSauDangNhap(NguoiDung nd) async {
    _dangTai = true;
    notifyListeners();

    _monHoc = await _repo.taiMonHoc();
    _giaoVien = await _repo.taiGiaoVien();

    if (nd.vaiTro == VaiTro.phuHuynh) {
      _dsCon = await _repo.danhSachCon(nd.id);
      _conDangXem = _dsCon.where((c) => c.id == _conDangXem?.id).firstOrNull ??
          _dsCon.firstOrNull;
    }
    await _napDuLieuHocSinh();
    _dangTai = false;
  }

  void _xoaBoNho() {
    _conDangXem = null;
    _dsCon = const [];
    _tkb = const [];
    _baoCao = const [];
    _nhacNho = const [];
  }

  Future<void> dangNhap(String email, String matKhau) =>
      _repo.dangNhap(email, matKhau);

  Future<void> dangKy({
    required String hoTen,
    required String email,
    required String matKhau,
    required VaiTro vaiTro,
    String? lop,
    String? truong,
    String? soDienThoai,
  }) =>
      _repo.dangKy(
        hoTen: hoTen,
        email: email,
        matKhau: matKhau,
        vaiTro: vaiTro,
        lop: lop,
        truong: truong,
        soDienThoai: soDienThoai,
      );

  Future<void> guiEmailDatLaiMatKhau(String email) =>
      _repo.guiEmailDatLaiMatKhau(email);

  Future<void> dangXuat() async {
    await _repo.dangXuat();
    if (_dungThu) {
      _dungThu = false;
      _repo = _repoThat;
      _ngePhien();
    }
  }

  /// Vào thẳng bằng dữ liệu mẫu để xem giao diện, không đụng tới Firebase.
  Future<void> dungThuVoiVaiTro(VaiTro vaiTro) async {
    // Đăng nhập xong mới lắng nghe: nếu làm ngược lại, sự kiện đăng nhập có
    // thể phát ra trước khi luồng kịp có người nghe và rơi mất.
    final mock = MockRepository();
    await mock.dangNhapThu(vaiTro);
    _repo = mock;
    _dungThu = true;
    _ngePhien();
  }
  // ------------------------------------------------------------------ dữ liệu

  Future<void> chonCon(NguoiDung con) async {
    _conDangXem = con;
    notifyListeners();
    await taiLai();
  }

  /// Nạp lại toàn bộ dữ liệu của học sinh đang xem.
  Future<void> taiLai() async {
    await _napDuLieuHocSinh();
    notifyListeners();
  }

  Future<void> _napDuLieuHocSinh() async {
    final hs = hocSinhHienTai;
    if (hs == null) {
      _tkb = const [];
      _baoCao = const [];
      _nhacNho = const [];
      return;
    }
    _tkb = await _repo.thoiKhoaBieu(hs.id);
    _baoCao = await _repo.baoCao(hs.id);
    // Cả hai vai trò đọc cùng một dòng nhắc nhở gửi tới học sinh: học sinh
    // thấy lời mình nhận, phụ huynh thấy lời mình đã gửi.
    _nhacNho = await _repo.nhacNho(hs.id);
  }

  /// Nạp lại danh sách con sau khi vừa nối thêm một học sinh mới.
  Future<void> taiLaiDsCon() async {
    final ph = _nguoiDung;
    if (ph == null || ph.vaiTro != VaiTro.phuHuynh) return;
    final hoSoMoi = await _repo.hoSo(ph.id);
    if (hoSoMoi != null) _nguoiDung = hoSoMoi;
    _dsCon = await _repo.danhSachCon(ph.id);
    _conDangXem ??= _dsCon.firstOrNull;
    await taiLai();
  }

  // -------------------------------------------------------------------- mã mời

  Future<MaMoi> taoMaMoi() async {
    final hs = hocSinhHienTai;
    if (hs == null) {
      throw const LoiHocTap('Chưa xác định được học sinh để tạo mã.');
    }
    return _repo.taoMaMoi(hs.id);
  }

  Future<NguoiDung> dungMaMoi(String ma) async {
    final ph = _nguoiDung;
    if (ph == null || ph.vaiTro != VaiTro.phuHuynh) {
      throw const LoiHocTap('Chỉ tài khoản phụ huynh mới nhập được mã mời.');
    }
    final hs = await _repo.dungMaMoi(ma, ph.id);
    _conDangXem = hs;
    await taiLaiDsCon();
    return hs;
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

  TietHoc? tkbTai(int thu, int tiet, Buoi buoi) =>
      _tkb.where((t) => t.thu == thu && t.tiet == tiet && t.buoi == buoi).firstOrNull;

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
    final hs = hocSinhHienTai;
    if (hs == null) return;
    await _repo.xoaTietHoc(hs.id, id);
    await taiLai();
  }

  // -------------------------------------------------------------- báo cáo

  List<BaoCao> baoCaoNgay(DateTime ngay) => _baoCao
      .where((b) =>
          b.ngay.year == ngay.year &&
          b.ngay.month == ngay.month &&
          b.ngay.day == ngay.day)
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
      final ngay =
          DateTime(homNay.year, homNay.month, homNay.day).subtract(Duration(days: i));
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
        monId: monMacDinh,
        noiDung: '',
        trangThai: TrangThai.chuaLam,
        taoLuc: DateTime.now(),
      );

  /// Lưu báo cáo, đưa ảnh mới chụp lên kho trước.
  ///
  /// Ảnh đã có đường dẫn mạng thì giữ nguyên — sửa lại một báo cáo cũ không
  /// nên tải lên lần nữa những tấm đã nằm sẵn trên kho.
  Future<void> luuBaoCao(BaoCao bc) async {
    final anh = <String>[];
    for (final a in bc.anh) {
      if (a.startsWith('http') || a.startsWith('demo:')) {
        anh.add(a);
      } else {
        anh.add(await _repo.taiAnhLen(bc.hocSinhId, a));
      }
    }
    await _repo.luuBaoCao(bc.copyWith(anh: anh));
    await taiLai();
  }

  Future<void> xoaBaoCao(String id) async {
    final bc = _baoCao.where((b) => b.id == id).firstOrNull;
    await _repo.xoaBaoCao(bc?.hocSinhId ?? hocSinhHienTai?.id ?? '', id);
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
    final hs = hocSinhHienTai;
    if (hs == null) return;
    await _repo.danhDauDaDoc(hs.id, id);
    await taiLai();
  }
}
