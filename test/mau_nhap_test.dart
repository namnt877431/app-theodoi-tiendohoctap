import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/data/mau_nhap.dart';
import 'package:theodoi_hoctap/data/models/models.dart';

BaoCao _bc(String mon, String noiDung, {int lui = 0}) => BaoCao(
      id: '$mon-$noiDung-$lui',
      hocSinhId: 'hs',
      ngay: DateTime(2026, 9, 10).subtract(Duration(days: lui)),
      loai: LoaiBaiTap.trenLop,
      monId: mon,
      noiDung: noiDung,
      trangThai: TrangThai.xong,
      taoLuc: DateTime(2026, 9, 10, 20),
    );

void main() {
  group('Mẫu nhập của con', () {
    test('dòng ghi từ hai lần trở lên mới thành mẫu; dấu chấm cuối và hoa thường không tính khác',
        () {
      final ds = mauNhapCuaCon([
        _bc('m_toan', 'Làm bài tập về nhà.'),
        _bc('m_toan', 'làm bài tập về nhà', lui: 1),
        _bc('m_toan', 'Bài 8, 9, 10 trang 41', lui: 2),
      ], monId: 'm_toan');

      // Bản mới nhất là bản không có dấu chấm, chữ thường — giữ nguyên chữ
      // con gõ lần gần nhất.
      expect(ds, ['Làm bài tập về nhà']);
    });

    test('mỗi dòng trong nội dung là một ứng viên; dòng quá dài hay quá ngắn bỏ qua', () {
      final ds = mauNhapCuaCon([
        _bc('m_van', 'Soạn bài\nHọc thuộc thơ'),
        _bc('m_van', 'Soạn bài\nHọc thuộc thơ', lui: 1),
        _bc('m_van', 'ok'),
        _bc('m_van', 'ok', lui: 1),
        _bc('m_van', 'Viết đoạn văn 200 chữ nêu cảm nhận về nhân vật Vũ Nương trong truyện'),
        _bc('m_van', 'Viết đoạn văn 200 chữ nêu cảm nhận về nhân vật Vũ Nương trong truyện', lui: 1),
      ], monId: 'm_van');

      expect(ds, ['Soạn bài', 'Học thuộc thơ']);
    });

    test('cùng môn xếp trước, rồi tới hay dùng hơn, rồi mới hơn', () {
      final ds = mauNhapCuaCon([
        _bc('m_anh', 'Học từ vựng'),
        _bc('m_anh', 'Học từ vựng', lui: 3),
        _bc('m_toan', 'Làm phiếu bài tập'),
        _bc('m_toan', 'Làm phiếu bài tập', lui: 1),
        _bc('m_toan', 'Làm phiếu bài tập', lui: 2),
        _bc('m_ly', 'Học thuộc công thức'),
        _bc('m_hoa', 'Học thuộc công thức', lui: 1),
        _bc('m_hoa', 'Học thuộc công thức', lui: 2),
      ], monId: 'm_anh');

      expect(ds, ['Học từ vựng', 'Làm phiếu bài tập', 'Học thuộc công thức']);
    });

    test('chưa có gì lặp thì trống', () {
      expect(mauNhapCuaCon([_bc('m_toan', 'Làm bài 5')], monId: 'm_toan'), isEmpty);
    });
  });

  group('Bộ câu mẫu đưa ra biểu mẫu', () {
    test('câu của con đứng trước, rồi bộ riêng của môn, rồi bộ chung; không trùng', () {
      final ds = mauNhap([
        _bc('m_van', 'Đọc thêm sách tham khảo'),
        _bc('m_van', 'Đọc thêm sách tham khảo', lui: 1),
        _bc('m_van', 'soạn bài'),
        _bc('m_van', 'Soạn bài.', lui: 1),
      ], monId: 'm_van');

      expect(ds.take(3), ['Đọc thêm sách tham khảo', 'soạn bài', 'Học thuộc thơ']);
      expect(ds.where((c) => c.toLowerCase() == 'soạn bài').length, 1);
      expect(ds, contains('Không có bài tập'));
      expect(ds.length, lessThanOrEqualTo(8));
    });

    test('môn không có bộ riêng thì chỉ có bộ chung', () {
      expect(mauNhap(const [], monId: 'm_la'), mauNhapChung);
    });
  });
}
