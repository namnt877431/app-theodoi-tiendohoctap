import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/huy_hieu/chuoi.dart';
import '../core/huy_hieu/huy_hieu.dart';
import '../core/thong_bao/kenh_thong_bao.dart';
import '../core/utils/mang.dart';
import '../core/utils/ngay.dart';
import 'diem_danh.dart';
import 'models/models.dart';
import 'nhap/kho_nhap.dart';
import 'repositories/hoc_tap_repository.dart';
import 'repositories/mock_repository.dart';

/// Trạng thái dùng chung cho toàn app: ai đang đăng nhập, đang xem con nào,
/// và bộ nhớ đệm của danh mục, thời khóa biểu, báo cáo, nhắc nhở.
///
/// Màn hình không bao giờ gọi thẳng repository — mọi thứ đi qua đây, nên đổi
/// từ dữ liệu mẫu sang Firebase là chuyện của một dòng trong `main.dart`.
/// Kết quả của một lần bấm Gửi.
enum KetQuaLuu {
  /// Đã lên máy chủ.
  daGui,

  /// Không có mạng — đã cất trên máy, tự gửi khi có mạng lại.
  choMang,
}

class AppState extends ChangeNotifier {
  AppState(this._repo, {KenhThongBao? kenhThongBao, KhoNhap? khoNhap})
      : _repoThat = _repo,
        _kenh = kenhThongBao,
        _khoNhap = khoNhap ?? KhoNhapBoNho() {
    _ngePhien();
    _ngeThongBao();
  }

  HocTapRepository _repo;

  /// Repository thật, giữ lại để quay về sau khi thoát chế độ dùng thử.
  final HocTapRepository _repoThat;

  HocTapRepository get repo => _repo;
  StreamSubscription<NguoiDung?>? _theoDoiPhien;

  /// Đường nhận thông báo đẩy; null khi máy không có Firebase.
  final KenhThongBao? _kenh;
  StreamSubscription<String>? _theoDoiToken;
  StreamSubscription<TinDen>? _theoDoiTin;

  /// Token của máy này đã ghi lên máy chủ — để xóa lúc đăng xuất.
  String? _tokenDaLuu;

  final _tinDen = StreamController<TinDen>.broadcast();

  /// Tin đến khi app đang mở, để giao diện báo một dòng. Dữ liệu đã được
  /// nạp lại trước khi phát.
  Stream<TinDen> get tinDen => _tinDen.stream;

  final _huyHieuMoi = StreamController<HuyHieu>.broadcast();

  /// Con dấu vừa đạt được ngay sau khi lưu một báo cáo — giao diện đóng dấu
  /// khen lên màn hình đúng lúc đó.
  Stream<HuyHieu> get huyHieuMoi => _huyHieuMoi.stream;

  /// Tiến độ mọi con dấu của học sinh đang xem, tính từ báo cáo đã nạp.
  List<TienDoHuyHieu> get huyHieu => tinhHuyHieu(baoCao, luat: luatChuoi);

  /// Báo cáo viết lúc mất mạng, chờ gửi. Giữ trên máy, không phụ thuộc phiên.
  final KhoNhap _khoNhap;
  List<BaoCao> _nhap = const [];
  bool _dangGuiNhap = false;

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

  List<Tinh> _tinh = const [];
  List<Truong> _truong = const [];
  List<MonHoc> _monHoc = const [];
  List<GiaoVien> _giaoVien = const [];

  /// Danh mục bài học đã nạp, theo khối lớp. Nạp lần đầu khi cần, giữ cả
  /// phiên — danh mục ít đổi.
  final Map<int, List<BaiHoc>> _baiHocTheoKhoi = {};
  List<TietHoc> _tkb = const [];
  List<BaoCao> _baoCao = const [];
  List<NhacNho> _nhacNho = const [];
  List<PhanThuong> _phanThuong = const [];

  List<Tinh> get tinh => _tinh;
  List<Truong> get truong => _truong;
  List<MonHoc> get monHoc => _monHoc;
  List<GiaoVien> get giaoVien => _giaoVien;
  List<TietHoc> get tkb => _tkb;

