import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'hoc_tap_repository.dart';

/// Bản cài đặt thật, chạy trên Supabase: Auth + Postgres + Storage.
///
/// Khác Firestore ở hai chỗ đáng kể:
///
/// - Liên kết phụ huynh với con là **một bảng quan hệ** (`lien_ket`), không
///   phải mảng nhét trong hồ sơ phụ huynh.
/// - Việc nối tài khoản làm bằng **hàm trong cơ sở dữ liệu** (`dung_ma_moi`)
///   chạy trong transaction ở server. Client không có quyền tự chèn một dòng
///   vào `lien_ket`, nên không cần mẹo "gửi kèm mã làm bằng chứng" như bản
///   Firestore trước đây.
///
/// Lược đồ và phân quyền: xem thư mục `supabase/`.
class SupabaseRepository implements HocTapRepository {
  SupabaseRepository([SupabaseClient? client])
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;
  GoTrueClient get _auth => _db.auth;

  static const bucketAnh = 'bai-lam';

  String? get _toi => _auth.currentUser?.id;

  // ------------------------------------------------------------ phiên đăng nhập

  @override
  Stream<NguoiDung?> phien() async* {
    yield await _hoSoHienTai();
    await for (final _ in _auth.onAuthStateChange) {
      yield await _hoSoHienTai();
    }
  }

  Future<NguoiDung?> _hoSoHienTai() async {
    final uid = _toi;
    if (uid == null) return null;
    try {
      final nd = await hoSo(uid);
      // Tài khoản bị khóa thì đá ra ngay, không để lọt vào trong app.
      if (nd == null || !nd.hoatDong) {
        await _auth.signOut();
        return null;
      }
      return nd;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<NguoiDung> dangNhap(String email, String matKhau) async {
    try {
      final kq = await _auth.signInWithPassword(
        email: email.trim(),
        password: matKhau,
      );
      final uid = kq.user?.id;
      if (uid == null) {
        throw const LoiHocTap('Không đăng nhập được. Thử lại sau.');
      }
      final nd = await hoSo(uid);
      if (nd == null) {
        await _auth.signOut();
        throw const LoiHocTap(
          'Tài khoản này chưa có hồ sơ. Liên hệ quản trị để được tạo lại.',
        );
      }
      if (!nd.hoatDong) {
        await _auth.signOut();
        throw const LoiHocTap('Tài khoản đang bị khóa. Liên hệ quản trị để mở lại.');
      }
      return nd;
    } on AuthException catch (e) {
      throw LoiHocTap(_dichLoiAuth(e, 'đăng nhập'), ma: e.code);
    }
  }

  @override
  Future<NguoiDung> dangKy({
    required String hoTen,
    required String email,
    required String matKhau,
    required VaiTro vaiTro,
    String? lop,
    String? truongId,
    String? soDienThoai,
  }) async {
    try {
      // Hồ sơ không do client chèn. Trigger `tao_ho_so_sau_dang_ky` trên
      // auth.users đọc mấy trường này và tự dựng hàng trong `nguoi_dung` —
      // nhân tiện kẹp luôn vai trò, gửi lên 'quanTri' cũng thành 'hocSinh',
      // và tra `truong_id` trong danh mục, id lạ thì coi như chưa chọn.
      final kq = await _auth.signUp(
        email: email.trim(),
        password: matKhau,
        data: {
          'ho_ten': hoTen.trim(),
          'vai_tro': vaiTro.name,
          if (soDienThoai != null) 'so_dien_thoai': soDienThoai.trim(),
          if (lop != null) 'lop': lop.trim(),
          'truong_id': ?truongId,
        },
      );

      final uid = kq.user?.id;
      if (uid == null) {
        throw const LoiHocTap('Không tạo được tài khoản. Thử lại sau.');
      }
      if (kq.session == null) {
        // Dự án đang bật xác nhận email. Tài khoản đã tạo nhưng chưa vào được.
        throw const LoiHocTap(
          'Đã tạo tài khoản. Mở email để xác nhận rồi quay lại đăng nhập.',
        );
      }

      final nd = await hoSo(uid);
      if (nd != null) return nd;

      // Trigger chạy sau khi hàng auth.users được ghi, thỉnh thoảng đọc ngay
      // thì chưa thấy. Chờ một nhịp rồi đọc lại.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final lai = await hoSo(uid);
      if (lai == null) {
        throw const LoiHocTap('Tạo tài khoản xong nhưng chưa dựng được hồ sơ.');
      }
      return lai;
    } on AuthException catch (e) {
      throw LoiHocTap(_dichLoiAuth(e, 'đăng ký'), ma: e.code);
    }
  }

  @override
  Future<void> guiEmailDatLaiMatKhau(String email) async {
    try {
      await _auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw LoiHocTap(_dichLoiAuth(e, 'gửi email đặt lại mật khẩu'), ma: e.code);
    }
  }

  @override
  Future<void> dangXuat() => _auth.signOut();

  /// Thông báo lỗi của Supabase là tiếng Anh dành cho lập trình viên. Người
  /// dùng cần biết chuyện gì xảy ra và làm gì tiếp, nên dịch ngay tại đây.
  String _dichLoiAuth(AuthException e, String viec) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'Email này đã có tài khoản. Đăng nhập hoặc dùng email khác.';
    }
    if (m.contains('password should be') || m.contains('at least 6')) {
      return 'Mật khẩu quá ngắn. Đặt ít nhất 6 ký tự.';
    }
    // Supabase từ chối địa chỉ email vì hai lý do rất khác nhau — sai định dạng,
    // hoặc tên miền nằm trong danh sách chặn (email.com, mailinator.com… là mail
    // dùng một lần). Thông báo của nó không phân biệt, nên câu trả lời phải bao
    // được cả hai, nếu không người dùng cứ sửa chính tả mãi mà không qua.
    if (m.contains('invalid email') ||
        m.contains('email address') && m.contains('invalid') ||
        m.contains('unable to validate email')) {
      return 'Email này không dùng được. Kiểm tra lại chính tả, và dùng tên miền '
          'thật — các dịch vụ mail tạm như email.com bị chặn.';
    }
    if (m.contains('email not confirmed')) {
      return 'Tài khoản chưa xác nhận email. Mở hộp thư và bấm vào link xác nhận.';
    }
    // Hai loại giới hạn rất khác nhau, và lời khuyên "đợi vài phút" chỉ đúng
    // với loại thứ hai. Giới hạn gửi email của gói miễn phí là 2 thư/giờ, nên
    // gộp chung sẽ khiến người dùng thử lại vô ích suốt cả tiếng.
    if (e.code == 'over_email_send_rate_limit' ||
        m.contains('email rate limit') ||
        m.contains('over_email_send_rate_limit')) {
      return 'Supabase đã hết lượt gửi email trong giờ này (gói miễn phí cho 2 '
          'thư mỗi giờ). Tắt "Confirm email" trong Authentication → Sign In / '
          'Providers thì đăng ký không cần gửi email nữa.';
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'Thử lại quá nhiều lần. Đợi vài phút rồi thử lại.';
    }
    if (m.contains('failed host lookup') || m.contains('socketexception')) {
      return 'Không có mạng. Kiểm tra kết nối rồi thử lại.';
    }
    return 'Không $viec được (${e.message}).';
  }
  // ------------------------------------------------------------------ danh mục

