import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/data/app_state.dart';
import 'package:theodoi_hoctap/data/models/models.dart';
import 'package:theodoi_hoctap/data/repositories/mock_repository.dart';

import 'tro_giup.dart';

/// Nạp thêm danh mục lúc chưa ai đăng nhập (như chạy SQL phía máy chủ), rồi
/// mới vào với vai trò cần thử. Nạp sau khi đăng nhập học sinh sẽ bị chính
/// luật phân quyền của mock chặn lại — đúng như trên Supabase.
Future<AppState> vaoSauKhiNap(
  VaiTro vaiTro,
  Future<void> Function(MockRepository repo) nap,
) async {
  final repo = MockRepository();
  await nap(repo);
  final s = AppState(repo);
  await repo.dangNhapThu(vaiTro);
  await cho(() => s.nguoiDung != null && !s.dangTai, moTa: 'phiên đăng nhập');
  return s;
}

void main() {
  group('Thầy cô theo trường và tỉnh', () {
    test('học sinh chỉ thấy thầy cô trên lớp của trường mình', () async {
      // Khôi học THCS Nguyễn Trãi; thêm một thầy trường khác vào danh mục.
      final s = await vaoSauKhiNap(VaiTro.hocSinh, (repo) async {
        await repo.luuTruong(const Truong(id: 'tr_khac', ten: 'THCS Kim Giang', tinhId: 't_hn'));
        await repo.luuGiaoVien(const GiaoVien(
          id: 'gv_khac',
          hoTen: 'Thầy Trường Khác',
          monId: 'm_toan',
          loai: LoaiBaiTap.trenLop,
          truongId: 'tr_khac',
        ));
      });

      final ids = s.gvChoHocSinh(LoaiBaiTap.trenLop).map((g) => g.id).toList();
      expect(ids, contains('gv_lan'));
      expect(ids, isNot(contains('gv_khac')));
      // Danh mục đầy đủ của quản trị thì vẫn có.
      expect(s.gvTheoLoai(LoaiBaiTap.trenLop).map((g) => g.id), contains('gv_khac'));
    });

    test('thầy cô trên lớp chưa gắn trường thì ai cũng thấy', () async {
      final s = await vaoSauKhiNap(VaiTro.hocSinh, (repo) async {
        await repo.luuGiaoVien(const GiaoVien(
          id: 'gv_cu',
          hoTen: 'Cô Dữ Liệu Cũ',
          monId: 'm_van',
          loai: LoaiBaiTap.trenLop,
        ));
      });
      expect(s.gvChoHocSinh(LoaiBaiTap.trenLop).map((g) => g.id), contains('gv_cu'));
    });

    test('thầy dạy thêm chung lọc theo tỉnh của trường học sinh', () async {
      final s = await vaoSauKhiNap(VaiTro.hocSinh, (repo) async {
        await repo.luuTinh(const Tinh(id: 't_hcm', ten: 'TP. Hồ Chí Minh'));
        await repo.luuGiaoVien(const GiaoVien(
          id: 'gv_ht_hcm',
          hoTen: 'Thầy Sài Gòn',
          monId: 'm_toan',
          loai: LoaiBaiTap.hocThem,
          tinhId: 't_hcm',
        ));
        await repo.luuGiaoVien(const GiaoVien(
          id: 'gv_ht_toanquoc',
          hoTen: 'Cô Dạy Online',
          monId: 'm_anh',
          loai: LoaiBaiTap.hocThem,
        ));
      });

      final ids = s.gvChoHocSinh(LoaiBaiTap.hocThem).map((g) => g.id).toList();
      expect(ids, contains('gv_ht_son')); // cùng tỉnh Hà Nội
      expect(ids, contains('gv_ht_toanquoc')); // không ghi tỉnh
      expect(ids, isNot(contains('gv_ht_hcm')));
    });
  });

  group('Thầy dạy thêm riêng', () {
    test('học sinh thấy thầy riêng của mình, không thấy của bạn', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      expect(s.hocSinhHienTai?.id, 'hs_01');
      final ids = s.gvChoHocSinh(LoaiBaiTap.hocThem).map((g) => g.id);
      expect(ids, contains('gv_ht_rieng_khoi'));
      expect(s.gvRiengCuaHs.length, 1);
    });

    test('phụ huynh thấy thầy riêng của con đang xem', () async {
      final s = await vaoVoiVaiTro(VaiTro.phuHuynh);
      expect(s.hocSinhHienTai?.id, 'hs_01');
      expect(s.gvChoHocSinh(LoaiBaiTap.hocThem).map((g) => g.id), contains('gv_ht_rieng_khoi'));

      // Chuyển sang đứa thứ hai thì không còn thấy thầy của Khôi.
      await s.chonCon(s.dsCon[1]);
      expect(s.gvChoHocSinh(LoaiBaiTap.hocThem).map((g) => g.id),
          isNot(contains('gv_ht_rieng_khoi')));
    });

    test('học sinh thêm được thầy riêng và chọn ngay được', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      final id = await s.luuGiaoVien(GiaoVien(
        id: '',
        hoTen: 'Thầy Mới',
        monId: 'm_ly',
        loai: LoaiBaiTap.hocThem,
        chuId: s.hocSinhHienTai!.id,
      ));
      expect(id, isNotEmpty);
      expect(s.gv(id)?.laRieng, isTrue);
      expect(s.gvChoHocSinh(LoaiBaiTap.hocThem).map((g) => g.id), contains(id));
      expect(s.gvRiengCuaHs.length, 2);

      await s.xoaGiaoVien(id);
      expect(s.gv(id), isNull);
    });

    test('học sinh không thêm được thầy vào danh mục chung', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      await expectLater(
        s.luuGiaoVien(const GiaoVien(
          id: '',
          hoTen: 'Thầy Lậu',
          monId: 'm_toan',
          loai: LoaiBaiTap.trenLop,
          truongId: 'tr_nguyen_trai',
        )),
        throwsA(predicate((e) => '$e'.contains('không có quyền'))),
      );
    });

    test('người lạ không thấy thầy riêng của nhà khác', () async {
      final repo = MockRepository();
      await repo.dangNhap('hong.le@gmail.com', 'matkhau123'); // mẹ của Bảo, không phải Khôi
      final ids = (await repo.taiGiaoVien()).map((g) => g.id);
      expect(ids, isNot(contains('gv_ht_rieng_khoi')));
      expect(ids, contains('gv_ht_son'));
    });
  });

  group('Danh mục của quản trị', () {
    test('thêm tỉnh, trường, môn rồi xóa — danh sách đổi theo', () async {
      final s = await vaoVoiVaiTro(VaiTro.quanTri);
      final soTinh = s.tinh.length;
      final soTruong = s.truong.length;
      final soMon = s.monHoc.length;

      await s.luuTinh(const Tinh(id: '', ten: 'Nghệ An'));
      expect(s.tinh.length, soTinh + 1);
      final na = s.tinh.firstWhere((t) => t.ten == 'Nghệ An');

      await s.luuTruong(Truong(id: '', ten: 'THCS Vinh', tinhId: na.id));
      expect(s.truongTheoTinh(na.id).map((t) => t.ten), ['THCS Vinh']);
      expect(s.truong.length, soTruong + 1);

      await s.luuMonHoc(const MonHoc(id: '', ten: 'Mỹ thuật', vietTat: ''));
      expect(s.monHoc.length, soMon + 1);

      await s.xoaTruong(s.truong.firstWhere((t) => t.ten == 'THCS Vinh').id);
      await s.xoaTinh(na.id);
      expect(s.truong.length, soTruong);
      expect(s.tinh.length, soTinh);
    });

    test('quản trị thấy cả thầy riêng của học sinh', () async {
      final s = await vaoVoiVaiTro(VaiTro.quanTri);
      expect(s.giaoVien.map((g) => g.id), contains('gv_ht_rieng_khoi'));
    });
  });

  group('Đăng ký chọn trường', () {
    test('trường hợp lệ thì gắn vào hồ sơ, id lạ thì bỏ qua', () async {
      final repo = MockRepository();
      final nd = await repo.dangKy(
        hoTen: 'Em Mới',
        email: 'moi@hocsinh.vn',
        matKhau: 'matkhau123',
        vaiTro: VaiTro.hocSinh,
        lop: '7A1',
        truongId: 'tr_nguyen_trai',
      );
      expect(nd.truongId, 'tr_nguyen_trai');

      final la = await repo.dangKy(
        hoTen: 'Em Lạ',
        email: 'la@hocsinh.vn',
        matKhau: 'matkhau123',
        vaiTro: VaiTro.hocSinh,
        truongId: 'khong-co',
      );
      expect(la.truongId, isNull);
    });

    test('tên trường tra được từ danh mục, dữ liệu cũ vẫn hiện tên gõ tay', () async {
      final s = await vaoVoiVaiTro(VaiTro.quanTri);
      final ds = await s.repo.danhSachNguoiDung();
      final khoi = ds.firstWhere((n) => n.id == 'hs_01');
      final bao = ds.firstWhere((n) => n.id == 'hs_03');
      expect(s.tenTruongCua(khoi), 'THCS Nguyễn Trãi');
      expect(khoi.truong, isNull);
      expect(s.tenTruongCua(bao), 'THCS Nguyễn Trãi');
      expect(bao.truongId, isNull);
    });
  });

  group('Chuyển đổi thầy cô', () {
    test('ghi rồi đọc lại giữ trường, tỉnh và chủ', () {
      const goc = GiaoVien(
        id: 'g1',
        hoTen: 'Cô A',
        monId: 'm_toan',
        loai: LoaiBaiTap.hocThem,
        noiDay: 'Nhà cô',
        soDienThoai: '0900',
        truongId: 'tr_x',
        tinhId: 't_y',
        chuId: 'hs_z',
      );
      final lai = GiaoVienPg.fromMap(goc.toMap());
      expect(lai.truongId, 'tr_x');
      expect(lai.tinhId, 't_y');
      expect(lai.chuId, 'hs_z');
      expect(lai.laRieng, isTrue);
    });

    test('hồ sơ mang truong_id lên xuống', () {
      const nd = NguoiDung(id: 'x', hoTen: 'X', vaiTro: VaiTro.hocSinh, truongId: 'tr_1');
      expect(nd.toMapCaNhan()['truong_id'], 'tr_1');
      expect(NguoiDungPg.fromMap(nd.toMap()).truongId, 'tr_1');
    });
  });
}
