import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/data/models/models.dart';
import 'package:theodoi_hoctap/data/repositories/mock_repository.dart';

void main() {
  group('Mã mời', () {
    test('mã gồm sáu chữ số và còn hiệu lực ngay sau khi tạo', () async {
      final repo = MockRepository();
      final ma = await repo.taoMaMoi('hs_03');

      expect(ma.ma.length, 6);
      expect(int.tryParse(ma.ma), isNotNull);
      expect(ma.conHieuLuc, isTrue);
      expect(ma.hetHan.isAfter(DateTime.now()), isTrue);
    });

    test('phụ huynh nhập mã đúng thì nối được vào tài khoản con', () async {
      final repo = MockRepository();
      final ma = await repo.taoMaMoi('hs_03');
      final hs = await repo.dungMaMoi(ma.ma, 'ph_01');

      expect(hs.id, 'hs_03');
      final con = await repo.danhSachCon('ph_01');
      expect(con.map((c) => c.id), contains('hs_03'));
    });

    test('mã chỉ dùng được một lần', () async {
      final repo = MockRepository();
      final ma = await repo.taoMaMoi('hs_03');
      await repo.dungMaMoi(ma.ma, 'ph_01');

      await expectLater(
        repo.dungMaMoi(ma.ma, 'ph_02'),
        throwsA(predicate((e) => '$e'.contains('đã được dùng'))),
      );
    });

    test('tạo mã mới thì mã cũ của cùng học sinh hết tác dụng', () async {
      final repo = MockRepository();
      final cu = await repo.taoMaMoi('hs_03');
      await repo.taoMaMoi('hs_03');

      await expectLater(
        repo.dungMaMoi(cu.ma, 'ph_01'),
        throwsA(predicate((e) => '$e'.contains('không đúng'))),
      );
    });

    test('mã sai định dạng hoặc không tồn tại đều bị chặn', () async {
      final repo = MockRepository();

      await expectLater(
        repo.dungMaMoi('123', 'ph_01'),
        throwsA(predicate((e) => '$e'.contains('6 chữ số'))),
      );
      await expectLater(
        repo.dungMaMoi('999999', 'ph_01'),
        throwsA(predicate((e) => '$e'.contains('không đúng'))),
      );
    });

    test('mã hết hạn thì không dùng được', () {
      final het = MaMoi(
        ma: '111111',
        hocSinhId: 'hs_01',
        hetHan: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(het.conHieuLuc, isFalse);
    });
  });
}