  @override
  Future<List<Tinh>> taiTinh() async {
    final ds = await _db.from('tinh').select().order('ten');
    return ds.map(TinhPg.fromMap).toList();
  }

  @override
  Future<List<Truong>> taiTruong() async {
    final ds = await _db.from('truong').select().order('ten');
    return ds.map(TruongPg.fromMap).toList();
  }

  @override
  Future<List<MonHoc>> taiMonHoc() async {
    final ds = await _db.from('mon_hoc').select().order('ten');
    return ds.map(MonHocPg.fromMap).toList();
  }

  /// RLS đã lọc sẵn: hàng chung ai cũng thấy, hàng riêng (`chu_id`) chỉ nhà
  /// em đó thấy. Client không cần thêm điều kiện gì.
  @override
  Future<List<GiaoVien>> taiGiaoVien() async {
    final ds = await _db.from('giao_vien').select().order('ho_ten');
    return ds.map(GiaoVienPg.fromMap).toList();
  }

  Future<void> _ghi(String bang, Map<String, Object?> hang) async {
    try {
      await _db.from(bang).upsert(hang);
    } on PostgrestException catch (e) {
      throw LoiHocTap(_dichLoiPg(e), ma: e.code);
    }
  }

  Future<void> _xoa(String bang, String id) async {
    try {
      await _db.from(bang).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw LoiHocTap(_dichLoiPg(e), ma: e.code);
    }
  }