  /// Báo cáo của học sinh đang xem — bản chờ mạng xếp trước bản đã lên máy
  /// chủ, để bài vừa viết vẫn hiện ra ngay dù chưa đi được.
  List<BaoCao> get baoCao =>
      _nhapCuaHs.isEmpty ? _baoCao : [..._nhapCuaHs, ..._baoCao];

  List<BaoCao> get _nhapCuaHs {
    final id = hocSinhHienTai?.id;
    return id == null ? const [] : _nhap.where((b) => b.hocSinhId == id).toList();
  }

  /// Số báo cáo của học sinh đang xem còn chờ mạng.
  int get soNhap => _nhapCuaHs.length;

  bool laNhap(String id) => _nhap.any((b) => b.id == id);
  List<NhacNho> get nhacNho => _nhacNho;
  int get soNhacNhoChuaDoc => _nhacNho.where((n) => !n.daDoc).length;

  // Khóa chính của Postgres là uuid, nên id phải sinh đúng dạng đó ngay từ
  // phía client — nhờ vậy `upsert` dùng chung được cho cả tạo mới lẫn sửa.
  static const _uuid = Uuid();
  String _id() => _uuid.v4();

  MonHoc? mon(String? id) => _monHoc.where((m) => m.id == id).firstOrNull;
  GiaoVien? gv(String? id) => _giaoVien.where((g) => g.id == id).firstOrNull;
  Truong? truongTheoId(String? id) => _truong.where((t) => t.id == id).firstOrNull;
  Tinh? tinhTheoId(String? id) => _tinh.where((t) => t.id == id).firstOrNull;

  String tenMon(String? id) => mon(id)?.ten ?? 'Môn khác';
  String vietTatMon(String? id) => mon(id)?.vietTat ?? '—';
  String? tenGv(String? id) => gv(id)?.hoTen;
  String? tenTruong(String? id) => truongTheoId(id)?.ten;
  String? tenTinh(String? id) => tinhTheoId(id)?.ten;

  /// Tên trường của một học sinh: tra danh mục trước, không có thì lấy tên gõ
  /// tay từ hồi chưa có danh mục.
  String? tenTruongCua(NguoiDung nd) => tenTruong(nd.truongId) ?? nd.truong;

  List<Truong> truongTheoTinh(String? tinhId) =>
      tinhId == null ? _truong : _truong.where((t) => t.tinhId == tinhId).toList();

  /// Môn đầu tiên để điền sẵn vào biểu mẫu. Trả về chuỗi rỗng khi danh mục
  /// còn trống — project Firebase mới dựng chưa có môn nào.
  String get monMacDinh => _monHoc.isEmpty ? '' : _monHoc.first.id;

  /// Toàn bộ danh mục theo hạng mục — dành cho màn quản trị.
  List<GiaoVien> gvTheoLoai(LoaiBaiTap loai) =>
      _giaoVien.where((g) => g.loai == loai).toList();

  /// Thầy cô mà học sinh đang xem chọn được khi viết báo cáo hay xếp tiết.
  ///
  /// - Trên lớp: thầy cô của trường em (thầy chưa gắn trường thì ai cũng thấy).
  /// - Học thêm: thầy riêng của chính em, cộng thầy dùng chung cùng tỉnh với
  ///   trường em (thầy không ghi tỉnh thì ai cũng thấy).
  List<GiaoVien> gvChoHocSinh(LoaiBaiTap loai) {
    final hs = hocSinhHienTai;
    final tinhCuaHs = truongTheoId(hs?.truongId)?.tinhId;
    return _giaoVien.where((g) {
      if (g.loai != loai) return false;
      if (loai == LoaiBaiTap.trenLop) {
        return g.truongId == null || g.truongId == hs?.truongId;
      }
      if (g.chuId != null) return g.chuId == hs?.id;
      return g.tinhId == null || tinhCuaHs == null || g.tinhId == tinhCuaHs;
    }).toList();
  }

  // ---------------------------------------------------------------- bài học

  /// Khối lớp của học sinh đang xem, suy từ tên lớp ("8A4" → 8).
  int? get khoiHienTai => khoiTuLop(hocSinhHienTai?.lop);

