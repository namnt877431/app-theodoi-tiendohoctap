import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:theodoi_hoctap/data/app_state.dart';
import 'package:theodoi_hoctap/data/diem_danh.dart';
import 'package:theodoi_hoctap/data/models/models.dart';
import 'package:theodoi_hoctap/features/student/diem_danh_hom_nay.dart';

import 'tro_giup.dart';

TietHoc _tiet(int tiet, String mon,
        {String? gv, LoaiBaiTap loai = LoaiBaiTap.trenLop, Buoi buoi = Buoi.sang}) =>
    TietHoc(
      id: 't$tiet${loai.name}',
      hocSinhId: 'hs',
      thu: 2,
      tiet: tiet,
      buoi: buoi,
      monId: mon,
      loai: loai,
      giaoVienId: gv,
    );

BaoCao _baoCao(String mon, LoaiBaiTap loai) => BaoCao(
      id: 'b$mon${loai.name}',
      hocSinhId: 'hs',
      ngay: DateTime(2027, 3, 1),
      loai: loai,
      monId: mon,
      noiDung: '',
      trangThai: TrangThai.xong,
      taoLuc: DateTime(2027, 3, 1, 20),
    );

/// Một thứ Hai xa trong tương lai: dữ liệu mẫu không có báo cáo nào ở đó,
/// còn thời khóa biểu của Khôi thứ Hai có Toán, Văn (hai tiết), Anh, Sử.
final _thuHai = DateTime(2027, 3, 1);

