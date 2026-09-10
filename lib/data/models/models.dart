import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

enum VaiTro {
  phuHuynh('Phụ huynh', Icons.family_restroom_rounded),
  hocSinh('Học sinh', Icons.backpack_rounded),
  quanTri('Quản trị', Icons.shield_moon_rounded);

  const VaiTro(this.nhan, this.icon);
  final String nhan;
  final IconData icon;
}

/// Hai hạng mục bài tập mà phụ huynh cần tách bạch khi xem báo cáo.
enum LoaiBaiTap {
  trenLop('Bài tập trên lớp', 'Trên lớp', AppColor.muc, AppColor.sky),
  hocThem('Bài tập học thêm', 'Học thêm', AppColor.hocThem, AppColor.hocThemNhat);

  const LoaiBaiTap(this.nhan, this.nhanNgan, this.mau, this.mauNen);
  final String nhan;
  final String nhanNgan;
  final Color mau;
  final Color mauNen;
}

/// Trạng thái quyết định màu của đường lề đỏ trên trang vở.
enum TrangThai {
  chuaLam('Chưa làm', AppColor.butDo, AppColor.butDoNhat, Icons.radio_button_unchecked_rounded),
  dangLam('Đang làm', AppColor.dangLam, AppColor.dangLamNhat, Icons.timelapse_rounded),
  xong('Đã xong', AppColor.xong, AppColor.xongNhat, Icons.check_circle_rounded);

  const TrangThai(this.nhan, this.mau, this.mauNen, this.icon);
  final String nhan;
  final Color mau;
  final Color mauNen;
  final IconData icon;
}

enum Buoi {
  sang('Sáng'),
  chieu('Chiều'),
  toi('Tối');

  const Buoi(this.nhan);
  final String nhan;
}

class NguoiDung {
  const NguoiDung({
    required this.id,
    required this.hoTen,
    required this.vaiTro,
    this.email,
    this.soDienThoai,
    this.lop,
    this.truong,
    this.conIds = const [],
    this.hoatDong = true,
  });

  final String id;
  final String hoTen;
  final VaiTro vaiTro;
  final String? email;
  final String? soDienThoai;

  /// Chỉ có ở học sinh.
  final String? lop;
  final String? truong;

  /// Chỉ có ở phụ huynh — danh sách id học sinh được liên kết.
  final List<String> conIds;
  final bool hoatDong;

  String get tenGoi => hoTen.split(' ').last;

  String get chuCaiDau {
    final phan = hoTen.trim().split(RegExp(r'\s+'));
    if (phan.length == 1) return phan.first.characters.first.toUpperCase();
    return (phan.first.characters.first + phan.last.characters.first).toUpperCase();
  }

  NguoiDung copyWith({
    String? hoTen,
    String? email,
    String? soDienThoai,
    String? lop,
    String? truong,
    List<String>? conIds,
    bool? hoatDong,
  }) =>
      NguoiDung(
        id: id,
        hoTen: hoTen ?? this.hoTen,
        vaiTro: vaiTro,
        email: email ?? this.email,
        soDienThoai: soDienThoai ?? this.soDienThoai,
        lop: lop ?? this.lop,
        truong: truong ?? this.truong,
        conIds: conIds ?? this.conIds,
        hoatDong: hoatDong ?? this.hoatDong,
      );
}

class MonHoc {
  const MonHoc({required this.id, required this.ten, required this.vietTat});

  final String id;
  final String ten;
  final String vietTat;
}

class GiaoVien {
  const GiaoVien({
    required this.id,
    required this.hoTen,
    required this.monId,
    required this.loai,
    this.noiDay,
    this.soDienThoai,
  });

  final String id;
  final String hoTen;
  final String monId;

  /// Thầy cô trên lớp hay thầy cô dạy thêm — báo cáo học thêm bám theo từng người.
  final LoaiBaiTap loai;
  final String? noiDay;
  final String? soDienThoai;

  String get xungHo => hoTen;
}

class TietHoc {
  const TietHoc({
    required this.id,
    required this.hocSinhId,
    required this.thu,
    required this.tiet,
    required this.buoi,
    required this.monId,
    required this.loai,
    this.giaoVienId,
    this.phong,
    this.batDau,
    this.ketThuc,
  });

