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
    this.truongId,
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

  /// Tên trường gõ tay — chỉ còn ở tài khoản đăng ký trước khi có danh mục
  /// trường. Tài khoản mới chọn trường từ danh mục, khóa bằng [truongId].
  final String? truong;
  final String? truongId;

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
    String? truongId,
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
        truongId: truongId ?? this.truongId,
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

/// Tỉnh chỉ để quản trị lọc danh sách trường và thầy cô cho gọn, không phải
/// một tầng phân quyền — quản trị nào cũng thấy hết.
class Tinh {
  const Tinh({required this.id, required this.ten});

  final String id;
  final String ten;
}

class Truong {
  const Truong({required this.id, required this.ten, this.tinhId});

  final String id;
  final String ten;
  final String? tinhId;
}

/// Một mục trong danh mục bài học theo sách giáo khoa: một bài, một tiết
/// luyện tập, một văn bản… Học sinh chọn thay vì gõ tên; phụ huynh đọc tóm
/// tắt và mấy câu hỏi để kiểm tra con.
class BaiHoc {
  const BaiHoc({
    required this.id,
    required this.monId,
    required this.lop,
    required this.thuTu,
    required this.ten,
    this.hocKi,
    this.chuong,
    this.tomTat,
    this.kiemTra = const [],
  });

  final String id;
  final String monId;

  /// Khối lớp 1–12.
  final int lop;
  final int? hocKi;

  /// Chương / chủ đề / unit chứa bài này, để nhóm trong danh sách.
  final String? chuong;

  /// Thứ tự trong sách của cùng một môn — dùng để gợi ý "bài kế tiếp".
  final int thuTu;
  final String ten;

  /// Vài câu cho phụ huynh hiểu con đang học gì. Null khi chưa có.
  final String? tomTat;

  /// Câu hỏi để bố mẹ hỏi con; phần sau " → " (nếu có) là đáp án gợi ý.
  final List<String> kiemTra;

  bool get coTomTat => (tomTat ?? '').trim().isNotEmpty;

  BaiHoc copyWith({String? ten, String? chuong, String? tomTat, List<String>? kiemTra}) =>
      BaiHoc(
        id: id,
        monId: monId,
        lop: lop,
        thuTu: thuTu,
        ten: ten ?? this.ten,
        hocKi: hocKi,
        chuong: chuong ?? this.chuong,
        tomTat: tomTat ?? this.tomTat,
        kiemTra: kiemTra ?? this.kiemTra,
      );
}

/// Tách "câu hỏi → đáp án" thành hai phần; không có mũi tên thì đáp án null.
({String hoi, String? dap}) tachCauHoi(String s) {
  final i = s.indexOf(' → ');
  if (i < 0) return (hoi: s.trim(), dap: null);
  return (hoi: s.substring(0, i).trim(), dap: s.substring(i + 3).trim());
}

/// Khối lớp từ tên lớp học sinh khai ("8A4" → 8, "12B" → 12). Null nếu tên
/// lớp không bắt đầu bằng số.
int? khoiTuLop(String? lop) {
  final m = RegExp(r'^\s*(\d{1,2})').firstMatch(lop ?? '');
  final k = m == null ? null : int.tryParse(m.group(1)!);
  return k == null || k < 1 || k > 12 ? null : k;
}

class GiaoVien {
  const GiaoVien({
    required this.id,
    required this.hoTen,
    required this.monId,
    required this.loai,
    this.noiDay,
    this.soDienThoai,
    this.truongId,
    this.tinhId,
    this.chuId,
  });

  final String id;
  final String hoTen;
  final String monId;

  /// Thầy cô trên lớp hay thầy cô dạy thêm — báo cáo học thêm bám theo từng người.
  final LoaiBaiTap loai;
  final String? noiDay;
  final String? soDienThoai;

  /// Thầy cô trên lớp thuộc trường nào. Học sinh chỉ thấy thầy cô trường mình;
  /// null là "mọi trường" — chỉ còn ở dữ liệu nhập trước khi có danh mục trường.
  final String? truongId;

  /// Thầy dạy thêm dùng chung thuộc tỉnh nào, để quản trị lọc. Null là toàn quốc.
  final String? tinhId;

  /// Thầy dạy thêm riêng của một học sinh: id em đó. Null là thầy dùng chung
  /// do quản trị nhập. Chỉ nhà em đó và quản trị thấy được hàng này.
  final String? chuId;

  bool get laRieng => chuId != null;

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
    this.baiHocId,
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