  /// Danh mục bài học của khối đang xem; rỗng khi khối chưa có dữ liệu hoặc
  /// tên lớp không nói được khối.
  List<BaiHoc> get baiHoc => baiHocKhoi(khoiHienTai);

  List<BaiHoc> baiHocKhoi(int? khoi) =>
      khoi == null ? const [] : _baiHocTheoKhoi[khoi] ?? const [];

  /// Có danh mục để chọn cho môn này không — không có thì biểu mẫu giấu ô
  /// chọn bài đi, khỏi hiện một danh sách rỗng.
  List<BaiHoc> baiHocTheoMon(String? monId) =>
      baiHoc.where((b) => b.monId == monId).toList();

  /// Tra một bài theo id, ở mọi khối đã nạp — báo cáo cũ có thể trỏ tới bài
  /// của khối năm ngoái.
  BaiHoc? baiHocTheoId(String? id) {
    if (id == null) return null;
    for (final ds in _baiHocTheoKhoi.values) {
      final b = ds.where((b) => b.id == id).firstOrNull;
      if (b != null) return b;
    }
    return null;
  }

  /// Bài lớp đang học ở môn này: bài gắn vào báo cáo trên lớp gần nhất
  /// (theo ngày học, rồi giờ gửi). Null khi chưa ghi bài nào hay môn không
  /// có danh mục.
  ///
  /// Đây là mặc định khi con báo cáo. Một bài trong sách thường học hai ba
  /// tiết, nên "vẫn bài hôm trước" đúng nhiều hơn "bài kế tiếp"; sang bài
  /// mới là việc con biết chắc còn app thì không, để con bấm. Chỉ tính báo
  /// cáo trên lớp — thầy dạy thêm không đi theo thứ tự sách.
  BaiHoc? baiDangHoc(String? monId) {
    final ds = baiHocTheoMon(monId);
    if (ds.isEmpty) return null;
    final daGhi = baoCao
        .where((b) =>
            b.monId == monId &&
            b.loai == LoaiBaiTap.trenLop &&
            ds.any((x) => x.id == b.baiHocId))
        .toList()
      ..sort((a, b) {
        final c = b.ngay.compareTo(a.ngay);
        return c != 0 ? c : b.taoLuc.compareTo(a.taoLuc);
      });
    final cuoi = daGhi.firstOrNull;
    return cuoi == null ? null : ds.firstWhere((x) => x.id == cuoi.baiHocId);
  }

  /// Bài đứng ngay sau [bh] trong sách của cùng môn; null khi hết sách hay
  /// không có [bh].
  BaiHoc? baiSau(BaiHoc? bh) => bh == null
      ? null
      : baiHocTheoMon(bh.monId).where((x) => x.thuTu > bh.thuTu).firstOrNull;

  Future<void> _napBaiHoc(int? khoi) async {
    if (khoi == null || _baiHocTheoKhoi.containsKey(khoi)) return;
    _baiHocTheoKhoi[khoi] = await _repo.taiBaiHoc(khoi);
  }

  /// Quản trị xem danh mục một khối bất kì; nạp nếu chưa có.
  Future<void> taiBaiHocKhoi(int khoi, {bool lamMoi = false}) async {
    if (lamMoi) _baiHocTheoKhoi.remove(khoi);
    await _napBaiHoc(khoi);
    notifyListeners();
  }

  /// Quản trị sửa tóm tắt, câu hỏi. Lưu xong cập nhật thẳng bộ nhớ đệm.
  Future<void> luuBaiHoc(BaiHoc bh) async {
    if (bh.id.isEmpty) {
      // Bài quản trị thêm tay: id không trùng với id sinh từ file dữ liệu.
      bh = BaiHoc(
        id: 'l${bh.lop}_${bh.monId.replaceFirst('m_', '')}_qt_${_id().substring(0, 8)}',
        monId: bh.monId,
        lop: bh.lop,
        hocKi: bh.hocKi,
        chuong: bh.chuong,
        thuTu: bh.thuTu,
        ten: bh.ten,
        tomTat: bh.tomTat,
        kiemTra: bh.kiemTra,
      );
    }
    await _repo.luuBaiHoc(bh);
    final ds = [...?_baiHocTheoKhoi[bh.lop]];
    final i = ds.indexWhere((b) => b.id == bh.id);
    if (i >= 0) {
      ds[i] = bh;
    } else {
      ds.add(bh);
      ds.sort((a, b) => a.monId != b.monId
          ? a.monId.compareTo(b.monId)
          : a.thuTu.compareTo(b.thuTu));
    }
    _baiHocTheoKhoi[bh.lop] = ds;
    notifyListeners();
  }

