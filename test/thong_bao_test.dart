import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/core/thong_bao/kenh_thong_bao.dart';
import 'package:theodoi_hoctap/data/app_state.dart';
import 'package:theodoi_hoctap/data/models/models.dart';
import 'package:theodoi_hoctap/data/repositories/mock_repository.dart';

import 'tro_giup.dart';

/// Kênh giả: cấp token cố định, cho test tự phát token mới và tin đến.
class _KenhGia implements KenhThongBao {
  _KenhGia({this.token = 'token-may-1'});

  String? token;
  int soLanXoa = 0;
  final _tokenMoi = StreamController<String>.broadcast();
  final _tinDen = StreamController<TinDen>.broadcast();

  @override
  Future<String?> layToken() async => token;
  @override
  Stream<String> get tokenMoi => _tokenMoi.stream;
  @override
  Stream<TinDen> get tinDen => _tinDen.stream;
  @override
  Future<void> xoaToken() async => soLanXoa++;

  void phatTokenMoi(String t) => _tokenMoi.add(t);
  void phatTin(TinDen t) => _tinDen.add(t);
}

Future<(AppState, MockRepository, _KenhGia)> vao(VaiTro vt, {String? token = 'token-may-1'}) async {
  final repo = MockRepository();
  final kenh = _KenhGia(token: token);
  final s = AppState(repo, kenhThongBao: kenh);
  await repo.dangNhapThu(vt);
  await cho(() => s.nguoiDung != null && !s.dangTai, moTa: 'phiên đăng nhập');
  return (s, repo, kenh);
}

void main() {
  group('Đăng ký máy nhận thông báo', () {
    test('đăng nhập xong thì token của máy được ghi cho đúng người', () async {
      final (s, repo, _) = await vao(VaiTro.hocSinh);
      await cho(() => repo.thietBi.isNotEmpty, moTa: 'ghi token');
      expect(repo.thietBi['token-may-1'], s.nguoiDung!.id);
    });

    test('người dùng từ chối quyền thì không ghi gì', () async {
      final (_, repo, _) = await vao(VaiTro.hocSinh, token: null);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(repo.thietBi, isEmpty);
    });

    test('FCM cấp token mới thì ghi đè lên máy chủ', () async {
      final (s, repo, kenh) = await vao(VaiTro.phuHuynh);
      await cho(() => repo.thietBi.isNotEmpty, moTa: 'ghi token');
      kenh.phatTokenMoi('token-may-2');
      await cho(() => repo.thietBi.containsKey('token-may-2'), moTa: 'token mới');
      expect(repo.thietBi['token-may-2'], s.nguoiDung!.id);
    });

    test('đăng xuất thì gỡ máy khỏi máy chủ và xóa token trên máy', () async {
      final (s, repo, kenh) = await vao(VaiTro.hocSinh);
      await cho(() => repo.thietBi.isNotEmpty, moTa: 'ghi token');
      await s.dangXuat();
      expect(repo.thietBi, isEmpty);
      expect(kenh.soLanXoa, 1);
    });

    test('đăng xuất khi chưa từng có token thì không đụng gì', () async {
      final (s, repo, kenh) = await vao(VaiTro.hocSinh, token: null);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await s.dangXuat();
      expect(repo.thietBi, isEmpty);
      expect(kenh.soLanXoa, 0);
    });
  });

  group('Tin đến lúc app đang mở', () {
    test('nạp lại dữ liệu rồi mới phát ra cho giao diện', () async {
      final (s, repo, kenh) = await vao(VaiTro.phuHuynh);
      await cho(() => repo.thietBi.isNotEmpty, moTa: 'ghi token');
      final soCu = s.baoCao.length;

      // Con gửi báo cáo từ máy khác: kho có thêm một hàng, app chưa biết.
      await repo.luuBaoCao(BaoCao(
        id: 'bc_moi',
        hocSinhId: 'hs_01',
        ngay: DateTime.now(),
        loai: LoaiBaiTap.trenLop,
        monId: 'm_toan',
        noiDung: 'Bài mới',
        trangThai: TrangThai.xong,
        taoLuc: DateTime.now(),
      ));
      expect(s.baoCao.length, soCu);

      final nhan = s.tinDen.first;
      kenh.phatTin(const TinDen(
        tieuDe: 'Nguyễn Minh Khôi vừa gửi báo cáo',
        noiDung: 'Toán · Bài mới',
        duLieu: {'loai': 'bao_cao', 'bao_cao_id': 'bc_moi'},
      ));
      final tin = await nhan.timeout(const Duration(seconds: 5));

      expect(tin.loai, 'bao_cao');
      expect(s.baoCao.length, soCu + 1);
    });

    test('chưa đăng nhập thì bỏ qua tin', () async {
      final repo = MockRepository();
      final kenh = _KenhGia();
      final s = AppState(repo, kenhThongBao: kenh);
      var soTin = 0;
      s.tinDen.listen((_) => soTin++);
      kenh.phatTin(const TinDen(tieuDe: 'x', noiDung: 'y'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(soTin, 0);
    });
  });

  group('Chế độ dùng thử', () {
    test('không đăng ký máy — không có tài khoản thật để gắn vào', () async {
      final kenh = _KenhGia();
      final s = AppState(MockRepository(), kenhThongBao: kenh);
      await s.dungThuVoiVaiTro(VaiTro.hocSinh);
      await cho(() => s.nguoiDung != null && !s.dangTai, moTa: 'phiên dùng thử');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect((s.repo as MockRepository).thietBi, isEmpty);
      await s.dangXuat();
      expect(kenh.soLanXoa, 0);
    });
  });
}
