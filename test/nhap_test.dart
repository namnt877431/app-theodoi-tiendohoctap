import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/data/app_state.dart';
import 'package:theodoi_hoctap/data/models/models.dart';
import 'package:theodoi_hoctap/data/nhap/kho_nhap.dart';
import 'package:theodoi_hoctap/data/repositories/mock_repository.dart';

import 'tro_giup.dart';

Future<(AppState, MockRepository)> vaoHocSinh(KhoNhap kho) async {
  final repo = MockRepository();
  final s = AppState(repo, khoNhap: kho);
  await repo.dangNhapThu(VaiTro.hocSinh);
  await cho(() => s.nguoiDung != null && !s.dangTai, moTa: 'phiên đăng nhập');
  return (s, repo);
}

BaoCao baiMoi(AppState s, String noiDung, {List<String> anh = const []}) =>
    s.taoBaoCaoRong(loai: LoaiBaiTap.trenLop).copyWith(
          noiDung: noiDung,
          trangThai: TrangThai.xong,
          anh: anh,
        );

void main() {
  group('Viết lúc mất mạng', () {
    test('không có mạng thì bài được cất trên máy và vẫn hiện trong danh sách', () async {
      final kho = KhoNhapBoNho();
      final (s, repo) = await vaoHocSinh(kho);
      final soCu = s.baoCao.length;

      repo.matMang = true;
      final bc = baiMoi(s, 'Bài lúc mất sóng');
      final kq = await s.luuBaoCao(bc);

      expect(kq, KetQuaLuu.choMang);
      expect(s.laNhap(bc.id), isTrue);
      expect(s.soNhap, 1);
      expect(s.baoCao.length, soCu + 1);
      expect(s.baoCao.first.id, bc.id); // xếp lên đầu
      expect(kho.ds.map((b) => b.id), [bc.id]);
      // Máy chủ chưa có gì.
      final trenMayChu = await (repo..matMang = false).baoCao(bc.hocSinhId);
      expect(trenMayChu.any((b) => b.id == bc.id), isFalse);
    });

    test('có mạng lại thì gửi đi, xóa khỏi máy', () async {
      final kho = KhoNhapBoNho();
      final (s, repo) = await vaoHocSinh(kho);
      repo.matMang = true;
      final bc = baiMoi(s, 'Chờ mạng');
      await s.luuBaoCao(bc);

      repo.matMang = false;
      final daGui = await s.guiNhap();

      expect(daGui, 1);
      expect(s.soNhap, 0);
      expect(s.laNhap(bc.id), isFalse);
      expect(kho.ds, isEmpty);
      expect(s.baoCao.any((b) => b.id == bc.id), isTrue);
      expect((await repo.baoCao(bc.hocSinhId)).any((b) => b.id == bc.id), isTrue);
    });

    test('vẫn mất mạng thì gửi lại không làm gì, bài còn nguyên', () async {
      final kho = KhoNhapBoNho();
      final (s, repo) = await vaoHocSinh(kho);
      repo.matMang = true;
      await s.luuBaoCao(baiMoi(s, 'x'));
      expect(await s.guiNhap(), 0);
      expect(s.soNhap, 1);
    });

    test('sửa lại bài đang chờ thì thay chứ không nhân đôi', () async {
      final kho = KhoNhapBoNho();
      final (s, repo) = await vaoHocSinh(kho);
      repo.matMang = true;
      final bc = baiMoi(s, 'bản một');
      await s.luuBaoCao(bc);
      await s.luuBaoCao(bc.copyWith(noiDung: 'bản hai'));

      expect(s.soNhap, 1);
      expect(s.baoCao.firstWhere((b) => b.id == bc.id).noiDung, 'bản hai');
    });

    test('xóa bài đang chờ thì bỏ khỏi máy, không đụng máy chủ', () async {
      final kho = KhoNhapBoNho();
      final (s, repo) = await vaoHocSinh(kho);
      repo.matMang = true;
      final bc = baiMoi(s, 'xóa đi');
      await s.luuBaoCao(bc);
      await s.xoaBaoCao(bc.id);
      expect(s.soNhap, 0);
      expect(kho.ds, isEmpty);
    });

    test('mở app lại là bài chờ được đọc lên và tự gửi', () async {
      final kho = KhoNhapBoNho();
      final (s1, repo1) = await vaoHocSinh(kho);
      repo1.matMang = true;
      final bc = baiMoi(s1, 'từ phiên trước');
      await s1.luuBaoCao(bc);
      expect(kho.ds.length, 1);

      // Phiên mới trên cùng máy, có mạng.
      final (s2, repo2) = await vaoHocSinh(kho);
      await cho(() => kho.ds.isEmpty, moTa: 'tự gửi nháp lúc đăng nhập');
      expect(s2.soNhap, 0);
      expect((await repo2.baoCao(bc.hocSinhId)).any((b) => b.id == bc.id), isTrue);
    });

    test('mất mạng thì kéo làm mới không ném lỗi, dữ liệu cũ giữ nguyên', () async {
      final (s, repo) = await vaoHocSinh(KhoNhapBoNho());
      final soCu = s.baoCao.length;
      repo.matMang = true;
      await s.lamMoi();
      expect(s.baoCao.length, soCu);
    });

    test('bài chờ mạng vẫn được tính vào tổng kết ngày và con dấu', () async {
      final (s, repo) = await vaoHocSinh(KhoNhapBoNho());
      final xongTruoc = s.tongKet(DateTime.now()).xong;
      repo.matMang = true;
      await s.luuBaoCao(baiMoi(s, 'tính luôn'));
      expect(s.tongKet(DateTime.now()).xong, xongTruoc + 1);
    });
  });

  group('Kho nháp trên đĩa', () {
    late Directory tam;

    setUp(() async {
      tam = await Directory.systemTemp.createTemp('kho_nhap_');
    });

    tearDown(() async {
      await tam.delete(recursive: true);
    });

    test('ghi rồi đọc lại giữ đủ trường, kể cả giờ tạo', () async {
      final kho = KhoNhapFile(tam);
      final bc = BaoCao(
        id: 'n1',
        hocSinhId: 'hs_01',
        ngay: DateTime(2026, 9, 12),
        loai: LoaiBaiTap.hocThem,
        monId: 'm_toan',
        giaoVienId: 'gv_ht_son',
        noiDung: 'Đề số 7',
        trangThai: TrangThai.dangLam,
        anh: const ['demo:a'],
        soPhut: 45,
        taoLuc: DateTime(2026, 9, 12, 20, 15),
      );
      await kho.ghi([bc]);
      final lai = await kho.doc();
      expect(lai.length, 1);
      expect(lai.first.id, 'n1');
      expect(lai.first.noiDung, 'Đề số 7');
      expect(lai.first.loai, LoaiBaiTap.hocThem);
      expect(lai.first.anh, ['demo:a']);
      expect(lai.first.soPhut, 45);
      expect(lai.first.taoLuc, DateTime(2026, 9, 12, 20, 15));
    });

    test('chưa có file thì danh sách rỗng; file hỏng cũng rỗng', () async {
      final kho = KhoNhapFile(tam);
      expect(await kho.doc(), isEmpty);
      await File('${tam.path}/nhap_bao_cao.json').writeAsString('{hỏng');
      expect(await kho.doc(), isEmpty);
    });

    test('giữ ảnh chép sang thư mục bền, bỏ ảnh xóa đi', () async {
      final kho = KhoNhapFile(tam);
      final goc = File('${tam.path}/chup.jpg')..writeAsBytesSync([1, 2, 3]);
      final ben = await kho.giuAnh(goc.path);
      expect(ben, isNot(goc.path));
      expect(await File(ben).readAsBytes(), [1, 2, 3]);
      // Đã bền rồi thì giữ lại trả về chính nó.
      expect(await kho.giuAnh(ben), ben);
      await kho.boAnh(ben);
      expect(await File(ben).exists(), isFalse);
      // Không đụng file ngoài thư mục của mình.
      await kho.boAnh(goc.path);
      expect(await goc.exists(), isTrue);
    });
  });
}