  @override
  Future<void> luuTinh(Tinh t) => _ghi('tinh', t.toMap());
  @override
  Future<void> xoaTinh(String id) => _xoa('tinh', id);
  @override
  Future<void> luuTruong(Truong t) => _ghi('truong', t.toMap());
  @override
  Future<void> xoaTruong(String id) => _xoa('truong', id);
  @override
  Future<void> luuMonHoc(MonHoc m) => _ghi('mon_hoc', m.toMap());
  @override
  Future<void> xoaMonHoc(String id) => _xoa('mon_hoc', id);
  @override
  Future<void> luuGiaoVien(GiaoVien gv) => _ghi('giao_vien', gv.toMap());
  @override
  Future<void> xoaGiaoVien(String id) => _xoa('giao_vien', id);

  @override
  Future<List<BaiHoc>> taiBaiHoc(int lop) async {
    final ds = await _db
        .from('bai_hoc')
        .select()
        .eq('lop', lop)
        .order('mon_id')
        .order('thu_tu');
    return ds.map(BaiHocPg.fromMap).toList();
  }

  @override
  Future<void> luuBaiHoc(BaiHoc bh) => _ghi('bai_hoc', bh.toMap());
  @override
  Future<void> xoaBaiHoc(String id) => _xoa('bai_hoc', id);

  /// Nạp danh mục lần đầu cho một dự án còn trống. Không nằm trong interface vì
  /// chỉ quản trị chạy đúng một lần — xem nút "Nạp danh mục mẫu" ở màn
  /// Danh mục, hoặc chạy thẳng `supabase/05_danh_muc.sql`.
  Future<int> napDanhMucMau({
    required List<Tinh> tinh,
    required List<Truong> truong,
    required List<MonHoc> mon,
    required List<GiaoVien> gv,
  }) async {
    // Thứ tự theo khóa ngoại: trường cần tỉnh, thầy cô cần trường và môn.
    await _db.from('tinh').upsert(tinh.map((t) => t.toMap()).toList());
    await _db.from('truong').upsert(truong.map((t) => t.toMap()).toList());
    await _db.from('mon_hoc').upsert(mon.map((m) => m.toMap()).toList());
    await _db.from('giao_vien').upsert(gv.map((g) => g.toMap()).toList());
    return tinh.length + truong.length + mon.length + gv.length;
  }

  // ---------------------------------------------------------------- người dùng

  /// Danh sách con nằm ở bảng `lien_ket`, không nằm trong hồ sơ. Chỉ phụ huynh
  /// mới cần nên chỉ truy vấn thêm khi đúng vai trò đó.
  Future<List<String>> _conCua(String phuHuynhId) async {
    final ds = await _db
        .from('lien_ket')
        .select('hoc_sinh_id')
        .eq('phu_huynh_id', phuHuynhId)
        .order('tao_luc');
    return ds.map((e) => '${e['hoc_sinh_id']}').toList();
  }

  @override
  Future<NguoiDung?> hoSo(String id) async {
    final m = await _db.from('nguoi_dung').select().eq('id', id).maybeSingle();
    if (m == null) return null;
    final nd = NguoiDungPg.fromMap(m);
    if (nd.vaiTro != VaiTro.phuHuynh) return nd;
    return nd.copyWith(conIds: await _conCua(id));
  }

  @override
  Future<List<NguoiDung>> danhSachNguoiDung() async {
    final ds = await _db.from('nguoi_dung').select().order('ho_ten');
    final tatCa = ds.map((m) => NguoiDungPg.fromMap(m)).toList();

    // Một truy vấn cho toàn bộ liên kết rồi ghép trong bộ nhớ — rẻ hơn nhiều so
    // với gọi _conCua cho từng phụ huynh trong danh sách.
    final lk = await _db.from('lien_ket').select('phu_huynh_id, hoc_sinh_id');
    final theoPh = <String, List<String>>{};
    for (final e in lk) {
      theoPh
          .putIfAbsent('${e['phu_huynh_id']}', () => [])
          .add('${e['hoc_sinh_id']}');
    }

    return [
      for (final nd in tatCa)
        nd.vaiTro == VaiTro.phuHuynh
            ? nd.copyWith(conIds: theoPh[nd.id] ?? const [])
            : nd,
    ];
  }

  @override
  Future<List<NguoiDung>> danhSachCon(String phuHuynhId) async {
    final ids = await _conCua(phuHuynhId);
    if (ids.isEmpty) return const [];

    final ds = await _db.from('nguoi_dung').select().inFilter('id', ids);
    final ket = ds.map((m) => NguoiDungPg.fromMap(m)).toList();
    // Giữ đúng thứ tự đã liên kết, không theo thứ tự Postgres trả về.
    ket.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return ket;
  }

