import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:theodoi_hoctap/core/utils/ngay.dart';
import 'package:theodoi_hoctap/data/app_state.dart';
import 'package:theodoi_hoctap/data/models/models.dart';
import 'package:theodoi_hoctap/data/repositories/mock_repository.dart';

void main() {
  group('AppState', () {
    test('phụ huynh đăng nhập thì nạp được danh sách con và chọn sẵn đứa đầu', () async {
      final s = AppState(MockRepository());
      await s.dangNhap(VaiTro.phuHuynh);

      expect(s.nguoiDung?.vaiTro, VaiTro.phuHuynh);
      expect(s.dsCon.length, 2);
      expect(s.hocSinhHienTai?.id, 'hs_01');
      expect(s.tkb, isNotEmpty);
      expect(s.baoCao, isNotEmpty);
    });

    test('học sinh đăng nhập thì học sinh hiện tại chính là mình', () async {
      final s = AppState(MockRepository());
      await s.dangNhap(VaiTro.hocSinh);

      expect(s.hocSinhHienTai?.id, s.nguoiDung?.id);
    });

    test('tổng kết ngày đếm đúng theo trạng thái', () async {
      final s = AppState(MockRepository());
      await s.dangNhap(VaiTro.hocSinh);

      final homNay = Ngay.dauNgay(DateTime.now());
      final ds = s.baoCaoNgay(homNay);
      final tk = s.tongKet(homNay);

      expect(tk.tong, ds.length);
      expect(tk.xong, ds.where((b) => b.trangThai == TrangThai.xong).length);
      expect(tk.soPhut, ds.fold<int>(0, (t, b) => t + (b.soPhut ?? 0)));
    });

    test('lưu báo cáo mới thì danh sách dài thêm một mục', () async {
      final s = AppState(MockRepository());
      await s.dangNhap(VaiTro.hocSinh);
      final truoc = s.baoCao.length;

      final bc = s.taoBaoCaoRong(loai: LoaiBaiTap.trenLop);
      await s.luuBaoCao(BaoCao(
        id: bc.id,
        hocSinhId: bc.hocSinhId,
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

    test('gửi nhắc nhở thì học sinh nhận được và đếm là chưa đọc', () async {
      final s = AppState(MockRepository());
      await s.dangNhap(VaiTro.phuHuynh);
      final truoc = s.soNhacNhoChuaDoc;

      await s.guiNhacNho('Làm nốt bài Toán nhé');

      expect(s.soNhacNhoChuaDoc, truoc + 1);
      final moi = s.nhacNho.firstWhere((n) => n.noiDung == 'Làm nốt bài Toán nhé');
      expect(moi.denId, 'hs_01');

      await s.docNhacNho(moi.id);
      expect(s.soNhacNhoChuaDoc, truoc);
    });

    test('thêm rồi xóa tiết học không để lại dấu vết trong lưới', () async {
      final s = AppState(MockRepository());
      await s.dangNhap(VaiTro.hocSinh);

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

  group('Ngay', () {
    test('nhãn ngày dùng từ quen thuộc cho hôm nay và hôm qua', () {
      final n = DateTime.now();
      expect(Ngay.nhan(n), 'Hôm nay');
      expect(Ngay.nhan(n.subtract(const Duration(days: 1))), 'Hôm qua');
    });

    test('cột thời khóa biểu quy Chủ nhật về 8', () {
      expect(Ngay.cotTuNgay(DateTime(2026, 9, 7)), 2); // Thứ Hai
      expect(Ngay.cotTuNgay(DateTime(2026, 9, 13)), 8); // Chủ nhật
      expect(Ngay.thuTuCot(8), 'Chủ nhật');
    });

    test('số phút đọc thành giờ khi vượt 60', () {
      expect(Ngay.phut(0), '—');
      expect(Ngay.phut(45), '45 phút');
      expect(Ngay.phut(60), '1 giờ');
      expect(Ngay.phut(95), '1 giờ 35 phút');
    });
  });

  testWidgets('màn chọn vai trò hiện đủ ba lối vào', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(MockRepository()),
        child: const MaterialApp(home: _KhungChonVaiTro()),
      ),
    );
    await tester.pump();

    expect(find.text('Phụ huynh'), findsOneWidget);
    expect(find.text('Học sinh'), findsOneWidget);
    expect(find.text('Quản trị'), findsOneWidget);
  });
}

/// Bọc lại phần thân màn chọn vai trò để test không phải tải font qua mạng.
class _KhungChonVaiTro extends StatelessWidget {
  const _KhungChonVaiTro();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          for (final vt in VaiTro.values)
            ListTile(leading: Icon(vt.icon), title: Text(vt.nhan)),
        ],
      ),
    );
  }
}
