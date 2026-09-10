import '../mock/seed.dart';
import '../models/models.dart';
import 'hoc_tap_repository.dart';

/// Kho dữ liệu tạm trong bộ nhớ, nạp sẵn dữ liệu mẫu để xem được giao diện
/// ngay khi mở app. Mọi thay đổi mất khi tắt app — đúng như mong đợi ở giai
/// đoạn dựng giao diện.
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

  int _dem = 1000;
  String _idMoi(String tienTo) => '${tienTo}_${_dem++}';

  /// Giả lập độ trễ mạng để giao diện không "nhảy" khi sau này gắn Firebase.
  Future<T> _tre<T>(T giaTri) =>
      Future.delayed(const Duration(milliseconds: 180), () => giaTri);

  @override
  List<MonHoc> get monHoc => Seed.monHoc;

  @override
  List<GiaoVien> get giaoVien => Seed.giaoVien;

  @override
  Future<NguoiDung?> dangNhap(VaiTro vaiTro) =>
      _tre(_nguoiDung.where((n) => n.vaiTro == vaiTro && n.hoatDong).firstOrNull);

  @override
  Future<List<NguoiDung>> danhSachNguoiDung() => _tre([..._nguoiDung]);

  @override
  Future<List<NguoiDung>> danhSachCon(String phuHuynhId) {
    final ph = _nguoiDung.where((n) => n.id == phuHuynhId).firstOrNull;
    if (ph == null) return _tre(const <NguoiDung>[]);
    return _tre(_nguoiDung.where((n) => ph.conIds.contains(n.id)).toList());
  }

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
  Future<void> xoaTietHoc(String tietId) async => _tietHoc.removeWhere((t) => t.id == tietId);

  @override
  Future<List<BaoCao>> baoCao(String hocSinhId, {DateTime? ngay}) {
    var ds = _baoCao.where((b) => b.hocSinhId == hocSinhId);
    if (ngay != null) {
      ds = ds.where((b) =>
          b.ngay.year == ngay.year && b.ngay.month == ngay.month && b.ngay.day == ngay.day);
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
  Future<void> xoaBaoCao(String id) async => _baoCao.removeWhere((b) => b.id == id);

  @override
  Future<List<NhacNho>> nhacNho(String nguoiNhanId) {
    final ds = _nhacNho.where((n) => n.denId == nguoiNhanId).toList()
      ..sort((a, b) => b.taoLuc.compareTo(a.taoLuc));
    return _tre(ds);
  }

  @override
  Future<void> guiNhacNho(NhacNho nn) async => _nhacNho.add(nn);

  @override
  Future<void> danhDauDaDoc(String nhacNhoId) async {
    final i = _nhacNho.indexWhere((n) => n.id == nhacNhoId);
    if (i >= 0) _nhacNho[i] = _nhacNho[i].copyWith(daDoc: true);
  }

  @override
  Future<void> luuNguoiDung(NguoiDung nd) async {
    final i = _nguoiDung.indexWhere((n) => n.id == nd.id);
    if (i >= 0) {
      _nguoiDung[i] = nd;
    } else {
      _nguoiDung.add(nd);
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
    _nguoiDung[i] = ph.copyWith(conIds: ph.conIds.where((c) => c != hocSinhId).toList());
  }

  String idBaoCao() => _idMoi('bc');
  String idTietHoc() => _idMoi('tkb');
  String idNhacNho() => _idMoi('nn');
  String idNguoiDung(String tienTo) => _idMoi(tienTo);
}