  final String id;
  final String hocSinhId;

  /// 2..7 ứng với Thứ Hai..Thứ Bảy, 8 là Chủ nhật.
  final int thu;
  final int tiet;
  final Buoi buoi;
  final String monId;
  final LoaiBaiTap loai;
  final String? giaoVienId;
  final String? phong;
  final String? batDau;
  final String? ketThuc;

  String get khungGio => (batDau != null && ketThuc != null) ? '$batDau – $ketThuc' : '';

  TietHoc copyWith({
    int? thu,
    int? tiet,
    Buoi? buoi,
    String? monId,
    LoaiBaiTap? loai,
    String? giaoVienId,
    String? phong,
    String? batDau,
    String? ketThuc,
  }) =>
      TietHoc(
        id: id,
        hocSinhId: hocSinhId,
        thu: thu ?? this.thu,
        tiet: tiet ?? this.tiet,
        buoi: buoi ?? this.buoi,
        monId: monId ?? this.monId,
        loai: loai ?? this.loai,
        giaoVienId: giaoVienId ?? this.giaoVienId,
        phong: phong ?? this.phong,
        batDau: batDau ?? this.batDau,
        ketThuc: ketThuc ?? this.ketThuc,
      );
}

class BaoCao {
  const BaoCao({
    required this.id,
    required this.hocSinhId,
    required this.ngay,
    required this.loai,
    required this.monId,
    required this.noiDung,
    required this.trangThai,
    required this.taoLuc,
    this.giaoVienId,
    this.anh = const [],
    this.soPhut,
    this.nhanXetPhuHuynh,
    this.phuHuynhDaXem = false,
  });

  final String id;
  final String hocSinhId;
  final DateTime ngay;
  final LoaiBaiTap loai;
  final String monId;
  final String? giaoVienId;
  final String noiDung;
  final TrangThai trangThai;

  /// Đường dẫn ảnh chụp bài — không bắt buộc.
  final List<String> anh;
  final int? soPhut;
  final String? nhanXetPhuHuynh;
  final bool phuHuynhDaXem;
  final DateTime taoLuc;

  BaoCao copyWith({
    DateTime? ngay,
    LoaiBaiTap? loai,
    String? monId,
    String? giaoVienId,
    String? noiDung,
    TrangThai? trangThai,
    List<String>? anh,
    int? soPhut,
    String? nhanXetPhuHuynh,
    bool? phuHuynhDaXem,
  }) =>
      BaoCao(
        id: id,
        hocSinhId: hocSinhId,
        ngay: ngay ?? this.ngay,
        loai: loai ?? this.loai,
        monId: monId ?? this.monId,
        giaoVienId: giaoVienId ?? this.giaoVienId,
        noiDung: noiDung ?? this.noiDung,
        trangThai: trangThai ?? this.trangThai,
        anh: anh ?? this.anh,
        soPhut: soPhut ?? this.soPhut,
        nhanXetPhuHuynh: nhanXetPhuHuynh ?? this.nhanXetPhuHuynh,
        phuHuynhDaXem: phuHuynhDaXem ?? this.phuHuynhDaXem,
        taoLuc: taoLuc,
      );
}

class NhacNho {
  const NhacNho({
    required this.id,
    required this.tuId,
    required this.denId,
    required this.noiDung,
    required this.taoLuc,
    this.hanLuc,
    this.daDoc = false,
    this.baoCaoId,
  });

  final String id;
  final String tuId;
  final String denId;
  final String noiDung;
  final DateTime taoLuc;
  final DateTime? hanLuc;
  final bool daDoc;
  final String? baoCaoId;

  NhacNho copyWith({bool? daDoc}) => NhacNho(
        id: id,
        tuId: tuId,
        denId: denId,
        noiDung: noiDung,
        taoLuc: taoLuc,
        hanLuc: hanLuc,
        daDoc: daDoc ?? this.daDoc,
        baoCaoId: baoCaoId,
      );
}

/// Tổng hợp một ngày để hiện nhanh trên trang chủ phụ huynh.
class TongKetNgay {
  const TongKetNgay({
    required this.xong,
    required this.dangLam,
    required this.chuaLam,
    required this.soPhut,
  });

  final int xong;
  final int dangLam;
  final int chuaLam;
  final int soPhut;