  Future<void> xoaBaiHoc(BaiHoc bh) async {
    await _repo.xoaBaiHoc(bh.id);
    _baiHocTheoKhoi[bh.lop] = [...?_baiHocTheoKhoi[bh.lop]]..removeWhere((b) => b.id == bh.id);
    notifyListeners();
  }

  /// Thầy dạy thêm riêng của học sinh đang xem.
  List<GiaoVien> get gvRiengCuaHs {
    final id = hocSinhHienTai?.id;
    return _giaoVien.where((g) => g.chuId != null && g.chuId == id).toList();
  }

  @override
  void dispose() {
    _theoDoiPhien?.cancel();
    _theoDoiToken?.cancel();
    _theoDoiTin?.cancel();
    _tinDen.close();
    _huyHieuMoi.close();
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

    await _napDanhMuc();

    if (nd.vaiTro == VaiTro.phuHuynh) {
      _dsCon = await _repo.danhSachCon(nd.id);
      _conDangXem = _dsCon.where((c) => c.id == _conDangXem?.id).firstOrNull ??
          _dsCon.firstOrNull;
    }
    await _napDuLieuHocSinh();
    _nhap = await _khoNhap.doc();
    _dangTai = false;

    // Không chờ: xin quyền và lấy token có thể mất vài giây, đừng bắt màn
    // hình đứng đó. Bài chờ mạng cũng thử gửi lại luôn.
    unawaited(_dangKyThietBi());
    unawaited(guiNhap());
  }

  // ------------------------------------------------------------ thông báo

  void _ngeThongBao() {
    final kenh = _kenh;
    if (kenh == null) return;
    _theoDoiToken = kenh.tokenMoi.listen((token) {
      if (_nguoiDung == null || _dungThu) return;
      _tokenDaLuu = token;
      _repo.luuThietBi(token);
    });
    _theoDoiTin = kenh.tinDen.listen((tin) async {
      if (_nguoiDung == null) return;
      // Tin nói "có cái mới" — nạp lại rồi mới báo, để người dùng chạm vào
      // là thấy ngay chứ không phải chờ thêm một nhịp.
      await taiLaiTatCa();
      _tinDen.add(tin);
    });
  }

  Future<void> _dangKyThietBi() async {
    final kenh = _kenh;
    // Chế độ dùng thử không có tài khoản thật để gắn máy vào.
    if (kenh == null || _dungThu || _nguoiDung == null) return;
    final token = await kenh.layToken();
    if (token == null || _nguoiDung == null) return;
    _tokenDaLuu = token;
    await _repo.luuThietBi(token);
  }

  void _xoaBoNho() {
    _conDangXem = null;
    _dsCon = const [];
    _baiHocTheoKhoi.clear();
    _tkb = const [];
    _baoCao = const [];
    _nhacNho = const [];
    _phanThuong = const [];
  }

  Future<void> dangNhap(String email, String matKhau) =>
      _repo.dangNhap(email, matKhau);

  Future<void> dangKy({
    required String hoTen,
    required String email,
    required String matKhau,
    required VaiTro vaiTro,
    String? lop,
    String? truongId,
    String? soDienThoai,
  }) =>
      _repo.dangKy(
        hoTen: hoTen,
        email: email,
        matKhau: matKhau,
        vaiTro: vaiTro,
        lop: lop,
        truongId: truongId,
        soDienThoai: soDienThoai,
      );

  /// Màn đăng ký cần danh sách trường khi chưa có ai đăng nhập. Tỉnh và trường
  /// đọc được với khách, nên gọi thẳng repository rồi giữ lại trong bộ nhớ.
  Future<void> taiTinhTruong() async {
    _tinh = await _repo.taiTinh();
    _truong = await _repo.taiTruong();
    notifyListeners();
  }