void main() {
  group('tinhMucDiemDanh', () {
    test('gộp tiết cùng môn, giữ thứ tự tiết; học thêm cùng môn là dòng riêng', () {
      final ds = tinhMucDiemDanh([
        _tiet(1, 'm_toan', gv: 'gv_lan'),
        _tiet(2, 'm_van', gv: 'gv_hoa'),
        _tiet(3, 'm_van', gv: 'gv_hoa'),
        _tiet(4, 'm_anh'),
        _tiet(1, 'm_toan', gv: 'gv_ht_son', loai: LoaiBaiTap.hocThem, buoi: Buoi.toi),
      ], const []);

      expect(ds.map((m) => m.monId), ['m_toan', 'm_van', 'm_anh', 'm_toan']);
      expect(ds.map((m) => m.loai), [
        LoaiBaiTap.trenLop,
        LoaiBaiTap.trenLop,
        LoaiBaiTap.trenLop,
        LoaiBaiTap.hocThem,
      ]);
      expect(ds[1].tiet, 2, reason: 'Văn ghi tiết đầu tiên trong ngày');
      expect(ds.last.giaoVienId, 'gv_ht_son');
    });

    test('môn đã có báo cáo cùng hạng mục thì biến mất; hạng mục kia vẫn còn', () {
      final ds = tinhMucDiemDanh([
        _tiet(1, 'm_toan', gv: 'gv_lan'),
        _tiet(2, 'm_van'),
        _tiet(1, 'm_toan', loai: LoaiBaiTap.hocThem, buoi: Buoi.toi),
      ], [
        _baoCao('m_toan', LoaiBaiTap.trenLop),
      ]);

      expect(ds.map((m) => (m.monId, m.loai)), [
        ('m_van', LoaiBaiTap.trenLop),
        ('m_toan', LoaiBaiTap.hocThem),
      ]);
    });

    test('thầy cô lấy ở tiết đầu tiên có ghi tên', () {
      final ds = tinhMucDiemDanh([
        _tiet(2, 'm_van'),
        _tiet(3, 'm_van', gv: 'gv_hoa'),
      ], const []);

      expect(ds.single.giaoVienId, 'gv_hoa');
      expect(ds.single.tiet, 2);
    });

    test('bài đang học và bài sau lấy qua hàm truyền vào, một lần mỗi môn; học thêm không đoán',
        () {
      const b1 = BaiHoc(id: 'b1', monId: 'm_toan', lop: 9, thuTu: 1, ten: 'Bài 1');
      const b2 = BaiHoc(id: 'b2', monId: 'm_toan', lop: 9, thuTu: 2, ten: 'Bài 2');
      final daHoi = <String>[];
      final ds = tinhMucDiemDanh(
        [
          _tiet(1, 'm_toan'),
          _tiet(2, 'm_toan'),
          _tiet(3, 'm_van'),
          _tiet(1, 'm_toan', loai: LoaiBaiTap.hocThem, buoi: Buoi.toi),
        ],
        const [],
        baiDangHoc: (mon) {
          daHoi.add(mon);
          return mon == 'm_toan' ? b1 : null;
        },
        baiSau: (bh) => bh.id == 'b1' ? b2 : null,
      );

      expect(daHoi, ['m_toan', 'm_van']);
      expect(ds[0].baiHoc?.id, 'b1');
      expect(ds[0].baiTiep?.id, 'b2');
      expect(ds[1].baiHoc, isNull);
      expect(ds[1].baiTiep, isNull);
      expect(ds[2].loai, LoaiBaiTap.hocThem);
      expect(ds[2].baiHoc, isNull, reason: 'học thêm không điền bài');
    });
  });

  group('AppState.diemDanh', () {
    test('thứ Hai của Khôi có bốn môn chưa báo; Toán điền bài hôm trước và biết bài sau',
        () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      final ds = s.mucDiemDanh(_thuHai);

      expect(ds.map((m) => m.monId), ['m_toan', 'm_van', 'm_anh', 'm_su']);
      expect(ds.first.giaoVienId, 'gv_lan');
      expect(ds.first.baiHoc?.id, 'l9_toan_bai_1');
      expect(ds.first.baiTiep?.id, 'l9_toan_bai_2');
    });

    test('một chạm tạo báo cáo đủ môn, thầy, hạng mục, bài, trạng thái — và dòng đó biến mất',
        () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      final toan = s.mucDiemDanh(_thuHai).first;

      final (bc, ketQua) = await s.diemDanh(
        toan,
        TrangThai.dangLam,
        baiHocId: toan.baiHoc?.id,
        ngay: _thuHai,
      );

      expect(ketQua, KetQuaLuu.daGui);
      final daLuu = s.baoCao.firstWhere((b) => b.id == bc.id);
      expect(daLuu.monId, 'm_toan');
      expect(daLuu.giaoVienId, 'gv_lan');
      expect(daLuu.loai, LoaiBaiTap.trenLop);
      expect(daLuu.baiHocId, toan.baiHoc?.id);
      expect(daLuu.trangThai, TrangThai.dangLam);
      expect(daLuu.noiDung, isEmpty);
      expect(daLuu.ngay, _thuHai);
      expect(s.mucDiemDanh(_thuHai).map((m) => m.monId), ['m_van', 'm_anh', 'm_su']);
    });

    test('"không có bài" là báo cáo xong kèm lời ghi rõ', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      final su = s.mucDiemDanh(_thuHai).last;

      final (bc, _) = await s.diemDanh(su, TrangThai.xong,
          noiDung: noiDungKhongCoBai, ngay: _thuHai);

      final daLuu = s.baoCao.firstWhere((b) => b.id == bc.id);
      expect(daLuu.trangThai, TrangThai.xong);
      expect(daLuu.noiDung, 'Không có bài tập');
    });

    test('taoBaoCaoRong nhận đủ tham số, ngày mặc định là đầu ngày hôm nay', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      final bc = s.taoBaoCaoRong(
        loai: LoaiBaiTap.hocThem,
        monId: 'm_ly',
        giaoVienId: 'gv_ht_dung',
        baiHocId: 'x',
        trangThai: TrangThai.xong,
        noiDung: 'abc',
      );
      final n = DateTime.now();

      expect(bc.loai, LoaiBaiTap.hocThem);
      expect(bc.monId, 'm_ly');
      expect(bc.giaoVienId, 'gv_ht_dung');
      expect(bc.baiHocId, 'x');
      expect(bc.trangThai, TrangThai.xong);
      expect(bc.noiDung, 'abc');
      expect(bc.ngay, DateTime(n.year, n.month, n.day));
      expect(s.taoBaoCaoRong(loai: LoaiBaiTap.trenLop).monId, s.monMacDinh);
    });
  });

  group('Bảng điểm danh (widget)', () {
    Future<AppState> dung(WidgetTester t, List<MucDiemDanh> ds, AppState s) async {
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(ChangeNotifierProvider.value(
        value: s,
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: DiemDanhHomNay(ds: ds))),
        ),
      ));
      await t.pump();
      return s;
    }

    testWidgets('mỗi môn một dòng với bốn ô, không ô nào chọn sẵn, bài hôm trước điền sẵn',
        (t) async {
      final s = (await t.runAsync(() => vaoVoiVaiTro(VaiTro.hocSinh)))!;
      final ds = s.mucDiemDanh(_thuHai);
      await dung(t, ds, s);

      expect(find.textContaining('Toán'), findsOneWidget);
      expect(find.textContaining('Ngữ văn'), findsOneWidget);
      expect(find.text('Đã xong'), findsNWidgets(4));
      expect(find.text('Không có bài'), findsNWidgets(4));
      expect(find.byTooltip('Ghi thêm chữ, ảnh'), findsNWidgets(4));
      expect(find.text(s.baiDangHoc('m_toan')!.ten), findsOneWidget);
      // Văn đã ở bài cuối trong mẫu, không có "Bài tiếp"; Toán thì có.
      expect(find.text('Bài tiếp'), findsOneWidget);
    });

    testWidgets('"Bài tiếp" nhảy bài của dòng lên một bài; báo cáo ghi bài đó', (t) async {
      final s = (await t.runAsync(() => vaoVoiVaiTro(VaiTro.hocSinh)))!;
      final ds = s.mucDiemDanh(_thuHai);
      await dung(t, ds, s);

      await t.tap(find.text('Bài tiếp'));
      await t.pump();
      expect(find.text(s.baiDangHoc('m_toan')!.ten), findsNothing);
      expect(find.textContaining('Bài 2:'), findsOneWidget);

      await t.tap(find.text('Đang làm').first);
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));

      final moi = s.baoCao.singleWhere((b) => b.noiDung.isEmpty);
      expect(moi.baiHocId, 'l9_toan_bai_2');
      expect(moi.trangThai, TrangThai.dangLam);
    });

    testWidgets('chạm "Đã xong" ở dòng Toán là có báo cáo Toán xong', (t) async {
      final s = (await t.runAsync(() => vaoVoiVaiTro(VaiTro.hocSinh)))!;
      final ds = s.mucDiemDanh(_thuHai);
      final truoc = s.baoCao.length;
      await dung(t, ds, s);

      // Kho mẫu trả lời sau 180 ms giả lập — mỗi lần lưu rồi nạp lại là hai
      // nhịp như thế; đẩy đồng hồ giả qua đó chứ không dùng runAsync, vì
      // trong runAsync google_fonts sẽ thật sự đi tải font và ném lỗi.
      await t.tap(find.text('Đã xong').first);
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));

      expect(s.baoCao.length, truoc + 1);

      // Báo cáo mẫu nào cũng có chữ; bản ghi từ bảng điểm danh thì không.
      final moi = s.baoCao.singleWhere((b) => b.noiDung.isEmpty);
      expect(moi.monId, 'm_toan');
      expect(moi.loai, LoaiBaiTap.trenLop);
      expect(moi.trangThai, TrangThai.xong);
      expect(moi.giaoVienId, 'gv_lan');
      expect(moi.baiHocId, ds.first.baiHoc?.id);
      expect(find.textContaining('Toán · Đã xong'), findsOneWidget);
    });
  });
}
