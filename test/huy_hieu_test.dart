import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/core/huy_hieu/huy_hieu.dart';
import 'package:theodoi_hoctap/data/models/models.dart';

import 'tro_giup.dart';

BaoCao bc(
  int lui, {
  TrangThai tt = TrangThai.xong,
  String mon = 'm_toan',
  LoaiBaiTap loai = LoaiBaiTap.trenLop,
  int gio = 20,
  List<String> anh = const [],
  int? phut,
}) {
  final ngay = DateTime(2026, 9, 12).subtract(Duration(days: lui));
  return BaoCao(
    id: 'bc_${lui}_${mon}_${tt.name}_${loai.name}',
    hocSinhId: 'hs_01',
    ngay: ngay,
    loai: loai,
    monId: mon,
    noiDung: 'x',
    trangThai: tt,
    anh: anh,
    soPhut: phut,
    taoLuc: DateTime(ngay.year, ngay.month, ngay.day, gio),
  );
}

TienDoHuyHieu cua(List<TienDoHuyHieu> ds, String id) =>
    ds.firstWhere((t) => t.huyHieu.id == id);

void main() {
  test('không có báo cáo thì mọi con dấu đều ở 0', () {
    final ds = tinhHuyHieu(const []);
    expect(ds.length, danhSachHuyHieu.length);
    expect(ds.any((t) => t.dat), isFalse);
    expect(ds.every((t) => t.hienTai == 0), isTrue);
  });

  group('Chuỗi ngày trọn vẹn', () {
    test('ba ngày liền xong hết → đạt Ba ngày liền, chưa đạt Trọn một tuần', () {
      final ds = tinhHuyHieu([bc(0), bc(1), bc(2)]);
      expect(cua(ds, 'chuoi_3').dat, isTrue);
      expect(cua(ds, 'chuoi_7').hienTai, 3);
      expect(cua(ds, 'chuoi_7').dat, isFalse);
    });

    test('một bài chưa xong làm ngày đó không trọn, đứt chuỗi', () {
      final ds = tinhHuyHieu([bc(0), bc(1), bc(1, tt: TrangThai.dangLam, mon: 'm_van'), bc(2), bc(3)]);
      // Ngày 1 hỏng → hai chuỗi: [0] và [2,3] → dài nhất là 2.
      expect(cua(ds, 'chuoi_3').hienTai, 2);
    });

    test('ngày trống làm đứt chuỗi, lấy chuỗi dài nhất từng có', () {
      final ds = tinhHuyHieu([bc(0), bc(2), bc(3), bc(4), bc(5)]);
      expect(cua(ds, 'chuoi_3').hienTai, 4);
      expect(cua(ds, 'chuoi_3').dat, isTrue);
    });

    test('bảy ngày liền → Trọn một tuần, mốc vàng còn xa', () {
      final ds = tinhHuyHieu([for (var i = 0; i < 7; i++) bc(i)]);
      expect(cua(ds, 'chuoi_7').dat, isTrue);
      expect(cua(ds, 'chuoi_30').tiLe, closeTo(7 / 30, 1e-9));
      expect(cua(ds, 'chuoi_30').nhanTienDo, '7/30 ngày');
    });
  });

  group('Số bài và thói quen', () {
    test('đếm bài xong, bài đang làm không tính', () {
      final ds = tinhHuyHieu([
        for (var i = 0; i < 10; i++) bc(i, mon: 'm_$i'),
        bc(11, tt: TrangThai.dangLam),
      ]);
      expect(cua(ds, 'xong_10').dat, isTrue);
      expect(cua(ds, 'xong_50').hienTai, 10);
      // Mười môn khác nhau → Đủ môn.
      expect(cua(ds, 'mon_8').dat, isTrue);
    });

    test('chim sớm đếm báo cáo gửi trước 19 giờ', () {
      final ds = tinhHuyHieu([
        bc(0, gio: 17), bc(1, gio: 18), bc(2, gio: 19), bc(3, gio: 21),
      ]);
      expect(cua(ds, 'som_5').hienTai, 2);
    });

    test('ảnh, học thêm, và giờ học', () {
      final ds = tinhHuyHieu([
        for (var i = 0; i < 10; i++) bc(i, anh: const ['demo:a'], loai: LoaiBaiTap.hocThem, phut: 60),
        bc(20, tt: TrangThai.dangLam, loai: LoaiBaiTap.hocThem, phut: 30),
      ]);
      expect(cua(ds, 'anh_10').dat, isTrue);
      expect(cua(ds, 'hoc_them_10').dat, isTrue); // bài đang làm không tính
      expect(cua(ds, 'gio_10').hienTai, 10); // 630 phút → 10 giờ
      expect(cua(ds, 'gio_10').dat, isTrue);
    });
  });

  group('Vừa đạt', () {
    test('so hai lần tính, chỉ nhặt cái mới đạt', () {
      final truoc = tinhHuyHieu([bc(0), bc(1)]);
      final sau = tinhHuyHieu([bc(0), bc(1), bc(2)]);
      expect(huyHieuVuaDat(truoc, sau).map((h) => h.id), ['chuoi_3']);
      expect(huyHieuVuaDat(sau, sau), isEmpty);
    });

    test('học sinh lưu báo cáo tới mốc thì AppState reo lên đúng con dấu', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      final daCo = s.huyHieu.where((t) => t.dat).map((t) => t.huyHieu.id).toSet();
      final xongHienTai = cua(s.huyHieu, 'xong_50').hienTai;

      final nhan = <String>[];
      s.huyHieuMoi.listen((h) => nhan.add(h.id));

      // Đẩy số bài xong lên đúng mốc 50 (dữ liệu mẫu đã qua mốc 10).
      expect(daCo, isNot(contains('xong_50')));
      for (var i = xongHienTai; i < 50; i++) {
        final b = s.taoBaoCaoRong(loai: LoaiBaiTap.trenLop).copyWith(
              noiDung: 'bài $i',
              trangThai: TrangThai.xong,
              ngay: DateTime(2026, 1, 1).add(Duration(days: i)),
            );
        await s.luuBaoCao(b);
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(nhan, contains('xong_50'));
      expect(nhan.where((id) => id == 'xong_50').length, 1);
    });
  });
}