  @override
  Future<void> luuNguoiDung(NguoiDung nd) async {
    // Sửa hồ sơ của chính mình thì chỉ gửi các cột cá nhân: đụng vào `vai_tro`
    // hay `hoat_dong` sẽ bị trigger chan_tu_nang_quyen chặn lại.
    final laToi = nd.id == _toi;
    await _db
        .from('nguoi_dung')
        .update(laToi ? nd.toMapCaNhan() : nd.toMap())
        .eq('id', nd.id);
  }

  @override
  Future<void> lienKet(String phuHuynhId, String hocSinhId) => _db
      .from('lien_ket')
      .upsert({'phu_huynh_id': phuHuynhId, 'hoc_sinh_id': hocSinhId});

  @override
  Future<void> huyLienKet(String phuHuynhId, String hocSinhId) => _db
      .from('lien_ket')
      .delete()
      .eq('phu_huynh_id', phuHuynhId)
      .eq('hoc_sinh_id', hocSinhId);

  // -------------------------------------------------------------------- mã mời

  @override
  Future<MaMoi> taoMaMoi(String hocSinhId) async {
    try {
      final m = await _db.rpc<Map<String, dynamic>>('tao_ma_moi');
      return MaMoi.fromMap(m);
    } on PostgrestException catch (e) {
      throw LoiHocTap(_dichLoiPg(e), ma: e.code);
    }
  }

  @override
  Future<NguoiDung> dungMaMoi(String ma, String phuHuynhId) async {
    final maSach = ma.trim().replaceAll(RegExp(r'\D'), '');
    if (maSach.length != 6) {
      throw const LoiHocTap('Mã mời gồm đúng 6 chữ số.');
    }
    try {
      final m = await _db.rpc<Map<String, dynamic>>(
        'dung_ma_moi',
        params: {'p_ma': maSach},
      );
      return NguoiDungPg.fromMap(m);
    } on PostgrestException catch (e) {
      throw LoiHocTap(_dichLoiPg(e), ma: e.code);
    }
  }

  // ---------------------------------------------------------- thời khóa biểu

  @override
  Future<List<TietHoc>> thoiKhoaBieu(String hocSinhId) async {
    final ds = await _db
        .from('tiet_hoc')
        .select()
        .eq('hoc_sinh_id', hocSinhId)
        .order('thu')
        .order('tiet');
    return ds.map(TietHocPg.fromMap).toList();
  }

  @override
  Future<void> luuTietHoc(TietHoc tiet) => _db.from('tiet_hoc').upsert(tiet.toMap());

  @override
  Future<void> xoaTietHoc(String hocSinhId, String tietId) =>
      _db.from('tiet_hoc').delete().eq('id', tietId).eq('hoc_sinh_id', hocSinhId);

  // ------------------------------------------------------------------ báo cáo

  @override
  Future<List<BaoCao>> baoCao(String hocSinhId, {DateTime? ngay}) async {
    var q = _db.from('bao_cao').select().eq('hoc_sinh_id', hocSinhId);
    if (ngay != null) {
      q = q.eq('ngay', ngayIso(ngay));
    } else {
      // Bộ lọc xa nhất trong app là 90 ngày, lấy dư một chút cho tròn.
      final moc = DateTime.now().subtract(const Duration(days: 100));
      q = q.gte('ngay', ngayIso(moc));
    }
    final ds = await q.order('tao_luc', ascending: false);
    return ds.map(BaoCaoPg.fromMap).toList();
  }

  @override
  Future<void> luuBaoCao(BaoCao bc) async {
    try {
      // Phụ huynh chỉ được ghi lời nhận xét; gửi cả bản ghi lên sẽ đụng vào nội
      // dung của học sinh và trigger chan_phu_huynh_sua_bao_cao chặn lại.
      if (bc.hocSinhId != _toi) {
        await _db.from('bao_cao').update(bc.toMapNhanXet()).eq('id', bc.id);
        return;
      }
      await _db.from('bao_cao').upsert(bc.toMap());
    } on PostgrestException catch (e) {
      throw LoiHocTap(_dichLoiPg(e), ma: e.code);
    }
  }

