import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/core/utils/ngay.dart';

void main() {
  group('Ngay', () {
    test('nhãn ngày dùng từ quen thuộc cho hôm nay và hôm qua', () {
      final n = DateTime.now();
      expect(Ngay.nhan(n), 'Hôm nay');
      expect(Ngay.nhan(n.subtract(const Duration(days: 1))), 'Hôm qua');
      expect(Ngay.nhan(n.add(const Duration(days: 1))), 'Ngày mai');
    });

    test('cột thời khóa biểu quy Chủ nhật về 8', () {
      expect(Ngay.cotTuNgay(DateTime(2026, 9, 7)), 2); // Thứ Hai
      expect(Ngay.cotTuNgay(DateTime(2026, 9, 13)), 8); // Chủ nhật
      expect(Ngay.thuTuCot(8), 'Chủ nhật');
      expect(Ngay.thuNganTuCot(2), 'T2');
    });

    test('số phút đọc thành giờ khi vượt 60', () {
      expect(Ngay.phut(0), '—');
      expect(Ngay.phut(45), '45 phút');
      expect(Ngay.phut(60), '1 giờ');
      expect(Ngay.phut(95), '1 giờ 35 phút');
    });
  });
}
