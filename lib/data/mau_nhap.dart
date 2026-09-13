import 'diem_danh.dart';
import 'models/models.dart';

/// Câu mẫu để chạm là điền vào báo cáo, cho những ngày bài vở chẳng có gì
/// đáng kể hơn "làm bài tập trong sách" — gõ lại câu đó mỗi tối là thứ làm
/// con bỏ app.
///
/// Ba nguồn, theo thứ tự ưu tiên:
/// 1. Câu của chính con — những dòng con hay ghi, học từ báo cáo cũ. Không
///    lưu gì thêm: xóa báo cáo là mẫu cũng đi theo.
/// 2. Bộ riêng của môn (Văn thì "Soạn bài", Anh thì "Học từ vựng"…).
/// 3. Bộ chung.
List<String> mauNhap(List<BaoCao> baoCao, {required String monId, int toiDa = 8}) {
  final ds = <String>[];
  final daCo = <String>{};
  void them(String cau) {
    final khoa = _khoa(cau);
    if (khoa.isEmpty || !daCo.add(khoa)) return;
    ds.add(cau);
  }

  mauNhapCuaCon(baoCao, monId: monId).forEach(them);
  (_mauTheoMon[monId] ?? const []).forEach(them);
  mauNhapChung.where((c) => c != noiDungKhongCoBai).forEach(them);
  // "Không có bài tập" luôn có mặt, ở cuối — nó là câu trả lời cho một
  // trường hợp riêng, không phải câu mẫu để cạnh tranh chỗ.
  return [...ds.take(toiDa - 1), noiDungKhongCoBai];
}

/// Câu con tự ghi mà lặp lại: mỗi dòng trong nội dung báo cáo là một ứng
/// viên (dòng ngắn thôi — câu dài là chuyện riêng của hôm đó, không phải
/// mẫu). Lấy dòng ghi từ hai lần trở lên; ghi cho cùng môn thì xếp trước,
/// rồi tới dòng nào hay dùng hơn, mới hơn.
List<String> mauNhapCuaCon(List<BaoCao> baoCao, {required String monId, int toiDa = 4}) {
  final dem = <String, _DongMau>{};
  for (final b in baoCao) {
    for (final dong in b.noiDung.split('\n')) {
      final cau = _gon(dong);
      if (cau.length < 3 || cau.length > 60) continue;
      final m = dem.putIfAbsent(_khoa(cau), () => _DongMau(cau));
      m.soLan++;
      if (b.monId == monId) m.cungMon++;
      if (b.ngay.isAfter(m.ganNhat)) {
        m.ganNhat = b.ngay;
        m.cau = cau;
      }
    }
  }
  final ds = dem.values.where((m) => m.soLan >= 2).toList()
    ..sort((a, b) {
      final c = b.cungMon.compareTo(a.cungMon);
      if (c != 0) return c;
      final d = b.soLan.compareTo(a.soLan);
      return d != 0 ? d : b.ganNhat.compareTo(a.ganNhat);
    });
  return ds.take(toiDa).map((m) => m.cau).toList();
}

class _DongMau {
  _DongMau(this.cau);
  String cau;
  int soLan = 0;
  int cungMon = 0;
  DateTime ganNhat = DateTime(2000);
}

/// Bỏ khoảng trắng thừa và dấu chấm, dấu phẩy cuối câu — "Học thuộc bài." và
/// "Học thuộc bài" là một.
String _gon(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'[.,;:!…]+$'), '');

String _khoa(String s) => _gon(s).toLowerCase();

const mauNhapChung = [
  'Làm bài tập trong SGK',
  'Học thuộc bài',
  'Chép bài, ghi vở',
  'Ôn bài kiểm tra',
  noiDungKhongCoBai,
];

/// Mã môn theo danh mục mẫu (`05_danh_muc.sql`). Môn quản trị tự thêm với
/// mã khác thì chỉ có bộ chung.
const _mauTheoMon = <String, List<String>>{
  'm_toan': ['Làm bài tập trong SGK', 'Làm bài trong sách bài tập', 'Làm phiếu bài tập'],
  'm_van': ['Soạn bài', 'Học thuộc thơ', 'Viết đoạn văn', 'Đọc trước văn bản'],
  'm_anh': ['Học từ vựng', 'Làm Workbook', 'Luyện nghe, nói', 'Học ngữ pháp'],
  'm_ly': ['Làm bài tập trong SGK', 'Học thuộc công thức', 'Làm phiếu bài tập'],
  'm_hoa': ['Làm bài tập trong SGK', 'Học thuộc công thức', 'Làm phiếu bài tập'],
  'm_sinh': ['Học thuộc bài', 'Trả lời câu hỏi cuối bài', 'Vẽ sơ đồ tư duy'],
  'm_su': ['Học thuộc bài', 'Trả lời câu hỏi cuối bài', 'Vẽ sơ đồ tư duy'],
  'm_dia': ['Học thuộc bài', 'Trả lời câu hỏi cuối bài', 'Vẽ sơ đồ tư duy'],
  'm_gdcd': ['Học thuộc bài', 'Trả lời câu hỏi cuối bài'],
  'm_tin': ['Thực hành trên máy', 'Học thuộc bài'],
  'm_cn': ['Học thuộc bài', 'Làm sản phẩm thực hành'],
  'm_td': ['Tập luyện ở nhà'],
};
