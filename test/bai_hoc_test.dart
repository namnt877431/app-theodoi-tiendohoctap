import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/data/app_state.dart';
import 'package:theodoi_hoctap/data/models/models.dart';
import 'package:theodoi_hoctap/data/nhap/kho_nhap.dart';
import 'package:theodoi_hoctap/data/repositories/hoc_tap_repository.dart';
import 'package:theodoi_hoctap/data/repositories/mock_repository.dart';
import 'package:theodoi_hoctap/features/shared/chon_bai_hoc.dart';
import 'package:theodoi_hoctap/features/shared/the_bai_hoc.dart';

import 'tro_giup.dart';

void main() {
  group('Suy khối lớp từ tên lớp', () {
    test('lấy số đứng đầu, bỏ phần chữ', () {
      expect(khoiTuLop('8A4'), 8);
      expect(khoiTuLop('12B'), 12);
      expect(khoiTuLop(' 9a2'), 9);
      expect(khoiTuLop('6'), 6);
    });

    test('không có số, số vô lí hay null thì không đoán', () {
      expect(khoiTuLop('Lớp chọn'), isNull);
      expect(khoiTuLop(null), isNull);
      expect(khoiTuLop(''), isNull);
      expect(khoiTuLop('13A'), isNull);
      expect(khoiTuLop('0B'), isNull);
    });
  });

  group('Câu hỏi kiểm tra', () {
    test('tách câu hỏi và đáp án ở sau mũi tên', () {
      final (:hoi, :dap) = tachCauHoi('3⁴ bằng bao nhiêu? → 81');
      expect(hoi, '3⁴ bằng bao nhiêu?');
      expect(dap, '81');
    });

    test('không có mũi tên thì chỉ có câu hỏi', () {
      final (:hoi, :dap) = tachCauHoi('Kể ba truyền thống tốt đẹp của dân tộc.');
      expect(hoi, 'Kể ba truyền thống tốt đẹp của dân tộc.');
      expect(dap, isNull);
    });
  });

  group('Chuyển đổi Postgres', () {
    test('bài học đi qua map giữ đủ trường', () {
      const bh = BaiHoc(
        id: 'l8_toan_bai_6',
        monId: 'm_toan',
        lop: 8,
        hocKi: 1,
        chuong: 'Chương 2',
        thuTu: 10,
        ten: 'Bài 6: Hằng đẳng thức',
        tomTat: 'Ba hằng đẳng thức đầu.',
        kiemTra: ['(x + 3)² bằng? → x² + 6x + 9'],
      );
      final lai = BaiHocPg.fromMap(bh.toMap());
      expect(lai.id, bh.id);
      expect(lai.lop, 8);
      expect(lai.hocKi, 1);
      expect(lai.thuTu, 10);
      expect(lai.chuong, 'Chương 2');
      expect(lai.tomTat, bh.tomTat);
      expect(lai.kiemTra, bh.kiemTra);
      expect(lai.coTomTat, isTrue);
    });

    test('báo cáo mang theo bai_hoc_id, kể cả khi cất nháp ra đĩa', () async {
      final bc = BaoCao(
        id: 'n1',
        hocSinhId: 'hs_01',
        ngay: DateTime(2026, 9, 12),
        loai: LoaiBaiTap.trenLop,
        monId: 'm_toan',
        baiHocId: 'l8_toan_bai_6',
        noiDung: 'x',
        trangThai: TrangThai.xong,
        taoLuc: DateTime(2026, 9, 12, 20),
      );
      expect(BaoCaoPg.fromMap(bc.toMap()).baiHocId, 'l8_toan_bai_6');
      expect(bc.copyWith(noiDung: 'y').baiHocId, 'l8_toan_bai_6');

      final tam = await Directory.systemTemp.createTemp('kho_nhap_bh_');
      addTearDown(() => tam.delete(recursive: true));
      final kho = KhoNhapFile(tam);
      await kho.ghi([bc]);
      expect((await kho.doc()).single.baiHocId, 'l8_toan_bai_6');
    });
  });

  group('Danh mục theo khối của học sinh', () {
    test('học sinh 9A2 thấy bài lớp 9, không thấy bài lớp 8', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      expect(s.hocSinhHienTai?.lop, '9A2');
      expect(s.khoiHienTai, 9);
      expect(s.baiHoc, isNotEmpty);
      expect(s.baiHoc.every((b) => b.lop == 9), isTrue);
      expect(s.baiHocTheoMon('m_toan').map((b) => b.thuTu), [1, 2, 3, 4, 5]);
      // Môn chưa có danh mục thì rỗng — biểu mẫu giấu ô chọn đi.
      expect(s.baiHocTheoMon('m_anh'), isEmpty);
    });

    test('tra được bài theo id, id lạ thì null', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      expect(s.baiHocTheoId('l9_toan_bai_2')?.ten, startsWith('Bài 2'));
      expect(s.baiHocTheoId('khong_co'), isNull);
      expect(s.baiHocTheoId(null), isNull);
    });

    test('phụ huynh xem con thì nạp danh mục theo khối của con', () async {
      final s = await vaoVoiVaiTro(VaiTro.phuHuynh);
      expect(s.hocSinhHienTai?.lop, '9A2');
      expect(s.baiHoc.every((b) => b.lop == 9), isTrue);
      // Đứa em lớp 6: khối chưa có danh mục thì danh sách rỗng, không lỗi.
      final em = s.dsCon.where((c) => c.lop == '6A1').firstOrNull;
      expect(em, isNotNull, reason: 'dữ liệu mẫu có một con lớp 6');
      await s.chonCon(em!);
      expect(s.khoiHienTai, 6);
      expect(s.baiHoc, isEmpty);
      // Bài của khối kia vẫn tra được — báo cáo của anh còn trỏ tới.
      expect(s.baiHocTheoId('l9_toan_bai_1'), isNotNull);
    });
  });

  group('Gợi ý bài kế tiếp', () {
    test('là bài đứng sau bài gần nhất đã ghi cho môn đó', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      // Dữ liệu mẫu: báo cáo Toán gần nhất có gắn bài là Bài 1 (thứ tự 1).
      expect(s.goiYBaiHoc('m_toan')?.id, 'l9_toan_bai_2');
    });

    test('chưa ghi bài nào thì gợi ý bài đầu sách; hết sách thì thôi', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      // Văn: bài gần nhất là văn bản thứ 2 và cũng là bài cuối trong mẫu.
      expect(s.goiYBaiHoc('m_van'), isNull);
      // Xóa báo cáo Văn có gắn bài đi thì về bài đầu.
      for (final bc in s.baoCao.where((b) => b.baiHocId == 'l9_van_nam_xuong').toList()) {
        await s.xoaBaoCao(bc.id);
      }
      expect(s.goiYBaiHoc('m_van')?.thuTu, 1);
      // Môn không có danh mục thì không gợi ý gì.
      expect(s.goiYBaiHoc('m_anh'), isNull);
    });

    test('ghi bài kế tiếp xong thì gợi ý nhảy tiếp', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      final bc = s.taoBaoCaoRong(loai: LoaiBaiTap.trenLop).copyWith(
            monId: 'm_toan',
            baiHocId: 'l9_toan_bai_2',
            noiDung: 'Giải hệ bằng phương pháp thế',
            trangThai: TrangThai.xong,
          );
      expect(await s.luuBaoCao(bc), KetQuaLuu.daGui);
      expect(s.goiYBaiHoc('m_toan')?.id, 'l9_toan_ltc_1');
      // Bài đã lưu lên kho vẫn giữ liên kết.
      final trenKho = await s.repo.baoCao(bc.hocSinhId);
      expect(trenKho.firstWhere((b) => b.id == bc.id).baiHocId, 'l9_toan_bai_2');
    });

    test('tính theo ngày học chứ không theo thứ tự trong sách', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      // Ghi một bài "lùi" (Bài 1) với ngày hôm nay: gần nhất theo ngày là Bài 1
      // nên gợi ý vẫn là Bài 2, dù trước đó có thể đã ghi bài xa hơn.
      final cu = s.taoBaoCaoRong(loai: LoaiBaiTap.trenLop).copyWith(
            ngay: DateTime.now().subtract(const Duration(days: 10)),
            monId: 'm_toan',
            baiHocId: 'l9_toan_bai_3',
            noiDung: 'x',
            trangThai: TrangThai.xong,
          );
      await s.luuBaoCao(cu);
      final moi = s.taoBaoCaoRong(loai: LoaiBaiTap.trenLop).copyWith(
            monId: 'm_toan',
            baiHocId: 'l9_toan_bai_1',
            noiDung: 'y',
            trangThai: TrangThai.xong,
          );
      await s.luuBaoCao(moi);
      expect(s.goiYBaiHoc('m_toan')?.id, 'l9_toan_bai_2');
    });
  });

  group('Tìm bài', () {
    const ds = [
      BaiHoc(id: 'a', monId: 'm_toan', lop: 8, thuTu: 1, ten: 'Bài 6: Lũy thừa với số mũ tự nhiên', chuong: 'Chương 1: Tập hợp'),
      BaiHoc(id: 'b', monId: 'm_toan', lop: 8, thuTu: 2, ten: 'Bài 23: Mở rộng phân số', chuong: 'Chương 6: Phân số'),
      BaiHoc(id: 'c', monId: 'm_toan', lop: 8, thuTu: 3, ten: 'Luyện tập chung (trang 13)', chuong: 'Chương 6: Phân số'),
    ];

    test('mọi từ gõ vào đều phải có trong tên hoặc chương', () {
      expect(locBaiHoc(ds, 'bài 6').map((b) => b.id), ['a']);
      expect(locBaiHoc(ds, 'phân số').map((b) => b.id), ['b', 'c']);
      expect(locBaiHoc(ds, 'PHÂN SỐ luyện').map((b) => b.id), ['c']);
      expect(locBaiHoc(ds, 'không có'), isEmpty);
    });

    test('chuỗi trống thì trả về tất cả', () {
      expect(locBaiHoc(ds, '   ').length, 3);
    });
  });

  group('Quản trị sửa danh mục bài học', () {
    test('học sinh không sửa được', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      final bh = s.baiHocTheoId('l9_toan_bai_1')!;
      expect(
        () => s.luuBaiHoc(bh.copyWith(tomTat: 'Đổi bậy')),
        throwsA(isA<LoiHocTap>()),
      );
    });

    test('quản trị sửa tóm tắt thì bộ nhớ đệm đổi theo, thêm bài mới được cấp id', () async {
      final s = await vaoVoiVaiTro(VaiTro.quanTri);
      await s.taiBaiHocKhoi(9);
      final bh = s.baiHocTheoId('l9_toan_bai_1')!;
      await s.luuBaiHoc(bh.copyWith(tomTat: 'Tóm tắt mới', kiemTra: ['Hỏi? → đáp']));
      expect(s.baiHocTheoId('l9_toan_bai_1')?.tomTat, 'Tóm tắt mới');
      expect(s.baiHocTheoId('l9_toan_bai_1')?.kiemTra, ['Hỏi? → đáp']);

      await s.luuBaiHoc(const BaiHoc(
        id: '',
        monId: 'm_toan',
        lop: 9,
        thuTu: 99,
        ten: 'Bài thêm tay',
      ));
      final them = s.baiHocKhoi(9).where((b) => b.ten == 'Bài thêm tay').single;
      expect(them.id, startsWith('l9_toan_qt_'));
      // Xếp đúng chỗ theo môn rồi thứ tự.
      expect(s.baiHocKhoi(9).where((b) => b.monId == 'm_toan').last.id, them.id);

      await s.xoaBaiHoc(them);
      expect(s.baiHocTheoId(them.id), isNull);
    });

    test('nạp lại từ máy chủ bỏ bản đệm cũ', () async {
      final repo = MockRepository();
      final s = AppState(repo);
      await s.dungThuVoiVaiTro(VaiTro.quanTri);
      await cho(() => s.nguoiDung != null && !s.dangTai, moTa: 'phiên đăng nhập');
      await s.taiBaiHocKhoi(8);
      expect(s.baiHocKhoi(8).length, 2);
      // Máy chủ có thêm bài (ví dụ vừa chạy file SQL) — chỉ thấy khi nạp lại.
      final mock = s.repo as MockRepository;
      await mock.dangNhapThu(VaiTro.quanTri);
      await mock.luuBaiHoc(const BaiHoc(id: 'l8_x', monId: 'm_toan', lop: 8, thuTu: 3, ten: 'X'));
      expect(s.baiHocKhoi(8).length, 2);
      await s.taiBaiHocKhoi(8, lamMoi: true);
      expect(s.baiHocKhoi(8).length, 3);
    });
  });

  group('Tấm bài học', () {
    testWidgets('hiện tóm tắt, câu hỏi; đáp án giấu tới khi chạm', (t) async {
      const bh = BaiHoc(
        id: 'x',
        monId: 'm_toan',
        lop: 8,
        thuTu: 1,
        ten: 'Bài 6: Lũy thừa',
        tomTat: 'Viết gọn tích nhiều thừa số bằng nhau.',
        kiemTra: ['3⁴ bằng bao nhiêu? → 81', 'Đọc thuộc công thức.'],
      );
      await t.pumpWidget(const MaterialApp(
        home: Scaffold(body: TheBaiHoc(bh, laPhuHuynh: true)),
      ));
      expect(find.text('Bài 6: Lũy thừa'), findsOneWidget);
      expect(find.text('Viết gọn tích nhiều thừa số bằng nhau.'), findsOneWidget);
      expect(find.text('HỎI CON THỬ'), findsOneWidget);
      expect(find.text('3⁴ bằng bao nhiêu?'), findsOneWidget);
      expect(find.text('Gợi ý: 81'), findsNothing);
      // Câu không có đáp án thì không có nút xem gợi ý.
      expect(find.text('Xem gợi ý đáp án'), findsOneWidget);

      await t.tap(find.text('Xem gợi ý đáp án'));
      await t.pump();
      expect(find.text('Gợi ý: 81'), findsOneWidget);
      expect(find.text('Xem gợi ý đáp án'), findsNothing);
    });

    testWidgets('học sinh xem thì nhãn là tự kiểm tra; chưa có tóm tắt thì nói rõ', (t) async {
      const bh = BaiHoc(id: 'x', monId: 'm_toan', lop: 8, thuTu: 1, ten: 'Bài 1', kiemTra: ['Hỏi?']);
      await t.pumpWidget(const MaterialApp(home: Scaffold(body: TheBaiHoc(bh))));
      expect(find.text('TỰ KIỂM TRA'), findsOneWidget);
      expect(find.text('Bài này chưa có tóm tắt.'), findsOneWidget);
    });
  });
}
