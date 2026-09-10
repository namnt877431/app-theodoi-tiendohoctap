import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/data/models/models.dart';
import 'package:theodoi_hoctap/data/repositories/mock_repository.dart';

import 'tro_giup.dart';

void main() {
  group('Phiên đăng nhập', () {
    test('phụ huynh vào thì nạp danh mục, danh sách con và chọn sẵn đứa đầu', () async {
      final s = await vaoVoiVaiTro(VaiTro.phuHuynh);

      expect(s.nguoiDung?.vaiTro, VaiTro.phuHuynh);
      expect(s.dsCon.length, 2);
      expect(s.hocSinhHienTai?.id, 'hs_01');
      expect(s.monHoc, isNotEmpty);
      expect(s.giaoVien, isNotEmpty);
      expect(s.tkb, isNotEmpty);
      expect(s.baoCao, isNotEmpty);
    });

    test('học sinh vào thì học sinh hiện tại chính là mình', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      expect(s.hocSinhHienTai?.id, s.nguoiDung?.id);
    });

    test('đăng xuất thì xóa sạch dữ liệu trong bộ nhớ', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      await s.dangXuat();
      await cho(() => s.nguoiDung == null, moTa: 'trạng thái đăng xuất');

      expect(s.baoCao, isEmpty);
      expect(s.tkb, isEmpty);
      expect(s.nhacNho, isEmpty);
      expect(s.dungThu, isFalse);
    });

    test('sai mật khẩu hay email lạ đều báo lỗi đọc được', () async {
      final repo = MockRepository();

      await expectLater(
        repo.dangNhap('khong-ton-tai@email.com', 'matkhau123'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        repo.dangNhap('hung.nguyen@gmail.com', '123'),
        throwsA(predicate((e) => '$e'.contains('6 ký tự'))),
      );
    });

    test('tài khoản bị khóa thì không vào được, và nói rõ vì sao', () async {
      final repo = MockRepository();
      // hs_04 trong dữ liệu mẫu có hoatDong = false.
      await expectLater(
        repo.dangNhap('linh.pham@hocsinh.vn', 'matkhau123'),
        throwsA(predicate((e) => '$e'.contains('bị khóa'))),
      );
    });

    test('đăng ký tài khoản mới thì vào thẳng luôn', () async {
      final repo = MockRepository();
      final nd = await repo.dangKy(
        hoTen: 'Trần Thu Hà',
        email: 'ha.tran@gmail.com',
        matKhau: 'matkhau123',
        vaiTro: VaiTro.phuHuynh,
        soDienThoai: '0900 111 222',
      );

      expect(nd.vaiTro, VaiTro.phuHuynh);
      expect(nd.conIds, isEmpty);
      await expectLater(
        repo.dangKy(
          hoTen: 'Người khác',
          email: 'ha.tran@gmail.com',
          matKhau: 'matkhau123',
          vaiTro: VaiTro.phuHuynh,
        ),
        throwsA(predicate((e) => '$e'.contains('đã có tài khoản'))),
      );
    });
  });
}
