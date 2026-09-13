import '../../data/models/models.dart';

/// Luật đếm chuỗi ngày trọn vẹn.
///
/// Một ngày "trọn vẹn" là ngày có ít nhất một báo cáo và mọi báo cáo đều
/// xong. Chuỗi là số ngày trọn vẹn liên tiếp. Hai ngoại lệ để chuỗi không
/// đứt oan:
///
/// - [thuNghi]: thứ không có tiết học (theo thời khóa biểu — Chủ nhật, có
///   khi cả thứ Bảy). Không có báo cáo cũng không đứt, mà cũng không tính.
/// - [veMoiTuan]: mỗi tuần được bỏ trống chừng này ngày học mà chuỗi vẫn
///   giữ — "vé nghỉ", app tự dùng khi cần. Một chuỗi hai mươi ngày đứt vì đi
///   chơi một hôm là thứ giết động lực nhanh nhất.
///
/// Mặc định không có ngoại lệ nào — đó là luật thuần để test.
class LuatChuoi {
  const LuatChuoi({this.thuNghi = const {}, this.veMoiTuan = 0});

  /// Theo `DateTime.weekday`: 1 là Thứ Hai … 7 là Chủ nhật.
  final Set<int> thuNghi;
  final int veMoiTuan;
}

class KetQuaChuoi {
  const KetQuaChuoi({
    required this.hienTai,
    required this.daiNhat,
    required this.veDaDungTuanNay,
    required this.veConLaiTuanNay,
    this.cacChuoi = const [],
    this.ngayDungVeGanNhat,
  });

  static const khong = KetQuaChuoi(
    hienTai: 0,
    daiNhat: 0,
    veDaDungTuanNay: 0,
    veConLaiTuanNay: 0,
  );

  /// Độ dài từng chuỗi đã có trong khoảng đếm, theo thứ tự thời gian; chuỗi
  /// đang chạy (nếu có) là phần tử cuối. Phần thưởng lặp lại đếm trên đây.
  final List<int> cacChuoi;

  /// Chuỗi tính tới hôm nay. Hôm nay chưa báo cáo thì chưa đứt — ngày còn
  /// chưa hết.
  final int hienTai;

  /// Chuỗi dài nhất từng có trong khoảng đã đếm.
  final int daiNhat;
  final int veDaDungTuanNay;
  final int veConLaiTuanNay;
  final DateTime? ngayDungVeGanNhat;
}

/// Đếm chuỗi từ ngày đầu tiên có báo cáo (hoặc [tuNgay] nếu muộn hơn) tới
/// [homNay]. Báo cáo ghi ngày tương lai bỏ qua.
KetQuaChuoi demChuoi(
  List<BaoCao> ds, {
  LuatChuoi luat = const LuatChuoi(),
  DateTime? tuNgay,
  DateTime? homNay,
}) {
  final nay = _ngay(homNay ?? DateTime.now());
  final tuan = _tuanCua(nay);

  // Trạng thái từng ngày: true là trọn vẹn, false là có bài chưa xong.
  final theoNgay = <DateTime, bool>{};
  for (final b in ds) {
    final n = _ngay(b.ngay);
    if (n.isAfter(nay)) continue;
    if (tuNgay != null && n.isBefore(_ngay(tuNgay))) continue;
    theoNgay[n] = (theoNgay[n] ?? true) && b.trangThai == TrangThai.xong;
  }
  if (theoNgay.isEmpty) {
    return KetQuaChuoi(
      hienTai: 0,
      daiNhat: 0,
      veDaDungTuanNay: 0,
      veConLaiTuanNay: luat.veMoiTuan,
    );
  }

  var dau = theoNgay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  if (tuNgay != null && _ngay(tuNgay).isAfter(dau)) dau = _ngay(tuNgay);

  final veDaDung = <DateTime, int>{};
  final cacChuoi = <int>[];
  DateTime? veGanNhat;
  var hienTai = 0;
  var daiNhat = 0;
  void dut() {
    if (hienTai > 0) cacChuoi.add(hienTai);
    hienTai = 0;
  }

  for (var d = dau; !d.isAfter(nay); d = d.add(const Duration(days: 1))) {
    final tron = theoNgay[d];
    if (tron == true) {
      hienTai++;
      if (hienTai > daiNhat) daiNhat = hienTai;
      continue;
    }
    if (tron == false) {
      dut();
      continue;
    }
    // Ngày trống.
    if (d == nay) break; // hôm nay chưa xong ngày, chưa kết luận
    if (luat.thuNghi.contains(d.weekday)) continue;
    // Chỉ xé vé khi đang có chuỗi để giữ — chuỗi 0 thì giữ làm gì.
    final t = _tuanCua(d);
    if (hienTai > 0 && (veDaDung[t] ?? 0) < luat.veMoiTuan) {
      veDaDung[t] = (veDaDung[t] ?? 0) + 1;
      veGanNhat = d;
      continue;
    }
    dut();
  }
  if (hienTai > 0) cacChuoi.add(hienTai);

  final dungTuanNay = veDaDung[tuan] ?? 0;
  return KetQuaChuoi(
    hienTai: hienTai,
    daiNhat: daiNhat,
    veDaDungTuanNay: dungTuanNay,
    veConLaiTuanNay: (luat.veMoiTuan - dungTuanNay).clamp(0, luat.veMoiTuan),
    cacChuoi: cacChuoi,
    ngayDungVeGanNhat: veGanNhat,
  );
}

DateTime _ngay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Thứ Hai của tuần chứa [d] — khóa để đếm vé theo tuần.
DateTime _tuanCua(DateTime d) => _ngay(d).subtract(Duration(days: d.weekday - 1));