  int get tong => xong + dangLam + chuaLam;
  double get tiLeXong => tong == 0 ? 0 : xong / tong;
}

// ---------------------------------------------------------------------------
// Chuyển đổi sang/từ Firestore
//
// Models cố tình không import cloud_firestore: kiểu Timestamp được đọc qua
// `dynamic` nên tầng miền vẫn dùng được ở test và ở bản mock mà không kéo
// theo SDK.
// ---------------------------------------------------------------------------

/// Đọc một giá trị ngày về DateTime, dù nó là Timestamp, DateTime, chuỗi ISO
/// hay số mili-giây.
DateTime? ngayTu(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  final d = (v as dynamic).toDate();
  return d is DateTime ? d : null;
}

/// Đọc tên enum đã lưu; giá trị lạ hoặc thiếu thì rơi về mặc định.
T enumTu<T extends Enum>(List<T> ds, Object? v, T macDinh) =>
    ds.where((e) => e.name == v).firstOrNull ?? macDinh;

List<String> chuoiTu(Object? v) =>
    v is List ? v.map((e) => '$e').toList() : const [];

extension NguoiDungFs on NguoiDung {
  Map<String, Object?> toMap() => {
        'hoTen': hoTen,
        'vaiTro': vaiTro.name,
        'email': email,
        'soDienThoai': soDienThoai,
        'lop': lop,
        'truong': truong,
        'conIds': conIds,
        'hoatDong': hoatDong,
      };

  static NguoiDung fromMap(String id, Map<String, Object?> m) => NguoiDung(
        id: id,
        hoTen: '${m['hoTen'] ?? ''}',
        vaiTro: enumTu(VaiTro.values, m['vaiTro'], VaiTro.hocSinh),
        email: m['email'] as String?,
        soDienThoai: m['soDienThoai'] as String?,
        lop: m['lop'] as String?,
        truong: m['truong'] as String?,
        conIds: chuoiTu(m['conIds']),
        hoatDong: m['hoatDong'] as bool? ?? true,
      );
}

extension MonHocFs on MonHoc {
  Map<String, Object?> toMap() => {'ten': ten, 'vietTat': vietTat};

  static MonHoc fromMap(String id, Map<String, Object?> m) => MonHoc(
        id: id,
        ten: '${m['ten'] ?? ''}',
        vietTat: '${m['vietTat'] ?? m['ten'] ?? ''}',
      );
}

extension GiaoVienFs on GiaoVien {
  Map<String, Object?> toMap() => {
        'hoTen': hoTen,
        'monId': monId,
        'loai': loai.name,
        'noiDay': noiDay,
        'soDienThoai': soDienThoai,
      };

  static GiaoVien fromMap(String id, Map<String, Object?> m) => GiaoVien(
        id: id,
        hoTen: '${m['hoTen'] ?? ''}',
        monId: '${m['monId'] ?? ''}',
        loai: enumTu(LoaiBaiTap.values, m['loai'], LoaiBaiTap.trenLop),
        noiDay: m['noiDay'] as String?,
        soDienThoai: m['soDienThoai'] as String?,
      );
}

extension TietHocFs on TietHoc {
  Map<String, Object?> toMap() => {
        'hocSinhId': hocSinhId,
        'thu': thu,
        'tiet': tiet,
        'buoi': buoi.name,
        'monId': monId,
        'loai': loai.name,
        'giaoVienId': giaoVienId,
        'phong': phong,
        'batDau': batDau,
        'ketThuc': ketThuc,
      };

  static TietHoc fromMap(String id, Map<String, Object?> m) => TietHoc(
        id: id,
        hocSinhId: '${m['hocSinhId'] ?? ''}',
        thu: (m['thu'] as num?)?.toInt() ?? 2,
        tiet: (m['tiet'] as num?)?.toInt() ?? 1,
        buoi: enumTu(Buoi.values, m['buoi'], Buoi.sang),
        monId: '${m['monId'] ?? ''}',
        loai: enumTu(LoaiBaiTap.values, m['loai'], LoaiBaiTap.trenLop),
        giaoVienId: m['giaoVienId'] as String?,
        phong: m['phong'] as String?,
        batDau: m['batDau'] as String?,
        ketThuc: m['ketThuc'] as String?,
      );
}

