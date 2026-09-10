import 'dart:async';
import 'dart:math';

import '../mock/seed.dart';
import '../models/models.dart';
import 'hoc_tap_repository.dart';

/// Kho dữ liệu tạm trong bộ nhớ, nạp sẵn dữ liệu mẫu của lớp 9A2.
///
/// Dùng cho hai việc: chế độ "dùng thử" để xem giao diện khi chưa dựng
/// Firebase, và cho test — nhờ vậy test chạy được mà không cần mạng.
/// Mọi thay đổi mất khi tắt app.
class MockRepository implements HocTapRepository {
  MockRepository()
      : _nguoiDung = [...Seed.nguoiDung],
        _tietHoc = [...Seed.tietHoc],
        _baoCao = [...Seed.baoCao],
        _nhacNho = [...Seed.nhacNho];

  final List<NguoiDung> _nguoiDung;
  final List<TietHoc> _tietHoc;
  final List<BaoCao> _baoCao;
  final List<NhacNho> _nhacNho;
  final List<MaMoi> _maMoi = [];

  final _phien = StreamController<NguoiDung?>.broadcast();
  NguoiDung? _dangNhap;

  int _dem = 1000;
  String _idMoi(String tienTo) => '${tienTo}_${_dem++}';

  /// Giả lập độ trễ mạng để giao diện không "nhảy" khi đổi sang Firebase thật.
  Future<T> _tre<T>(T giaTri) =>
      Future.delayed(const Duration(milliseconds: 180), () => giaTri);

  void dispose() => _phien.close();

  // ------------------------------------------------------------ phiên đăng nhập

  @override
  Stream<NguoiDung?> phien() async* {
    yield _dangNhap;
    yield* _phien.stream;
  }

  /// Lối vào nhanh cho chế độ dùng thử: chọn vai trò là vào thẳng, khỏi gõ
  /// email và mật khẩu của tài khoản mẫu.
  Future<NguoiDung?> dangNhapThu(VaiTro vaiTro) async {
    final nd = _nguoiDung.where((n) => n.vaiTro == vaiTro && n.hoatDong).firstOrNull;
    _dangNhap = nd;
    _phien.add(nd);
    return _tre(nd);
  }

  @override
  Future<NguoiDung> dangNhap(String email, String matKhau) async {
    await _tre(null);
    final nd = _nguoiDung
        .where((n) => (n.email ?? '').toLowerCase() == email.trim().toLowerCase())
        .firstOrNull;
    if (nd == null) {
      throw const LoiHocTap('Email hoặc mật khẩu không đúng.');
    }
    if (!nd.hoatDong) {
      throw const LoiHocTap('Tài khoản đang bị khóa. Liên hệ quản trị để mở lại.');
    }
    if (matKhau.length < 6) {
      throw const LoiHocTap('Mật khẩu quá ngắn. Đặt ít nhất 6 ký tự.');
    }
    _dangNhap = nd;
    _phien.add(nd);
    return nd;
  }

  @override
  Future<NguoiDung> dangKy({
    required String hoTen,
    required String email,
    required String matKhau,
    required VaiTro vaiTro,
    String? lop,
    String? truong,
    String? soDienThoai,
  }) async {
    await _tre(null);
    final trung = _nguoiDung
        .any((n) => (n.email ?? '').toLowerCase() == email.trim().toLowerCase());
    if (trung) {
      throw const LoiHocTap('Email này đã có tài khoản. Đăng nhập hoặc dùng email khác.');
    }
    if (matKhau.length < 6) {
      throw const LoiHocTap('Mật khẩu quá ngắn. Đặt ít nhất 6 ký tự.');
    }

    final nd = NguoiDung(
      id: _idMoi(vaiTro == VaiTro.hocSinh ? 'hs' : 'ph'),
      hoTen: hoTen.trim(),
      vaiTro: vaiTro,
      email: email.trim(),
      soDienThoai: soDienThoai,
      lop: lop,
      truong: truong,
    );
    _nguoiDung.add(nd);
    _dangNhap = nd;
    _phien.add(nd);
    return nd;
  }

  @override
  Future<void> guiEmailDatLaiMatKhau(String email) => _tre(null);

  @override
  Future<void> dangXuat() async {
    _dangNhap = null;
    _phien.add(null);
  }
  // ------------------------------------------------------------------ danh mục

  @override
  Future<List<MonHoc>> taiMonHoc() => _tre(Seed.monHoc);

  @override
  Future<List<GiaoVien>> taiGiaoVien() => _tre(Seed.giaoVien);

  // ---------------------------------------------------------------- người dùng

  @override
  Future<NguoiDung?> hoSo(String id) =>
      _tre(_nguoiDung.where((n) => n.id == id).firstOrNull);

  @override
  Future<List<NguoiDung>> danhSachNguoiDung() => _tre([..._nguoiDung]);

  @override
  Future<List<NguoiDung>> danhSachCon(String phuHuynhId) {
    final ph = _nguoiDung.where((n) => n.id == phuHuynhId).firstOrNull;
    if (ph == null) return _tre(const <NguoiDung>[]);
    final ds = ph.conIds
        .map((id) => _nguoiDung.where((n) => n.id == id).firstOrNull)
        .whereType<NguoiDung>()
        .toList();
    return _tre(ds);
  }

  @override
  Future<void> luuNguoiDung(NguoiDung nd) async {
    final i = _nguoiDung.indexWhere((n) => n.id == nd.id);
    if (i >= 0) {
      _nguoiDung[i] = nd;
    } else {
      _nguoiDung.add(nd);
    }
    if (_dangNhap?.id == nd.id) {
      _dangNhap = nd;
      _phien.add(nd);
    }
  }