  Future<void> guiEmailDatLaiMatKhau(String email) =>
      _repo.guiEmailDatLaiMatKhau(email);

  Future<void> dangXuat() async {
    // Gỡ máy khỏi danh sách nhận TRƯỚC khi đăng xuất — sau đó không còn
    // phiên để luật phân quyền cho xóa, và người đăng nhập tiếp theo trên
    // cùng máy sẽ nhận nhầm tin của người trước.
    final token = _tokenDaLuu;
    if (token != null && !_dungThu) {
      _tokenDaLuu = null;
      await _repo.xoaThietBi(token);
      await _kenh?.xoaToken();
    }
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
  // ------------------------------------------------------------------ danh mục

  Future<void> _napDanhMuc() async {
    _tinh = await _repo.taiTinh();
    _truong = await _repo.taiTruong();
    _monHoc = await _repo.taiMonHoc();
    _giaoVien = await _repo.taiGiaoVien();
  }

  /// Nạp lại danh mục sau khi quản trị sửa, hoặc học sinh thêm thầy dạy thêm.
  Future<void> taiLaiDanhMuc() async {
    await _napDanhMuc();
    notifyListeners();
  }

  Future<void> luuTinh(Tinh t) async {
    await _repo.luuTinh(t.id.isEmpty ? Tinh(id: _id(), ten: t.ten) : t);
    await taiLaiDanhMuc();
  }

  Future<void> xoaTinh(String id) async {
    await _repo.xoaTinh(id);
    await taiLaiDanhMuc();
  }

  Future<void> luuTruong(Truong t) async {
    await _repo.luuTruong(
      t.id.isEmpty ? Truong(id: _id(), ten: t.ten, tinhId: t.tinhId) : t,
    );
    await taiLaiDanhMuc();
  }

  Future<void> xoaTruong(String id) async {
    await _repo.xoaTruong(id);
    await taiLaiDanhMuc();
  }

  Future<void> luuMonHoc(MonHoc m) async {
    await _repo.luuMonHoc(
      m.id.isEmpty ? MonHoc(id: _id(), ten: m.ten, vietTat: m.vietTat) : m,
    );
    await taiLaiDanhMuc();
  }

  Future<void> xoaMonHoc(String id) async {
    await _repo.xoaMonHoc(id);
    await taiLaiDanhMuc();
  }

  /// Lưu một thầy cô; id rỗng là thêm mới. Trả về id đã lưu để biểu mẫu vừa
  /// mở chọn ngay người vừa thêm.
  Future<String> luuGiaoVien(GiaoVien gv) async {
    final id = gv.id.isEmpty ? _id() : gv.id;
    await _repo.luuGiaoVien(GiaoVien(
      id: id,
      hoTen: gv.hoTen,
      monId: gv.monId,
      loai: gv.loai,
      noiDay: gv.noiDay,
      soDienThoai: gv.soDienThoai,
      truongId: gv.truongId,
      tinhId: gv.tinhId,
      chuId: gv.chuId,
    ));
    await taiLaiDanhMuc();
    return id;
  }

  Future<void> xoaGiaoVien(String id) async {
    await _repo.xoaGiaoVien(id);
    await taiLaiDanhMuc();
  }

  // ------------------------------------------------------------------ dữ liệu

  Future<void> chonCon(NguoiDung con) async {
    _conDangXem = con;
    notifyListeners();
    await taiLai();
  }

  /// Nạp lại mọi thứ có thể đã đổi từ máy khác: danh sách con (phụ huynh
  /// vừa được nối thêm), rồi dữ liệu của học sinh đang xem. Bài chờ mạng
  /// được thử gửi trước — quay lại app thường là lúc vừa có mạng.
  Future<void> taiLaiTatCa() async {
    await guiNhap();
    if (_nguoiDung?.vaiTro == VaiTro.phuHuynh) {
      await taiLaiDsCon();
    } else {
      await taiLai();
    }
  }

  /// Kéo để làm mới: gửi bài đang chờ rồi nạp lại.
  Future<void> lamMoi() async {
    await guiNhap();
    await taiLai();
  }

  /// Nạp lại toàn bộ dữ liệu của học sinh đang xem. Mất mạng thì giữ nguyên
  /// những gì đang có thay vì ném lỗi lên màn hình.
  Future<void> taiLai() async {
    try {
      await _napDuLieuHocSinh();
    } catch (e) {
      if (!laLoiMang(e)) rethrow;
    }
    notifyListeners();
  }

  Future<void> _napDuLieuHocSinh() async {
    final hs = hocSinhHienTai;
    if (hs == null) {
      _tkb = const [];
      _baoCao = const [];
      _nhacNho = const [];
      _phanThuong = const [];
      return;
    }
    _tkb = await _repo.thoiKhoaBieu(hs.id);
    _baoCao = await _repo.baoCao(hs.id);
    // Danh mục bài học của khối em đang học — để chọn bài lúc viết và để
    // bố mẹ đọc tóm tắt. Khối chưa có dữ liệu thì chỉ là danh sách rỗng.
    await _napBaiHoc(khoiTuLop(hs.lop));
    // Cả hai vai trò đọc cùng một dòng nhắc nhở gửi tới học sinh: học sinh
    // thấy lời mình nhận, phụ huynh thấy lời mình đã gửi.
    _nhacNho = await _repo.nhacNho(hs.id);
    _phanThuong = await _repo.phanThuong(hs.id);
  }

  /// Người dùng sửa hồ sơ của chính mình (hiện chỉ có chọn trường). Lưu xong
  /// đọc lại từ kho để trạng thái khớp với những gì server thực sự giữ.
  Future<void> capNhatHoSo(NguoiDung nd) async {
    await _repo.luuNguoiDung(nd);
    final moi = await _repo.hoSo(nd.id);
    if (moi != null && _nguoiDung?.id == moi.id) _nguoiDung = moi;
    notifyListeners();
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
        id: _id(),
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

  List<BaoCao> baoCaoNgay(DateTime ngay) => baoCao
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

  // ---------------------------------------------------------------- chuỗi

  /// Luật đếm chuỗi của học sinh đang xem: thứ nào không có tiết trong thời
  /// khóa biểu là ngày nghỉ (chưa nhập TKB thì coi Chủ nhật là nghỉ), và
  /// mỗi tuần một vé nghỉ.
  LuatChuoi get luatChuoi {
    final coTiet = _tkb.map((t) => t.thu == 8 ? 7 : t.thu - 1).toSet();
    final nghi = _tkb.isEmpty
        ? {DateTime.sunday}
        : {for (var d = 1; d <= 7; d++) if (!coTiet.contains(d)) d};
    return LuatChuoi(thuNghi: nghi, veMoiTuan: 1);
  }

  KetQuaChuoi get chuoi => demChuoi(baoCao, luat: luatChuoi);

  /// Chuỗi ngày liên tiếp gần nhất mà mọi bài tập đều đã xong.
  int get chuoiNgayTron => chuoi.hienTai;

  // ---------------------------------------------------------- phần thưởng

  List<PhanThuong> get phanThuong => _phanThuong;

  /// Từng phần thưởng kèm chỗ đứng của con: chuỗi đếm từ ngày treo, đã chạm
  /// mốc chưa. Chưa trao xếp trước, mốc gần xếp trước.
  List<TienDoPhanThuong> get tienDoPhanThuong {
    final ds = [
      for (final pt in _phanThuong)
        () {
          final kq = demChuoi(baoCao, luat: luatChuoi, tuNgay: pt.tuNgay);
          return TienDoPhanThuong(pt, hienTai: kq.hienTai, dat: kq.daiNhat >= pt.moc);
        }(),
    ]..sort((a, b) {
        if (a.phanThuong.daTrao != b.phanThuong.daTrao) return a.phanThuong.daTrao ? 1 : -1;
        return a.phanThuong.moc.compareTo(b.phanThuong.moc);
      });
    return ds;
  }

  /// Phụ huynh treo phần thưởng mới cho con đang xem.
  Future<void> treoPhanThuong({required int moc, required String ten}) async {
    final hs = hocSinhHienTai;
    final ph = _nguoiDung;
    if (hs == null || ph == null) return;
    await _repo.luuPhanThuong(PhanThuong(
      id: _id(),
      hocSinhId: hs.id,
      taoBoi: ph.id,
      moc: moc,
      ten: ten,
      tuNgay: Ngay.dauNgay(DateTime.now()),
      taoLuc: DateTime.now(),
    ));
    await taiLai();
  }

  Future<void> luuPhanThuong(PhanThuong pt) async {
    await _repo.luuPhanThuong(pt);
    await taiLai();
  }

  /// Bố mẹ đã đưa quà cho con.
  Future<void> traoPhanThuong(PhanThuong pt) =>
      luuPhanThuong(pt.copyWith(traoLuc: () => DateTime.now()));

  /// Treo lại cùng phần thưởng: chuỗi đếm lại từ hôm nay.
  Future<void> treoLaiPhanThuong(PhanThuong pt) => luuPhanThuong(
        pt.copyWith(tuNgay: Ngay.dauNgay(DateTime.now()), traoLuc: () => null),
      );

  Future<void> xoaPhanThuong(PhanThuong pt) async {
    await _repo.xoaPhanThuong(pt.hocSinhId, pt.id);
    await taiLai();
  }

  /// Bảng điểm danh của một ngày: môn có tiết mà chưa có báo cáo, kèm thầy
  /// cô và bài kế tiếp điền sẵn.
  List<MucDiemDanh> mucDiemDanh(DateTime ngay) => tinhMucDiemDanh(
        tkbTheoThu(Ngay.cotTuNgay(ngay)),
        baoCaoNgay(ngay),
        baiDangHoc: baiDangHoc,
        baiSau: baiSau,
      );

  BaoCao taoBaoCaoRong({
    required LoaiBaiTap loai,
    String? monId,
    String? giaoVienId,
    String? baiHocId,
    TrangThai trangThai = TrangThai.chuaLam,
    String noiDung = '',
    DateTime? ngay,
  }) =>
      BaoCao(
        id: _id(),
        hocSinhId: hocSinhHienTai?.id ?? '',
        ngay: ngay ?? Ngay.dauNgay(DateTime.now()),
        loai: loai,
        monId: monId ?? monMacDinh,
        giaoVienId: giaoVienId,
        baiHocId: baiHocId,
        noiDung: noiDung,
        trangThai: trangThai,
        taoLuc: DateTime.now(),
      );

  /// Ghi nhanh một môn từ bảng điểm danh: môn, thầy cô, hạng mục lấy từ thời
  /// khóa biểu, chỉ trạng thái (và bài, nếu em đổi) là do em chọn. Trả về
  /// báo cáo vừa tạo để còn mở ra ghi thêm.
  Future<(BaoCao, KetQuaLuu)> diemDanh(
    MucDiemDanh muc,
    TrangThai trangThai, {
    String? baiHocId,
    String noiDung = '',
    DateTime? ngay,
  }) async {
    final bc = taoBaoCaoRong(
      loai: muc.loai,
      monId: muc.monId,
      giaoVienId: muc.giaoVienId,
      baiHocId: baiHocId,
      trangThai: trangThai,
      noiDung: noiDung,
      ngay: ngay,
    );
    return (bc, await luuBaoCao(bc));
  }

  /// Lưu báo cáo. Có mạng thì lên máy chủ ngay; không có thì cất trên máy
  /// và trả về [KetQuaLuu.choMang] — bài vẫn hiện trong danh sách với nhãn
  /// chờ mạng, tự gửi khi có mạng lại.
  Future<KetQuaLuu> luuBaoCao(BaoCao bc) async {
    // Chỉ chính học sinh viết bài mới được đóng dấu; bố mẹ ghi nhận xét thì
    // không — kẻo dấu khen của con nhảy ra trên máy bố.
    final truoc = bc.hocSinhId == _nguoiDung?.id ? huyHieu : null;

    try {
      await _day(bc);
      await _boNhap(bc.id);
    } catch (e) {
      if (!laLoiMang(e)) rethrow;
      await _catNhap(bc);
      notifyListeners();
      _reoHuyHieu(truoc);
      return KetQuaLuu.choMang;
    }

    await taiLai();
    _reoHuyHieu(truoc);
    return KetQuaLuu.daGui;
  }

  void _reoHuyHieu(List<TienDoHuyHieu>? truoc) {
    if (truoc == null) return;
    for (final hh in huyHieuVuaDat(truoc, huyHieu)) {
      _huyHieuMoi.add(hh);
    }
  }

  /// Đưa một báo cáo lên máy chủ: ảnh mới chụp tải lên kho trước, ảnh đã có
  /// đường dẫn mạng giữ nguyên. Không nạp lại — người gọi lo việc đó.
  ///
  /// Mạng chập chờn có thể treo một lượt tải rất lâu; quá 30 giây coi như
  /// không có mạng, để bài được cất đi thay vì màn hình đứng mãi.
  Future<void> _day(BaoCao bc) => _dayKhongGioiHan(bc).timeout(const Duration(seconds: 30));

  Future<void> _dayKhongGioiHan(BaoCao bc) async {
    final anh = <String>[];
    for (final a in bc.anh) {
      if (a.startsWith('http') || a.startsWith('demo:')) {
        anh.add(a);
      } else {
        anh.add(await _repo.taiAnhLen(bc.hocSinhId, a));
      }
    }
    await _repo.luuBaoCao(bc.copyWith(anh: anh));
  }

  Future<void> _catNhap(BaoCao bc) async {
    // Ảnh chụp nằm trong cache, Android dọn bất cứ lúc nào — chép sang chỗ bền.
    final anh = <String>[];
    for (final a in bc.anh) {
      anh.add(a.startsWith('http') || a.startsWith('demo:') ? a : await _khoNhap.giuAnh(a));
    }
    _nhap = [..._nhap.where((b) => b.id != bc.id), bc.copyWith(anh: anh)];
    await _khoNhap.ghi(_nhap);
  }

  Future<void> _boNhap(String id) async {
    final cu = _nhap.where((b) => b.id == id).firstOrNull;
    if (cu == null) return;
    for (final a in cu.anh) {
      if (!a.startsWith('http') && !a.startsWith('demo:')) await _khoNhap.boAnh(a);
    }
    _nhap = _nhap.where((b) => b.id != id).toList();
    await _khoNhap.ghi(_nhap);
  }

  /// Thử gửi mọi bài đang chờ của người đang đăng nhập. Dừng ở bài đầu tiên
  /// vẫn không có mạng; bài bị máy chủ từ chối thì giữ lại cho người dùng
  /// tự xem. Trả về số bài đã lên.
  Future<int> guiNhap() async {
    final toi = _nguoiDung;
    if (toi == null || _dangGuiNhap || _dungThu) return 0;
    _dangGuiNhap = true;
    var daGui = 0;
    try {
      // Nháp của tài khoản khác từng dùng máy này thì để yên, chờ đúng chủ.
      for (final bc in _nhap.where((b) => b.hocSinhId == toi.id).toList()) {
        try {
          await _day(bc);
          await _boNhap(bc.id);
          daGui++;
        } catch (e) {
          if (laLoiMang(e)) break;
        }
      }
    } finally {
      _dangGuiNhap = false;
    }
    if (daGui > 0) {
      await taiLai();
    } else {
      notifyListeners();
    }
    return daGui;
  }

  Future<void> xoaBaoCao(String id) async {
    if (laNhap(id)) {
      await _boNhap(id);
      notifyListeners();
      return;
    }
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
      id: _id(),
      tuId: ph.id,
      denId: hs.id,
      noiDung: noiDung,
      taoLuc: DateTime.now(),
      hanLuc: hanLuc,
      baoCaoId: baoCaoId,
    ));
    await taiLai();
  }

  /// Đổi đường dẫn ảnh đã lưu thành địa chỉ xem được. Kho ảnh riêng tư nên
  /// mỗi lượt xem phải xin một URL ký có hạn.
  Future<String?> urlAnh(String duongDan) => _repo.urlAnh(duongDan);

  Future<void> docNhacNho(String id) async {
    final hs = hocSinhHienTai;
    if (hs == null) return;
    await _repo.danhDauDaDoc(hs.id, id);
    await taiLai();
  }
}
