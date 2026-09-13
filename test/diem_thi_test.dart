import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:theodoi_hoctap/core/theme/tokens.dart';
import 'package:theodoi_hoctap/data/app_state.dart';
import 'package:theodoi_hoctap/data/models/models.dart';
import 'package:theodoi_hoctap/core/widgets/common.dart';
import 'package:theodoi_hoctap/features/shared/so_diem.dart';

import 'tro_giup.dart';

DiemThi _d(String mon, LoaiKiemTra loai, double diem, {int hocKi = 1, int lui = 0}) => DiemThi(
      id: '$mon-${loai.name}-$diem-$lui',
      hocSinhId: 'hs',
      monId: mon,
      loai: loai,
      hocKi: hocKi,
      diem: diem,
      ngay: DateTime(2026, 10, 20).subtract(Duration(days: lui)),
      taoLuc: DateTime(2026, 10, 20),
    );

DiemThi _nx(String mon, bool dat, {int lui = 0}) => DiemThi(
      id: '$mon-nx-$dat-$lui',
      hocSinhId: 'hs',
      monId: mon,
      loai: LoaiKiemTra.mieng,
      hocKi: 1,
      dat: dat,
      ngay: DateTime(2026, 10, 20).subtract(Duration(days: lui)),
      taoLuc: DateTime(2026, 10, 20),
    );

PhanThuong _qua({String? mon, LoaiKiemTra? ki, double diem = 8, int soLanTrao = 0}) => PhanThuong(
      id: 'q',
      hocSinhId: 'hs',
      taoBoi: 'ph',
      loai: LoaiPhanThuong.diem,
      moc: 1,
      ten: 'Xem phim',
      tuNgay: DateTime(2026, 10, 1),
      taoLuc: DateTime(2026, 10, 1),
      monId: mon,
      kiThi: ki,
      diemToiThieu: diem,
      soLanTrao: soLanTrao,
    );