  @override
  Future<void> lienKet(String phuHuynhId, String hocSinhId) async {
    final i = _nguoiDung.indexWhere((n) => n.id == phuHuynhId);
    if (i < 0) return;
    final ph = _nguoiDung[i];
    if (ph.conIds.contains(hocSinhId)) return;
    _nguoiDung[i] = ph.copyWith(conIds: [...ph.conIds, hocSinhId]);
  }

  @override
  Future<void> huyLienKet(String phuHuynhId, String hocSinhId) async {
    final i = _nguoiDung.indexWhere((n) => n.id == phuHuynhId);
    if (i < 0) return;
    final ph = _nguoiDung[i];
    _nguoiDung[i] =
        ph.copyWith(conIds: ph.conIds.where((c) => c != hocSinhId).toList());
  }

  // -------------------------------------------------------------------- mã mời

  @override
  Future<MaMoi> taoMaMoi(String hocSinhId) async {
    _maMoi.removeWhere((m) => m.hocSinhId == hocSinhId);
    final ma = MaMoi(
      ma: Random().nextInt(1000000).toString().padLeft(6, '0'),
      hocSinhId: hocSinhId,
      hetHan: DateTime.now().add(const Duration(minutes: 15)),
    );
    _maMoi.add(ma);
    return _tre(ma);
  }

  @override
  Future<NguoiDung> dungMaMoi(String ma, String phuHuynhId) async {
    await _tre(null);
    final maSach = ma.trim().replaceAll(RegExp(r'\D'), '');
    if (maSach.length != 6) {
      throw const LoiHocTap('Mã mời gồm đúng 6 chữ số.');
    }
    final i = _maMoi.indexWhere((m) => m.ma == maSach);
    if (i < 0) {
      throw const LoiHocTap('Mã mời không đúng. Nhờ con đọc lại mã.');
    }
    final m = _maMoi[i];
    if (m.daDung) {
      throw const LoiHocTap('Mã mời này đã được dùng rồi. Nhờ con tạo mã mới.');
    }
    if (!m.hetHan.isAfter(DateTime.now())) {
      throw const LoiHocTap('Mã mời đã hết hạn. Nhờ con tạo mã mới.');
    }

    _maMoi[i] = MaMoi(
      ma: m.ma,
      hocSinhId: m.hocSinhId,
      hetHan: m.hetHan,
      daDung: true,
    );
    await lienKet(phuHuynhId, m.hocSinhId);

    final hs = _nguoiDung.where((n) => n.id == m.hocSinhId).firstOrNull;
    if (hs == null) {
      throw const LoiHocTap('Không tìm thấy hồ sơ học sinh của mã này.');
    }
    return hs;
  }

  // ---------------------------------------------------------- thời khóa biểu

  @override
  Future<List<TietHoc>> thoiKhoaBieu(String hocSinhId) =>
      _tre(_tietHoc.where((t) => t.hocSinhId == hocSinhId).toList());

  @override
  Future<void> luuTietHoc(TietHoc tiet) async {
    final i = _tietHoc.indexWhere((t) => t.id == tiet.id);
    if (i >= 0) {
      _tietHoc[i] = tiet;
    } else {
      _tietHoc.add(tiet);
    }
  }

  @override
  Future<void> xoaTietHoc(String hocSinhId, String tietId) async =>
      _tietHoc.removeWhere((t) => t.hocSinhId == hocSinhId && t.id == tietId);

  // ------------------------------------------------------------------ báo cáo

  @override
  Future<List<BaoCao>> baoCao(String hocSinhId, {DateTime? ngay}) {
    var ds = _baoCao.where((b) => b.hocSinhId == hocSinhId);
    if (ngay != null) {
      ds = ds.where((b) =>
          b.ngay.year == ngay.year &&
          b.ngay.month == ngay.month &&
          b.ngay.day == ngay.day);
    }
    final ket = ds.toList()..sort((a, b) => b.taoLuc.compareTo(a.taoLuc));
    return _tre(ket);
  }

  @override
  Future<void> luuBaoCao(BaoCao bc) async {
    final i = _baoCao.indexWhere((b) => b.id == bc.id);
    if (i >= 0) {
      _baoCao[i] = bc;
    } else {
      _baoCao.add(bc);
    }
  }

  @override
  Future<void> xoaBaoCao(String hocSinhId, String id) async =>
      _baoCao.removeWhere((b) => b.hocSinhId == hocSinhId && b.id == id);

  // ----------------------------------------------------------------- nhắc nhở

  @override
  Future<List<NhacNho>> nhacNho(String hocSinhId) {
    final ds = _nhacNho.where((n) => n.denId == hocSinhId).toList()
      ..sort((a, b) => b.taoLuc.compareTo(a.taoLuc));
    return _tre(ds);
  }

  @override
  Future<void> guiNhacNho(NhacNho nn) async => _nhacNho.add(nn);

  @override
  Future<void> danhDauDaDoc(String hocSinhId, String nhacNhoId) async {
    final i = _nhacNho.indexWhere((n) => n.denId == hocSinhId && n.id == nhacNhoId);
    if (i >= 0) _nhacNho[i] = _nhacNho[i].copyWith(daDoc: true);
  }

  // ---------------------------------------------------------------------- ảnh

  /// Bản mock giữ nguyên đường dẫn ảnh trên máy — không có kho nào để tải lên.
  @override
  Future<String> taiAnhLen(String hocSinhId, String duongDanCucBo) =>
      _tre(duongDanCucBo);

  @override
  Future<void> xoaAnh(String duongDan) async {}
}