  /// Bài trong danh mục sách giáo khoa mà báo cáo này nói tới; null khi không
  /// chọn hoặc bài không có trong danh mục.
  final String? baiHocId;
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
    String? baiHocId,
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
        baiHocId: baiHocId ?? this.baiHocId,
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

/// Phần thưởng bố mẹ treo cho một chuỗi ngày trọn vẹn: "7 ngày liền → đi ăn
/// kem". App chỉ đếm; quà là thật và do nhà tự chọn — động lực bền nhất là
/// thứ đến từ bố mẹ, không phải từ máy.
///
/// Đạt hay chưa không lưu, mà tính từ báo cáo: có một chuỗi dài ≥ [moc] kể
/// từ [tuNgay]. Bố mẹ trao xong thì "treo lại" — [tuNgay] về hôm nay, chuỗi
/// đếm lại từ đầu.
class PhanThuong {
  const PhanThuong({
    required this.id,
    required this.hocSinhId,
    required this.taoBoi,
    required this.moc,
    required this.ten,
    required this.tuNgay,
    required this.taoLuc,
    this.traoLuc,
  });

  final String id;
  final String hocSinhId;

  /// Phụ huynh đã treo.
  final String taoBoi;

  /// Số ngày liền phải đạt.
  final int moc;
  final String ten;

  /// Chuỗi chỉ tính từ ngày này — treo lại là dời nó lên hôm nay.
  final DateTime tuNgay;

  /// Bố mẹ đã trao quà lúc nào; null là chưa.
  final DateTime? traoLuc;
  final DateTime taoLuc;

  bool get daTrao => traoLuc != null;

  PhanThuong copyWith({
    int? moc,
    String? ten,
    DateTime? tuNgay,
    DateTime? Function()? traoLuc,
  }) =>
      PhanThuong(
        id: id,
        hocSinhId: hocSinhId,
        taoBoi: taoBoi,
        moc: moc ?? this.moc,
        ten: ten ?? this.ten,
        tuNgay: tuNgay ?? this.tuNgay,
        traoLuc: traoLuc == null ? this.traoLuc : traoLuc(),
        taoLuc: taoLuc,
      );
}

/// Một phần thưởng kèm chỗ đứng hiện tại của con so với mốc.
class TienDoPhanThuong {
  const TienDoPhanThuong(this.phanThuong, {required this.hienTai, required this.dat});

  final PhanThuong phanThuong;

  /// Chuỗi hiện tại tính từ ngày treo.
  final int hienTai;

  /// Đã có chuỗi chạm mốc kể từ ngày treo — kể cả khi sau đó đứt.
  final bool dat;

