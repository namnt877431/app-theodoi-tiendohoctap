import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/core/utils/ngay.dart';
import 'package:theodoi_hoctap/data/models/models.dart';

import 'tro_giup.dart';

void main() {
  group('Báo cáo', () {
    test('tổng kết ngày đếm đúng theo trạng thái', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      final homNay = Ngay.dauNgay(DateTime.now());
      final ds = s.baoCaoNgay(homNay);
      final tk = s.tongKet(homNay);

      expect(tk.tong, ds.length);
      expect(tk.xong, ds.where((b) => b.trangThai == TrangThai.xong).length);
      expect(tk.soPhut, ds.fold<int>(0, (t, b) => t + (b.soPhut ?? 0)));
    });

    test('lưu báo cáo mới thì danh sách dài thêm một mục', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      final truoc = s.baoCao.length;
      final mau = s.taoBaoCaoRong(loai: LoaiBaiTap.trenLop);

      await s.luuBaoCao(BaoCao(
        id: mau.id,
        hocSinhId: mau.hocSinhId,
        ngay: DateTime.now(),
        loai: LoaiBaiTap.trenLop,
        monId: 'm_toan',
        noiDung: 'Làm bài 5 trang 30',
        trangThai: TrangThai.xong,
        taoLuc: DateTime.now(),
      ));

      expect(s.baoCao.length, truoc + 1);
      expect(s.baoCao.any((b) => b.noiDung == 'Làm bài 5 trang 30'), isTrue);
    });

    test('xóa báo cáo thì nó biến mất khỏi danh sách', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      final id = s.baoCao.first.id;
      await s.xoaBaoCao(id);

      expect(s.baoCao.any((b) => b.id == id), isFalse);
    });
  });

  group('Thời khóa biểu', () {
    test('thêm rồi xóa tiết học không để lại dấu vết trong lưới', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      expect(s.tkbTai(4, 3, Buoi.chieu), isNull);

      await s.luuTiet(
        TietHoc(
          id: 'tam',
          hocSinhId: s.hocSinhHienTai!.id,
          thu: 4,
          tiet: 3,
          buoi: Buoi.chieu,
          monId: 'm_tin',
          loai: LoaiBaiTap.trenLop,
        ),
        moi: true,
      );

      final them = s.tkbTai(4, 3, Buoi.chieu);
      expect(them, isNotNull);
      expect(them!.monId, 'm_tin');

      await s.xoaTiet(them.id);
      expect(s.tkbTai(4, 3, Buoi.chieu), isNull);
    });
  });

  group('Nhắc nhở', () {
    test('phụ huynh gửi thì học sinh nhận được và đếm là chưa đọc', () async {
      final s = await vaoVoiVaiTro(VaiTro.phuHuynh);
      final truoc = s.soNhacNhoChuaDoc;

      await s.guiNhacNho('Làm nốt bài Toán nhé');
      expect(s.soNhacNhoChuaDoc, truoc + 1);

      final moi = s.nhacNho.firstWhere((n) => n.noiDung == 'Làm nốt bài Toán nhé');
      expect(moi.denId, 'hs_01');

      await s.docNhacNho(moi.id);
      expect(s.soNhacNhoChuaDoc, truoc);
    });
  });
}
