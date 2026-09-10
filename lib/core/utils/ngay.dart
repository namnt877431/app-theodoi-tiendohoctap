/// Định dạng ngày tháng theo cách người Việt đọc: "Thứ Năm, 10/09".
abstract final class Ngay {
  static const _thu = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ nhật',
  ];

  static const _thuNgan = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  /// DateTime.weekday: 1 = Thứ Hai … 7 = Chủ nhật.
  static String thu(DateTime d) => _thu[d.weekday - 1];
  static String thuNgan(DateTime d) => _thuNgan[d.weekday - 1];

  /// Quy ước trong app: cột thời khóa biểu đánh số 2..8 (8 là Chủ nhật).
  static String thuTuCot(int cot) => _thu[cot - 2];
  static String thuNganTuCot(int cot) => _thuNgan[cot - 2];
  static int cotTuNgay(DateTime d) => d.weekday == 7 ? 8 : d.weekday + 1;

  static String ddMM(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  static String ddMMyyyy(DateTime d) => '${ddMM(d)}/${d.year}';

  static String gio(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String dayDu(DateTime d) => '${thu(d)}, ${ddMM(d)}';

  static bool cungNgay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool laHomNay(DateTime d) => cungNgay(d, DateTime.now());

  /// "Hôm nay", "Hôm qua", hoặc "Thứ Năm, 10/09".
  static String nhan(DateTime d) {
    final n = DateTime.now();
    if (cungNgay(d, n)) return 'Hôm nay';
    if (cungNgay(d, n.subtract(const Duration(days: 1)))) return 'Hôm qua';
    if (cungNgay(d, n.add(const Duration(days: 1)))) return 'Ngày mai';
    return dayDu(d);
  }

  /// "2 giờ trước", "vừa xong".
  static String truoc(DateTime d) {
    final p = DateTime.now().difference(d);
    if (p.inMinutes < 1) return 'vừa xong';
    if (p.inMinutes < 60) return '${p.inMinutes} phút trước';
    if (p.inHours < 24) return '${p.inHours} giờ trước';
    if (p.inDays == 1) return 'hôm qua';
    if (p.inDays < 7) return '${p.inDays} ngày trước';
    return ddMM(d);
  }

  /// 95 phút -> "1 giờ 35 phút".
  static String phut(int p) {
    if (p <= 0) return '—';
    if (p < 60) return '$p phút';
    final gio = p ~/ 60;
    final du = p % 60;
    return du == 0 ? '$gio giờ' : '$gio giờ $du phút';
  }

  static DateTime dauNgay(DateTime d) => DateTime(d.year, d.month, d.day);
}