  int get conLai => (phanThuong.moc - hienTai).clamp(0, phanThuong.moc);
  double get tiLe => dat ? 1 : (hienTai / phanThuong.moc).clamp(0, 1).toDouble();
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
// Chuyển đổi sang/từ Postgres
//
// PostgREST trả về JSON thuần: ngày giờ là chuỗi ISO, cột là snake_case.
// Phần này dịch qua lại, và cố ý dễ dãi khi đọc — dữ liệu cũ có giá trị lạ thì
// rơi về mặc định chứ không làm sập app của người chưa cập nhật.
// ---------------------------------------------------------------------------

DateTime? ngayTu(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

T enumTu<T extends Enum>(List<T> ds, Object? v, T macDinh) =>
    ds.where((e) => e.name == v).firstOrNull ?? macDinh;

List<String> chuoiTu(Object? v) =>
    v is List ? v.map((e) => '$e').toList() : const [];

int? soTu(Object? v) => switch (v) {
      num n => n.toInt(),
      String s => int.tryParse(s),
      _ => null,
    };

/// Cột `date` của Postgres nhận đúng dạng này.
String ngayIso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

extension NguoiDungPg on NguoiDung {
  /// `conIds` không nằm trong bảng nguoi_dung — nó là bảng lien_ket riêng, do
  /// repository nạp vào. Vì vậy bản ghi gửi lên không mang trường đó.
  Map<String, Object?> toMap() => {
        'id': id,
        'ho_ten': hoTen,
        'vai_tro': vaiTro.name,
        'email': email,
        'so_dien_thoai': soDienThoai,
        'lop': lop,
        'truong': truong,
        'truong_id': truongId,
        'hoat_dong': hoatDong,
      };

  /// Chỉ những cột người dùng tự sửa được. Gửi cả bản ghi lên sẽ đụng vào
  /// `vai_tro` và `hoat_dong`, và trigger chan_tu_nang_quyen sẽ chặn lại.
  Map<String, Object?> toMapCaNhan() => {
        'ho_ten': hoTen,
        'email': email,
        'so_dien_thoai': soDienThoai,
        'lop': lop,
        'truong': truong,
        'truong_id': truongId,
      };

  static NguoiDung fromMap(Map<String, Object?> m, {List<String> conIds = const []}) =>
      NguoiDung(
        id: '${m['id'] ?? ''}',
        hoTen: '${m['ho_ten'] ?? ''}',
        vaiTro: enumTu(VaiTro.values, m['vai_tro'], VaiTro.hocSinh),
        email: m['email'] as String?,
        soDienThoai: m['so_dien_thoai'] as String?,
        lop: m['lop'] as String?,
        truong: m['truong'] as String?,
        truongId: m['truong_id'] as String?,
        conIds: conIds,
        hoatDong: m['hoat_dong'] as bool? ?? true,
      );
}

extension BaiHocPg on BaiHoc {
  Map<String, Object?> toMap() => {
        'id': id,
        'mon_id': monId,
        'lop': lop,
        'hoc_ki': hocKi,
        'chuong': chuong,
        'thu_tu': thuTu,
        'ten': ten,
        'tom_tat': tomTat,
        'kiem_tra': kiemTra,
      };

  static BaiHoc fromMap(Map<String, Object?> m) => BaiHoc(
        id: '${m['id'] ?? ''}',
        monId: '${m['mon_id'] ?? ''}',
        lop: soTu(m['lop']) ?? 0,
        hocKi: soTu(m['hoc_ki']),
        chuong: m['chuong'] as String?,
        thuTu: soTu(m['thu_tu']) ?? 0,
        ten: '${m['ten'] ?? ''}',
        tomTat: m['tom_tat'] as String?,
        kiemTra: chuoiTu(m['kiem_tra']),
      );
}

extension MonHocPg on MonHoc {
  Map<String, Object?> toMap() => {'id': id, 'ten': ten, 'viet_tat': vietTat};

  static MonHoc fromMap(Map<String, Object?> m) => MonHoc(
        id: '${m['id'] ?? ''}',
        ten: '${m['ten'] ?? ''}',
        vietTat: '${m['viet_tat'] ?? m['ten'] ?? ''}',
      );
}

extension TinhPg on Tinh {
  Map<String, Object?> toMap() => {'id': id, 'ten': ten};

  static Tinh fromMap(Map<String, Object?> m) =>
      Tinh(id: '${m['id'] ?? ''}', ten: '${m['ten'] ?? ''}');
}

extension TruongPg on Truong {
  Map<String, Object?> toMap() => {'id': id, 'ten': ten, 'tinh_id': tinhId};

  static Truong fromMap(Map<String, Object?> m) => Truong(
        id: '${m['id'] ?? ''}',
        ten: '${m['ten'] ?? ''}',
        tinhId: m['tinh_id'] as String?,
      );
}

extension GiaoVienPg on GiaoVien {
  Map<String, Object?> toMap() => {
        'id': id,
        'ho_ten': hoTen,
        'mon_id': monId,
        'loai': loai.name,
        'noi_day': noiDay,
        'so_dien_thoai': soDienThoai,
        'truong_id': truongId,
        'tinh_id': tinhId,
        'chu_id': chuId,
      };

  static GiaoVien fromMap(Map<String, Object?> m) => GiaoVien(
        id: '${m['id'] ?? ''}',
        hoTen: '${m['ho_ten'] ?? ''}',
        monId: '${m['mon_id'] ?? ''}',
        loai: enumTu(LoaiBaiTap.values, m['loai'], LoaiBaiTap.trenLop),
        noiDay: m['noi_day'] as String?,
        soDienThoai: m['so_dien_thoai'] as String?,
        truongId: m['truong_id'] as String?,
        tinhId: m['tinh_id'] as String?,
        chuId: m['chu_id'] as String?,
      );
}

extension TietHocPg on TietHoc {
  Map<String, Object?> toMap() => {
        'id': id,
        'hoc_sinh_id': hocSinhId,
        'thu': thu,
        'tiet': tiet,
        'buoi': buoi.name,
        'mon_id': monId,
        'loai': loai.name,
        'giao_vien_id': giaoVienId,
        'phong': phong,
        'bat_dau': batDau,
        'ket_thuc': ketThuc,
      };

  static TietHoc fromMap(Map<String, Object?> m) => TietHoc(
        id: '${m['id'] ?? ''}',
        hocSinhId: '${m['hoc_sinh_id'] ?? ''}',
        thu: soTu(m['thu']) ?? 2,
        tiet: soTu(m['tiet']) ?? 1,
        buoi: enumTu(Buoi.values, m['buoi'], Buoi.sang),
        monId: '${m['mon_id'] ?? ''}',
        loai: enumTu(LoaiBaiTap.values, m['loai'], LoaiBaiTap.trenLop),
        giaoVienId: m['giao_vien_id'] as String?,
        phong: m['phong'] as String?,
        batDau: m['bat_dau'] as String?,
        ketThuc: m['ket_thuc'] as String?,
      );
}

extension BaoCaoPg on BaoCao {
  Map<String, Object?> toMap() => {
        'id': id,
        'hoc_sinh_id': hocSinhId,
        'ngay': ngayIso(ngay),
        'loai': loai.name,
        'mon_id': monId,
        'giao_vien_id': giaoVienId,
        'bai_hoc_id': baiHocId,
        'noi_dung': noiDung,
        'trang_thai': trangThai.name,
        'anh': anh,
        'so_phut': soPhut,
        'nhan_xet_phu_huynh': nhanXetPhuHuynh,
        'phu_huynh_da_xem': phuHuynhDaXem,
      };

  /// Phần duy nhất phụ huynh được phép ghi. Gửi cả bản ghi lên sẽ đụng vào
  /// nội dung của học sinh và trigger chan_phu_huynh_sua_bao_cao chặn lại.
  Map<String, Object?> toMapNhanXet() => {
        'nhan_xet_phu_huynh': nhanXetPhuHuynh,
        'phu_huynh_da_xem': phuHuynhDaXem,
      };

  static BaoCao fromMap(Map<String, Object?> m) => BaoCao(
        id: '${m['id'] ?? ''}',
        hocSinhId: '${m['hoc_sinh_id'] ?? ''}',
        ngay: ngayTu(m['ngay']) ?? DateTime.now(),
        loai: enumTu(LoaiBaiTap.values, m['loai'], LoaiBaiTap.trenLop),
        monId: '${m['mon_id'] ?? ''}',
        giaoVienId: m['giao_vien_id'] as String?,
        baiHocId: m['bai_hoc_id'] as String?,
        noiDung: '${m['noi_dung'] ?? ''}',
        trangThai: enumTu(TrangThai.values, m['trang_thai'], TrangThai.chuaLam),
        anh: chuoiTu(m['anh']),
        soPhut: soTu(m['so_phut']),
        nhanXetPhuHuynh: m['nhan_xet_phu_huynh'] as String?,
        phuHuynhDaXem: m['phu_huynh_da_xem'] as bool? ?? false,
        taoLuc: ngayTu(m['tao_luc']) ?? DateTime.now(),
      );
}

extension NhacNhoPg on NhacNho {
  Map<String, Object?> toMap() => {
        'id': id,
        'tu_id': tuId,
        'den_id': denId,
        'noi_dung': noiDung,
        'han_luc': hanLuc?.toIso8601String(),
        'da_doc': daDoc,
        'bao_cao_id': baoCaoId,
      };

  static NhacNho fromMap(Map<String, Object?> m) => NhacNho(
        id: '${m['id'] ?? ''}',
        tuId: '${m['tu_id'] ?? ''}',
        denId: '${m['den_id'] ?? ''}',
        noiDung: '${m['noi_dung'] ?? ''}',
        taoLuc: ngayTu(m['tao_luc']) ?? DateTime.now(),
        hanLuc: ngayTu(m['han_luc']),
        daDoc: m['da_doc'] as bool? ?? false,
        baoCaoId: m['bao_cao_id'] as String?,
      );
}

extension PhanThuongPg on PhanThuong {
  Map<String, Object?> toMap() => {
        'id': id,
        'hoc_sinh_id': hocSinhId,
        'tao_boi': taoBoi,
        'moc': moc,
        'ten': ten,
        'tu_ngay': ngayIso(tuNgay),
        'trao_luc': traoLuc?.toIso8601String(),
      };

  static PhanThuong fromMap(Map<String, Object?> m) => PhanThuong(
        id: '${m['id'] ?? ''}',
        hocSinhId: '${m['hoc_sinh_id'] ?? ''}',
        taoBoi: '${m['tao_boi'] ?? ''}',
        moc: soTu(m['moc']) ?? 7,
        ten: '${m['ten'] ?? ''}',
        tuNgay: ngayTu(m['tu_ngay']) ?? DateTime.now(),
        traoLuc: ngayTu(m['trao_luc']),
        taoLuc: ngayTu(m['tao_luc']) ?? DateTime.now(),
      );
}

/// Mã mời sáu số để phụ huynh nối vào tài khoản con.
///
/// Học sinh sinh mã trên máy mình rồi đọc cho bố mẹ. Mã sống 15 phút và chỉ
/// dùng được một lần — đủ cho một lần ngồi cạnh nhau, và không để lại một
/// cánh cửa mở mãi vào dữ liệu của trẻ con.
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

  static MaMoi fromMap(Map<String, Object?> m) => MaMoi(
        ma: '${m['ma'] ?? ''}',
        hocSinhId: '${m['hoc_sinh_id'] ?? ''}',
        hetHan: ngayTu(m['het_han']) ?? DateTime.now(),
        daDung: m['da_dung'] as bool? ?? false,
      );
}