extension BaoCaoFs on BaoCao {
  Map<String, Object?> toMap() => {
        'hocSinhId': hocSinhId,
        'ngay': ngay,
        // Khóa ngày dạng chuỗi để truy vấn "báo cáo của ngày X" chỉ cần so
        // sánh bằng, khỏi phải dựng chỉ mục cho khoảng thời gian.
        'khoaNgay': khoaNgay,
        'loai': loai.name,
        'monId': monId,
        'giaoVienId': giaoVienId,
        'noiDung': noiDung,
        'trangThai': trangThai.name,
        'anh': anh,
        'soPhut': soPhut,
        'nhanXetPhuHuynh': nhanXetPhuHuynh,
        'phuHuynhDaXem': phuHuynhDaXem,
        'taoLuc': taoLuc,
      };

  /// "2026-09-10" — dùng làm khóa lọc theo ngày.
  String get khoaNgay => '${ngay.year.toString().padLeft(4, '0')}-'
      '${ngay.month.toString().padLeft(2, '0')}-'
      '${ngay.day.toString().padLeft(2, '0')}';

  static BaoCao fromMap(String id, Map<String, Object?> m) => BaoCao(
        id: id,
        hocSinhId: '${m['hocSinhId'] ?? ''}',
        ngay: ngayTu(m['ngay']) ?? DateTime.now(),
        loai: enumTu(LoaiBaiTap.values, m['loai'], LoaiBaiTap.trenLop),
        monId: '${m['monId'] ?? ''}',
        giaoVienId: m['giaoVienId'] as String?,
        noiDung: '${m['noiDung'] ?? ''}',
        trangThai: enumTu(TrangThai.values, m['trangThai'], TrangThai.chuaLam),
        anh: chuoiTu(m['anh']),
        soPhut: (m['soPhut'] as num?)?.toInt(),
        nhanXetPhuHuynh: m['nhanXetPhuHuynh'] as String?,
        phuHuynhDaXem: m['phuHuynhDaXem'] as bool? ?? false,
        taoLuc: ngayTu(m['taoLuc']) ?? DateTime.now(),
      );
}

extension NhacNhoFs on NhacNho {
  Map<String, Object?> toMap() => {
        'tuId': tuId,
        'denId': denId,
        'noiDung': noiDung,
        'taoLuc': taoLuc,
        'hanLuc': hanLuc,
        'daDoc': daDoc,
        'baoCaoId': baoCaoId,
      };

  static NhacNho fromMap(String id, Map<String, Object?> m) => NhacNho(
        id: id,
        tuId: '${m['tuId'] ?? ''}',
        denId: '${m['denId'] ?? ''}',
        noiDung: '${m['noiDung'] ?? ''}',
        taoLuc: ngayTu(m['taoLuc']) ?? DateTime.now(),
        hanLuc: ngayTu(m['hanLuc']),
        daDoc: m['daDoc'] as bool? ?? false,
        baoCaoId: m['baoCaoId'] as String?,
      );
}

/// Mã mời sáu số để phụ huynh nối vào tài khoản con.
///
/// Học sinh sinh mã trên máy mình rồi đọc cho bố mẹ. Mã sống 15 phút và
/// chỉ dùng được một lần — đủ cho một lần ngồi cạnh nhau, và không để lại
/// một cánh cửa mở mãi vào dữ liệu của trẻ con.
class MaMoi {
  const MaMoi({
    required this.ma,
    required this.hocSinhId,
    required this.hetHan,
    this.daDung = false,
  });

  final String ma;
  final String hocSinhId;
  final DateTime hetHan;
  final bool daDung;

  bool get conHieuLuc => !daDung && hetHan.isAfter(DateTime.now());
  Duration get conLai => hetHan.difference(DateTime.now());

  Map<String, Object?> toMap() => {
        'hocSinhId': hocSinhId,
        'hetHan': hetHan,
        'daDung': daDung,
      };

  static MaMoi fromMap(String ma, Map<String, Object?> m) => MaMoi(
        ma: ma,
        hocSinhId: '${m['hocSinhId'] ?? ''}',
        hetHan: ngayTu(m['hetHan']) ?? DateTime.now(),
        daDung: m['daDung'] as bool? ?? false,
      );
}