  @override
  Future<void> xoaBaoCao(String hocSinhId, String id) async {
    // Xóa ảnh trước rồi mới xóa bản ghi: làm ngược lại mà nửa chừng hỏng thì
    // ảnh nằm lại trong kho không còn ai biết đường dẫn để dọn.
    final m = await _db
        .from('bao_cao')
        .select('anh')
        .eq('id', id)
        .maybeSingle();
    for (final duongDan in chuoiTu(m?['anh'])) {
      await xoaAnh(duongDan);
    }
    await _db.from('bao_cao').delete().eq('id', id).eq('hoc_sinh_id', hocSinhId);
  }

  // ----------------------------------------------------------------- nhắc nhở

  @override
  Future<List<NhacNho>> nhacNho(String hocSinhId) async {
    final ds = await _db
        .from('nhac_nho')
        .select()
        .eq('den_id', hocSinhId)
        .order('tao_luc', ascending: false)
        .limit(100);
    return ds.map(NhacNhoPg.fromMap).toList();
  }

  @override
  Future<void> guiNhacNho(NhacNho nn) async {
    try {
      await _db.from('nhac_nho').insert(nn.toMap());
    } on PostgrestException catch (e) {
      throw LoiHocTap(_dichLoiPg(e), ma: e.code);
    }
  }

  @override
  Future<void> danhDauDaDoc(String hocSinhId, String nhacNhoId) => _db
      .from('nhac_nho')
      .update({'da_doc': true})
      .eq('id', nhacNhoId)
      .eq('den_id', hocSinhId);

  // ----------------------------------------------------------------- thiết bị

  @override
  Future<void> luuThietBi(String token) async {
    final toi = _toi;
    if (toi == null) return;
    try {
      await _db.from('thiet_bi').upsert({
        'token': token,
        'nguoi_dung_id': toi,
        'nen_tang': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'cap_nhat_luc': DateTime.now().toUtc().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      // Bảng chưa dựng (chưa chạy 06_thong_bao.sql) thì app vẫn phải chạy.
      debugPrint('Không lưu được thiết bị nhận thông báo: ${e.message}');
    }
  }

  @override
  Future<void> xoaThietBi(String token) async {
    try {
      await _db.from('thiet_bi').delete().eq('token', token);
    } on PostgrestException {
      // Không có mạng hay bảng chưa có: không chặn việc đăng xuất.
    }
  }

  // ---------------------------------------------------------------------- ảnh

  @override
  Future<String> taiAnhLen(String hocSinhId, String duongDanCucBo) async {
    // Thư mục đầu tiên phải là id học sinh — luật trên storage.objects đọc đúng
    // đoạn đó để biết ai được xem tấm ảnh này.
    final ten = '$hocSinhId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      // XFile đọc được cả file trên máy lẫn blob: của trình duyệt — nhờ vậy
      // cùng một đoạn mã chạy trên điện thoại và trên web.
      final bytes = await XFile(duongDanCucBo).readAsBytes();
      await _db.storage.from(bucketAnh).uploadBinary(
            ten,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      return ten;
    } on StorageException catch (e) {
      throw LoiHocTap('Không tải được ảnh lên (${e.message}).', ma: e.statusCode);
    }
  }

  @override
  Future<void> xoaAnh(String duongDan) async {
    if (duongDan.startsWith('demo:')) return;
    try {
      await _db.storage.from(bucketAnh).remove([duongDan]);
    } on StorageException {
      // Ảnh đã bị xóa từ trước thì thôi, không có gì để người dùng phải biết.
    }
  }

  /// Bucket để riêng tư nên ảnh phải xem qua URL ký có hạn, không phát tán link
  /// công khai. Một giờ là quá đủ cho một lượt mở màn chi tiết.
  @override
  Future<String?> urlAnh(String duongDan) async {
    if (duongDan.startsWith('demo:')) return null;
    try {
      return await _db.storage.from(bucketAnh).createSignedUrl(duongDan, 3600);
    } on StorageException {
      return null;
    }
  }

  String _dichLoiPg(PostgrestException e) {
    final m = e.message;
    // Thông báo do hàm và trigger của mình ném ra vốn đã là tiếng Việt.
    if (RegExp(r'[àáâãèéêìíòóôõùúýăđĩũơưạảấầẩẫậắằẳẵặẹẻẽếềể]').hasMatch(m)) {
      return m;
    }
    if (m.contains('duplicate key')) return 'Dữ liệu này đã tồn tại.';
    if (m.contains('violates row-level security')) {
      return 'Bạn không có quyền thực hiện việc này.';
    }
    if (m.contains('violates foreign key')) {
      return 'Dữ liệu tham chiếu tới một mục không còn tồn tại.';
    }
    return 'Thao tác không thành công ($m).';
  }
}
