import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/models.dart';
import 'hoc_tap_repository.dart';

/// Bản cài đặt thật, chạy trên Firebase Auth + Firestore + Storage.
///
/// Sơ đồ dữ liệu:
/// ```
/// nguoiDung/{uid}                     hồ sơ, vai trò, conIds
/// monHoc/{id} · giaoVien/{id}         danh mục dùng chung, chỉ quản trị sửa
/// hocSinh/{hsId}/tietHoc/{id}
/// hocSinh/{hsId}/baoCao/{id}
/// hocSinh/{hsId}/nhacNho/{id}
/// maMoi/{ma}                          mã sáu số, sống 15 phút, dùng một lần
/// ```
/// Dữ liệu học tập nằm dưới `hocSinh/{hsId}` để luật bảo mật chỉ cần một phép
/// kiểm tra ở cấp thư mục: người đọc phải là chính học sinh đó, hoặc là phụ
/// huynh có `hsId` trong `conIds`.
class FirebaseRepository implements HocTapRepository {
  FirebaseRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseStorage? kho,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _kho = kho ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _kho;

  CollectionReference<Map<String, dynamic>> get _nguoiDung => _db.collection('nguoiDung');
  CollectionReference<Map<String, dynamic>> get _maMoi => _db.collection('maMoi');
  CollectionReference<Map<String, dynamic>> _cua(String hocSinhId, String muc) =>
      _db.collection('hocSinh').doc(hocSinhId).collection(muc);

  // ------------------------------------------------------------ phiên đăng nhập

  @override
  Stream<NguoiDung?> phien() => _auth.authStateChanges().asyncMap((u) async {
        if (u == null) return null;
        final nd = await hoSo(u.uid);
        // Tài khoản bị khóa thì đá ra ngay, không để lọt vào trong app.
        if (nd == null || !nd.hoatDong) {
          await _auth.signOut();
          return null;
        }
        return nd;
      });