void main() {
  group('Chữ điểm', () {
    test('bỏ số 0 thừa, dấu phẩy như học bạ', () {
      expect(chuDiem(8.5), '8,5');
      expect(chuDiem(9), '9');
      expect(chuDiem(10), '10');
      expect(chuDiem(7.25), '7,25');
      expect(_d('m_toan', LoaiKiemTra.giuaKi, 6.75).diemChu, '6,75');
    });
  });

  group('Quà điểm thi', () {
    test('chỉ bài lớn, đúng môn, đúng kì, đủ điểm, từ ngày treo; Đ/CĐ không tính', () {
      final q = _qua(mon: 'm_toan', ki: LoaiKiemTra.giuaKi, diem: 8);
      expect(q.khopDiem(_d('m_toan', LoaiKiemTra.giuaKi, 8)), isTrue);
      expect(q.khopDiem(_d('m_toan', LoaiKiemTra.giuaKi, 7.75)), isFalse, reason: 'thiếu điểm');
      expect(q.khopDiem(_d('m_toan', LoaiKiemTra.cuoiKi, 9)), isFalse, reason: 'sai kì');
      expect(q.khopDiem(_d('m_van', LoaiKiemTra.giuaKi, 9)), isFalse, reason: 'sai môn');
      expect(q.khopDiem(_d('m_toan', LoaiKiemTra.mieng, 10)), isFalse, reason: 'bài nhỏ');
      expect(q.khopDiem(_d('m_toan', LoaiKiemTra.giuaKi, 9, lui: 40)), isFalse, reason: 'trước ngày treo');
      expect(q.khopDiem(_nx('m_toan', true).copyWith(loai: LoaiKiemTra.giuaKi)), isFalse, reason: 'Đ không phải điểm');
    });

    test('môn và kì bỏ trống là môn nào, kì nào cũng được; thường xuyên vẫn không', () {
      final q = _qua(diem: 9);
      expect(q.khopDiem(_d('m_van', LoaiKiemTra.cuoiKi, 9)), isTrue);
      expect(q.khopDiem(_d('m_anh', LoaiKiemTra.giuaKi, 9.5)), isTrue);
      expect(q.khopDiem(_d('m_anh', LoaiKiemTra.muoiLamPhut, 10)), isFalse);
    });

    test('mỗi bài đạt là một lần; trao bớt thì nợ giảm; bài mới nhất đứng đầu', () {
      final ds = [
        _d('m_toan', LoaiKiemTra.giuaKi, 8.5, lui: 10),
        _d('m_van', LoaiKiemTra.giuaKi, 9, lui: 2),
        _d('m_anh', LoaiKiemTra.giuaKi, 7, lui: 1),
      ];
      final td = AppState.tinhTienDoDiem(_qua(diem: 8), ds);
      expect(td.soLanDat, 2);
      expect(td.conNo, 2);
      expect(td.baiDat.first.monId, 'm_van');
      expect(td.tiLe, 1);

      final daTrao = AppState.tinhTienDoDiem(_qua(diem: 8, soLanTrao: 2), ds);
      expect(daTrao.dat, isFalse);
      expect(daTrao.conNo, 0);
    });
  });

  group('Điểm trung bình môn', () {
    test('miệng và 15 phút hệ số 1, giữa kì 2, cuối kì 3, chia tổng hệ số', () {
      final tb = diemTrungBinh([
        _d('m_toan', LoaiKiemTra.mieng, 8),
        _d('m_toan', LoaiKiemTra.muoiLamPhut, 9),
        _d('m_toan', LoaiKiemTra.giuaKi, 7),
        _d('m_toan', LoaiKiemTra.cuoiKi, 8),
      ]);
      // (8 + 9 + 2·7 + 3·8) / (1 + 1 + 2 + 3) = 55 / 7
      expect(tb, closeTo(55 / 7, 1e-9));
    });

    test('thiếu giữa kì hay cuối kì thì chưa tính', () {
      expect(diemTrungBinh([_d('m_toan', LoaiKiemTra.giuaKi, 7)]), isNull);
      expect(diemTrungBinh([_d('m_toan', LoaiKiemTra.mieng, 7), _d('m_toan', LoaiKiemTra.cuoiKi, 7)]), isNull);
    });

    test('màu theo mức xếp loại; Đ xanh, CĐ đỏ', () {
      expect(mauSo(8), AppColor.xong);
      expect(mauSo(6.5), AppColor.muc);
      expect(mauSo(5), AppColor.dangLam);
      expect(mauSo(4.75), AppColor.butDo);
      expect(mauDiem(_nx('m_td', true)), AppColor.xong);
      expect(mauDiem(_nx('m_td', false)), AppColor.butDo);
    });

    test('TBM ghi một chữ số lẻ; môn chấm nhận xét ra Đ khi mọi bài đều Đ', () {
      expect(chuTbm(55 / 7), '7,9');
      expect(chuTbm(10), '10,0');
      expect(chuTbmMon([_nx('m_td', true), _nx('m_td', true)]), 'Đ');
      expect(chuTbmMon([_nx('m_td', true), _nx('m_td', false)]), 'CĐ');
      expect(chuTbmMon([_d('m_toan', LoaiKiemTra.mieng, 9)]), isNull);
      // Điểm Đ/CĐ không kéo TBM số.
      expect(
        diemTrungBinh([
          _d('m_toan', LoaiKiemTra.giuaKi, 8),
          _d('m_toan', LoaiKiemTra.cuoiKi, 8),
          _nx('m_toan', true),
        ]),
        closeTo(8, 1e-9),
      );
    });
  });

  group('Cả năm và xếp loại', () {
    KetQuaMon km(String mon, double? tb, {bool? dat}) =>
        KetQuaMon(mon, tb: tb != null ? TbMon.so(tb) : dat != null ? TbMon.nhanXet(dat) : null);

    test('TB cả năm = (HK1 + 2 × HK2) ÷ 3; thiếu một kỳ thì chưa tính', () {
      final ds = [
        _d('m_toan', LoaiKiemTra.giuaKi, 8, hocKi: 1),
        _d('m_toan', LoaiKiemTra.cuoiKi, 8, hocKi: 1),
        _d('m_toan', LoaiKiemTra.giuaKi, 9.5, hocKi: 2),
        _d('m_toan', LoaiKiemTra.cuoiKi, 9.5, hocKi: 2),
      ];
      final k = ketQuaCaNam('m_toan', ds);
      expect(k.hk1!.so, closeTo(8, 1e-9));
      expect(k.hk2!.so, closeTo(9.5, 1e-9));
      expect(k.tb!.so, closeTo((8 + 2 * 9.5) / 3, 1e-9));
      expect(k.chu, '9,0');

      final thieu = ketQuaCaNam('m_toan', ds.where((d) => d.hocKi == 1).toList());
      expect(thieu.tb, isNull);
      expect(thieu.chuaDu, isTrue);
    });

    test('môn nhận xét cả năm Đ khi cả hai kỳ Đ', () {
      final ds = [_nx('m_td', true).copyWith(hocKi: 1), _nx('m_td', true).copyWith(hocKi: 2)];
      expect(ketQuaCaNam('m_td', ds).chu, 'Đ');
      final xau = [_nx('m_td', true).copyWith(hocKi: 1), _nx('m_td', false).copyWith(hocKi: 2)];
      expect(ketQuaCaNam('m_td', xau).chu, 'CĐ');
    });

    test('xếp loại Giỏi cần TB ≥ 8, không môn nào dưới 6,5, Toán hoặc Văn ≥ 8, nhận xét Đ', () {
      expect(xepLoaiHocLuc([km('m_toan', 8.5), km('m_van', 7), km('m_anh', 9), km('m_td', null, dat: true)]), 'Giỏi');
      // Một môn 6,4 → tụt xuống Khá.
      expect(xepLoaiHocLuc([km('m_toan', 9), km('m_van', 9), km('m_anh', 6.4)]), 'Khá');
      // Toán và Văn đều dưới 8 → Khá dù TB cao.
      expect(xepLoaiHocLuc([km('m_toan', 7.9), km('m_van', 7.9), km('m_anh', 10), km('m_ly', 10)]), 'Khá');
      // Thể dục CĐ → không Giỏi, không Khá, không TB → Yếu.
      expect(xepLoaiHocLuc([km('m_toan', 9), km('m_van', 9), km('m_td', null, dat: false)]), 'Yếu');
    });

    test('các mức thấp hơn; chưa có TBM nào thì không xếp', () {
      expect(xepLoaiHocLuc([km('m_toan', 7), km('m_van', 6)]), 'Khá');
      expect(xepLoaiHocLuc([km('m_toan', 5.5), km('m_van', 4.5)]), 'Trung bình');
      expect(xepLoaiHocLuc([km('m_toan', 4), km('m_van', 3)]), 'Yếu');
      expect(xepLoaiHocLuc([km('m_toan', 2), km('m_van', 1)]), 'Kém');
      expect(xepLoaiHocLuc([km('m_toan', null), km('m_td', null, dat: true)]), isNull);
      expect(tbCacMonCua([km('m_toan', 8), km('m_van', 6)]), closeTo(7, 1e-9));
    });
  });

  group('Bảng điểm (widget)', () {
    for (final rong in [360.0, 390.0, 800.0]) {
      testWidgets('đủ mọi môn một hàng, không tràn ở $rong', (t) async {
        final s = (await t.runAsync(() => vaoVoiVaiTro(VaiTro.hocSinh)))!;
        t.view.physicalSize = Size(rong, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(ChangeNotifierProvider.value(
          value: s,
          child: const MaterialApp(home: SoDiemScreen()),
        ));
        await t.pump();
        expect(t.takeException(), isNull);
        for (final m in s.monHoc) {
          expect(find.text(m.ten), findsOneWidget);
        }
        // Khôi có 9 miệng, 10 (15 phút), 8,5 1 tiết Toán; chưa có học kỳ → chưa có TBM.
        // Thể dục chấm Đ → TBM Đ.
        expect(find.textContaining('8,5'), findsOneWidget);
        expect(find.text('Đ'), findsWidgets);
        expect(find.text('Môn học'), findsOneWidget);
        expect(find.text('TBM'), findsOneWidget);
      });
    }

    testWidgets('chế độ cả năm: ba cột học kỳ 1, học kỳ 2, cả năm', (t) async {
      final s = (await t.runAsync(() => vaoVoiVaiTro(VaiTro.hocSinh)))!;
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(ChangeNotifierProvider.value(
        value: s,
        child: const MaterialApp(home: SoDiemScreen()),
      ));
      await t.pump();
      await t.tap(find.text('Cả năm'));
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.text('Học kỳ 1'), findsNWidgets(2), reason: 'chip và đầu cột');
      expect(find.text('TBM'), findsNothing);
    });

    testWidgets('chạm ô trống mở bảng ghi với đúng môn và cột', (t) async {
      final s = (await t.runAsync(() => vaoVoiVaiTro(VaiTro.hocSinh)))!;
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(ChangeNotifierProvider.value(
        value: s,
        child: const MaterialApp(home: SoDiemScreen()),
      ));
      await t.pump();
      // Chạm ô "Học kỳ" của Toán (còn trống) → bảng ghi với Toán, cột Học kỳ chọn sẵn.
      final oToan = find.descendant(
        of: find.ancestor(of: find.text('Toán'), matching: find.byType(Row)).first,
        matching: find.byType(InkWell),
      );
      await t.tap(oToan.at(3));
      await t.pumpAndSettle();
      expect(find.text('Ghi điểm'), findsWidgets);
      final chonHocKy = t.widgetList<OChon>(find.byType(OChon)).firstWhere((o) => o.nhan == 'Học kỳ');
      expect(chonHocKy.chon, isTrue);

      // Ô có điểm rồi (miệng Toán) thì mở danh sách để sửa hay ghi thêm.
      Navigator.of(t.element(find.byType(OChon).first)).pop();
      await t.pumpAndSettle();
      await t.tap(oToan.at(0));
      await t.pumpAndSettle();
      expect(find.text('Ghi thêm'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });
  });

  group('AppState sổ điểm', () {
    test('học kì theo lịch: tháng 9–12 là kì 1, còn lại kì 2', () {
      expect(AppState.hocKiCua(DateTime(2026, 9, 5)), 1);
      expect(AppState.hocKiCua(DateTime(2026, 12, 31)), 1);
      expect(AppState.hocKiCua(DateTime(2027, 1, 10)), 2);
      expect(AppState.hocKiCua(DateTime(2027, 5, 20)), 2);
    });

    test('con ghi điểm, bố mẹ thấy và sửa được, xóa được; quà điểm đếm theo', () async {
      final hs = await vaoVoiVaiTro(VaiTro.hocSinh);
      final truoc = hs.diemThi.length;
      await hs.ghiDiem(
        monId: 'm_van',
        loai: LoaiKiemTra.cuoiKi,
        hocKi: 1,
        diem: 9,
        ngay: DateTime.now(),
        ghiChu: '  ',
      );
      expect(hs.diemThi.length, truoc + 1);
      final moi = hs.diemThi.first;
      expect(moi.monId, 'm_van');
      expect(moi.ghiChu, isNull, reason: 'ghi chú toàn khoảng trắng thì bỏ');
      expect(moi.taoBoi, hs.nguoiDung!.id);
      // Quà "từ 8 trở lên" trong dữ liệu mẫu giờ đạt hai bài.
      final qua = hs.tienDoPhanThuong.firstWhere((t) => t.phanThuong.loai == LoaiPhanThuong.diem);
      expect(qua.soLanDat, 2);

      // Cùng kho mẫu trong bộ nhớ: phụ huynh đăng nhập bằng repo của phiên này.
      await hs.luuDiem(moi.copyWith(diem: () => 9.5, ghiChu: () => 'Cô chấm lại'));
      final sua = hs.diemThi.firstWhere((d) => d.id == moi.id);
      expect(sua.diem, 9.5);
      expect(sua.ghiChu, 'Cô chấm lại');

      await hs.xoaDiem(sua);
      expect(hs.diemThi.any((d) => d.id == moi.id), isFalse);
    });
  });
}