  @override
  Future<NguoiDung> dangNhap(String email, String matKhau) async {
    try {
      final kq = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: matKhau,
      );
      final nd = await hoSo(kq.user!.uid);
      if (nd == null) {
        await _auth.signOut();
        throw const LoiHocTap('Tài khoản này chưa có hồ sơ. Liên hệ quản trị để được tạo lại.');
      }
      if (!nd.hoatDong) {
        await _auth.signOut();
        throw const LoiHocTap('Tài khoản đang bị khóa. Liên hệ quản trị để mở lại.');
      }
      return nd;
    } on FirebaseAuthException catch (e) {
      throw LoiHocTap(_dichLoiAuth(e), ma: e.code);
    }
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
    try {
      final kq = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: matKhau,
      );
      final nd = NguoiDung(
        id: kq.user!.uid,
        hoTen: hoTen.trim(),
        vaiTro: vaiTro,
        email: email.trim(),
        soDienThoai: soDienThoai,
        lop: lop,
        truong: truong,
      );
      await _nguoiDung.doc(nd.id).set(nd.toMap());
      await kq.user!.updateDisplayName(nd.hoTen);
      return nd;
    } on FirebaseAuthException catch (e) {
      throw LoiHocTap(_dichLoiAuth(e), ma: e.code);
    }
  }

  @override
  Future<void> guiEmailDatLaiMatKhau(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw LoiHocTap(_dichLoiAuth(e), ma: e.code);
    }
  }

  @override
  Future<void> dangXuat() => _auth.signOut();

  /// Mã lỗi của Firebase là tiếng Anh dành cho lập trình viên. Người dùng cần
  /// biết chuyện gì xảy ra và làm gì tiếp, nên dịch ngay tại đây.
  String _dichLoiAuth(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => 'Địa chỉ email không đúng định dạng.',
        'user-disabled' => 'Tài khoản này đã bị khóa.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Email hoặc mật khẩu không đúng.',
        'email-already-in-use' =>
          'Email này đã có tài khoản. Đăng nhập hoặc dùng email khác.',
        'weak-password' => 'Mật khẩu quá ngắn. Đặt ít nhất 6 ký tự.',
        'too-many-requests' =>
          'Thử lại quá nhiều lần. Đợi vài phút rồi thử lại.',
        'network-request-failed' =>
          'Không có mạng. Kiểm tra kết nối rồi thử lại.',
        'operation-not-allowed' =>
          'Cách đăng nhập này chưa được bật trong Firebase Console.',
        _ => 'Không đăng nhập được (${e.code}).',
      };
  // ------------------------------------------------------------------ danh mục

  @override
  Future<List<MonHoc>> taiMonHoc() async {
    final s = await _db.collection('monHoc').orderBy('ten').get();
    return s.docs.map((d) => MonHocFs.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<List<GiaoVien>> taiGiaoVien() async {
    final s = await _db.collection('giaoVien').orderBy('hoTen').get();
    return s.docs.map((d) => GiaoVienFs.fromMap(d.id, d.data())).toList();
  }

  // ---------------------------------------------------------------- người dùng

  @override
  Future<NguoiDung?> hoSo(String id) async {
    final d = await _nguoiDung.doc(id).get();
    final m = d.data();
    return m == null ? null : NguoiDungFs.fromMap(d.id, m);
  }

  @override
  Future<List<NguoiDung>> danhSachNguoiDung() async {
    final s = await _nguoiDung.orderBy('hoTen').get();
    return s.docs.map((d) => NguoiDungFs.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<List<NguoiDung>> danhSachCon(String phuHuynhId) async {
    final ph = await hoSo(phuHuynhId);
    final ids = ph?.conIds ?? const <String>[];
    if (ids.isEmpty) return const [];

    // whereIn chỉ nhận 30 giá trị một lượt; chia lô cho chắc, dù trên thực tế
    // không phụ huynh nào có tới ngần ấy con.
    final ket = <NguoiDung>[];
    for (var i = 0; i < ids.length; i += 30) {
      final lo = ids.sublist(i, min(i + 30, ids.length));
      final s = await _nguoiDung.where(FieldPath.documentId, whereIn: lo).get();
      ket.addAll(s.docs.map((d) => NguoiDungFs.fromMap(d.id, d.data())));
    }
    // Giữ đúng thứ tự phụ huynh đã liên kết, không theo thứ tự Firestore trả về.
    ket.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return ket;
  }

  @override
  Future<void> luuNguoiDung(NguoiDung nd) =>
      _nguoiDung.doc(nd.id).set(nd.toMap(), SetOptions(merge: true));

  @override
  Future<void> lienKet(String phuHuynhId, String hocSinhId) => _nguoiDung
      .doc(phuHuynhId)
      .update({'conIds': FieldValue.arrayUnion([hocSinhId])});

  @override
  Future<void> huyLienKet(String phuHuynhId, String hocSinhId) => _nguoiDung
      .doc(phuHuynhId)
      .update({'conIds': FieldValue.arrayRemove([hocSinhId])});

  // -------------------------------------------------------------------- mã mời

  static const _hanMaMoi = Duration(minutes: 15);

  @override
  Future<MaMoi> taoMaMoi(String hocSinhId) async {
    // Vô hiệu mã cũ trước: mỗi học sinh chỉ nên có đúng một mã sống, để lỡ đọc
    // nhầm mã cũ cho bố mẹ thì cũng không nối vào được.
    final cu = await _maMoi.where('hocSinhId', isEqualTo: hocSinhId).get();
    for (final d in cu.docs) {
      if (d.data()['daDung'] != true) {
        await d.reference.update({'daDung': true});
      }
    }

    final rnd = Random.secure();
    for (var lan = 0; lan < 6; lan++) {
      final ma = rnd.nextInt(1000000).toString().padLeft(6, '0');
      final doc = _maMoi.doc(ma);
      if ((await doc.get()).exists) continue;

      final moi = MaMoi(
        ma: ma,
        hocSinhId: hocSinhId,
        hetHan: DateTime.now().add(_hanMaMoi),
      );
      await doc.set(moi.toMap());
      return moi;
    }
    throw const LoiHocTap('Chưa sinh được mã mời. Thử lại sau một lát.');
  }

  @override
  Future<NguoiDung> dungMaMoi(String ma, String phuHuynhId) async {
    final maSach = ma.trim().replaceAll(RegExp(r'\D'), '');
    if (maSach.length != 6) {
      throw const LoiHocTap('Mã mời gồm đúng 6 chữ số.');
    }

    final hocSinhId = await _db.runTransaction<String>((tx) async {
      final doc = _maMoi.doc(maSach);
      final snap = await tx.get(doc);
      final m = snap.data();
      if (m == null) {
        throw const LoiHocTap('Mã mời không đúng. Nhờ con đọc lại mã.');
      }
      if (m['daDung'] == true) {
        throw const LoiHocTap('Mã mời này đã được dùng rồi. Nhờ con tạo mã mới.');
      }
      final hetHan = ngayTu(m['hetHan']);
      if (hetHan == null || hetHan.isBefore(DateTime.now())) {
        throw const LoiHocTap('Mã mời đã hết hạn. Nhờ con tạo mã mới.');
      }

      final hsId = '${m['hocSinhId']}';
      tx.update(doc, {'daDung': true});
      // `maMoiDaDung` là bằng chứng cho luật bảo mật: server không tin client
      // nói "tôi là phụ huynh của em này", nó tự đối chiếu mã kèm theo với
      // học sinh đang được thêm vào. Xem hàm themConHopLe trong firestore.rules.
      tx.update(_nguoiDung.doc(phuHuynhId), {
        'conIds': FieldValue.arrayUnion([hsId]),
        'maMoiDaDung': maSach,
      });
      return hsId;
    });

    final hs = await hoSo(hocSinhId);
    if (hs == null) {
      throw const LoiHocTap('Không tìm thấy hồ sơ học sinh của mã này.');
    }
    return hs;
  }

  // ---------------------------------------------------------- thời khóa biểu

  @override
  Future<List<TietHoc>> thoiKhoaBieu(String hocSinhId) async {
    final s = await _cua(hocSinhId, 'tietHoc').get();
    final ds = s.docs.map((d) => TietHocFs.fromMap(d.id, d.data())).toList();
    ds.sort((a, b) {
      final t = a.thu.compareTo(b.thu);
      if (t != 0) return t;
      final b1 = a.buoi.index.compareTo(b.buoi.index);
      return b1 != 0 ? b1 : a.tiet.compareTo(b.tiet);
    });
    return ds;
  }

  @override
  Future<void> luuTietHoc(TietHoc tiet) =>
      _cua(tiet.hocSinhId, 'tietHoc').doc(tiet.id).set(tiet.toMap());

  @override
  Future<void> xoaTietHoc(String hocSinhId, String tietId) =>
      _cua(hocSinhId, 'tietHoc').doc(tietId).delete();

  // ------------------------------------------------------------------ báo cáo

  @override
  Future<List<BaoCao>> baoCao(String hocSinhId, {DateTime? ngay}) async {
    Query<Map<String, dynamic>> q = _cua(hocSinhId, 'baoCao');
    if (ngay != null) {
      q = q.where('khoaNgay', isEqualTo: _khoaNgay(ngay));
    } else {
      // Chỉ tải hai tháng gần nhất: màn hình xa nhất cũng chỉ lọc tới 90 ngày,
      // và tải cả đời học sinh về máy là vô nghĩa.
      final moc = DateTime.now().subtract(const Duration(days: 62));
      q = q.where('ngay', isGreaterThanOrEqualTo: Timestamp.fromDate(moc));
    }
    final s = await q.get();
    final ds = s.docs.map((d) => BaoCaoFs.fromMap(d.id, d.data())).toList();
    ds.sort((a, b) => b.taoLuc.compareTo(a.taoLuc));
    return ds;
  }

  static String _khoaNgay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<void> luuBaoCao(BaoCao bc) =>
      _cua(bc.hocSinhId, 'baoCao').doc(bc.id).set(bc.toMap());

  @override
  Future<void> xoaBaoCao(String hocSinhId, String id) async {
    // Xóa ảnh trước rồi mới xóa bản ghi: nếu làm ngược lại mà nửa chừng hỏng
    // thì ảnh nằm lại trong kho mà không còn ai biết đường dẫn để dọn.
    final doc = _cua(hocSinhId, 'baoCao').doc(id);
    final m = (await doc.get()).data();
    for (final url in chuoiTu(m?['anh'])) {
      await xoaAnh(url);
    }
    await doc.delete();
  }

  // ----------------------------------------------------------------- nhắc nhở

  @override
  Future<List<NhacNho>> nhacNho(String hocSinhId) async {
    final s = await _cua(hocSinhId, 'nhacNho')
        .orderBy('taoLuc', descending: true)
        .limit(100)
        .get();
    return s.docs.map((d) => NhacNhoFs.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<void> guiNhacNho(NhacNho nn) =>
      _cua(nn.denId, 'nhacNho').doc(nn.id).set(nn.toMap());

  @override
  Future<void> danhDauDaDoc(String hocSinhId, String nhacNhoId) =>
      _cua(hocSinhId, 'nhacNho').doc(nhacNhoId).update({'daDoc': true});

  // ---------------------------------------------------------------------- ảnh

  @override
  Future<String> taiAnhLen(String hocSinhId, String duongDanCucBo) async {
    final ten = '${DateTime.now().millisecondsSinceEpoch}_'
        '${Random().nextInt(9999)}.jpg';
    final o = _kho.ref('baiLam/$hocSinhId/$ten');
    try {
      await o.putFile(
        File(duongDanCucBo),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await o.getDownloadURL();
    } on FirebaseException catch (e) {
      throw LoiHocTap('Không tải được ảnh lên (${e.code}).', ma: e.code);
    }
  }

  @override
  Future<void> xoaAnh(String duongDan) async {
    if (!duongDan.startsWith('http')) return;
    try {
      await _kho.refFromURL(duongDan).delete();
    } on FirebaseException {
      // Ảnh đã bị xóa từ trước thì thôi, không có gì để người dùng phải biết.
    }
  }

  /// Nạp danh mục môn học và thầy cô lần đầu cho một project Firebase trống.
  /// Không nằm trong interface vì chỉ quản trị chạy đúng một lần khi dựng hệ
  /// thống — xem nút "Nạp danh mục mẫu" ở màn Môn & thầy cô.
  Future<int> napDanhMucMau(List<MonHoc> mon, List<GiaoVien> gv) async {
    final lo = _db.batch();
    for (final m in mon) {
      lo.set(_db.collection('monHoc').doc(m.id), m.toMap());
    }
    for (final g in gv) {
      lo.set(_db.collection('giaoVien').doc(g.id), g.toMap());
    }
    await lo.commit();
    return mon.length + gv.length;
  }
}
