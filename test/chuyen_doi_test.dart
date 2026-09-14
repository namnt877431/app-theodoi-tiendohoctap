import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/data/models/models.dart';

void main() {
  group('Đọc ngày từ Postgres', () {
    final moc = DateTime(2026, 9, 10, 21, 30);

    test('nhận được chuỗi ISO, DateTime và mili-giây', () {
      expect(ngayTu(moc), moc);
      expect(ngayTu(moc.toIso8601String()), moc);
      expect(ngayTu(moc.millisecondsSinceEpoch), moc);
      expect(ngayTu(null), isNull);
    });

    test('giờ UTC máy chủ trả về đổi sang giờ máy, không hiện thẳng', () {
      // Postgres trả "…+00:00"; 21:30 giờ máy phải vẫn là 21:30 sau khi đọc.
      final utc = moc.toUtc();
      final chuoi = utc.toIso8601String().replaceFirst('Z', '+00:00');
      final ra = ngayTu(chuoi)!;
      expect(ra.isUtc, isFalse);
      expect(ra, moc);
      expect(ra.hour, 21);
    });

    test('cột date không có múi giờ thì ra đúng ngày, nửa đêm giờ máy', () {
      final ra = ngayTu('2026-09-10')!;
      expect(ra, DateTime(2026, 9, 10));
    });

    test('gửi giờ lên luôn kèm múi giờ', () {
      expect(gioIso(moc), endsWith('Z'));
      expect(DateTime.parse(gioIso(moc)).toLocal(), moc);
    });
  });

  group('Chuyển đổi báo cáo', () {
    test('ghi rồi đọc lại thì giữ nguyên mọi trường', () {
      final goc = BaoCao(
        id: 'bc_1',
        hocSinhId: 'hs_01',
        ngay: DateTime(2026, 9, 10),
        loai: LoaiBaiTap.hocThem,
        monId: 'm_toan',
        giaoVienId: 'gv_ht_son',
        noiDung: 'Đề số 7, làm đúng 16/20',
        trangThai: TrangThai.dangLam,
        anh: const ['https://vi.du/anh1.jpg'],
        soPhut: 60,
        nhanXetPhuHuynh: 'Cố lên con',
        taoLuc: DateTime(2026, 9, 10, 21, 0),
      );

      final lai = BaoCaoPg.fromMap(goc.toMap()..['tao_luc'] = goc.taoLuc.toIso8601String());

      expect(lai.hocSinhId, goc.hocSinhId);
      expect(lai.loai, goc.loai);
      expect(lai.monId, goc.monId);
      expect(lai.giaoVienId, goc.giaoVienId);
      expect(lai.noiDung, goc.noiDung);
      expect(lai.trangThai, goc.trangThai);
      expect(lai.anh, goc.anh);
      expect(lai.soPhut, goc.soPhut);
      expect(lai.nhanXetPhuHuynh, goc.nhanXetPhuHuynh);
      expect(lai.ngay, goc.ngay);
    });

    test('cột date gửi lên đúng dạng yyyy-MM-dd', () {
      final bc = BaoCao(
        id: 'x',
        hocSinhId: 'hs_01',
        ngay: DateTime(2026, 3, 5),
        loai: LoaiBaiTap.trenLop,
        monId: 'm_van',
        noiDung: '',
        trangThai: TrangThai.xong,
        taoLuc: DateTime(2026, 3, 5),
      );
      expect(bc.toMap()['ngay'], '2026-03-05');
    });

    test('giá trị enum lạ trong dữ liệu cũ rơi về mặc định thay vì làm sập app', () {
      final lai = BaoCaoPg.fromMap({
        'hoc_sinh_id': 'hs_01',
        'loai': 'mot_loai_khong_con_ton_tai',
        'trang_thai': null,
        'mon_id': 'm_toan',
        'noi_dung': 'x',
      });

      expect(lai.loai, LoaiBaiTap.trenLop);
      expect(lai.trangThai, TrangThai.chuaLam);
    });
  });

  group('Chuyển đổi người dùng', () {
    test('giữ nguyên vai trò và danh sách con', () {
      final goc = const NguoiDung(
        id: 'ph_01',
        hoTen: 'Nguyễn Văn Hùng',
        vaiTro: VaiTro.phuHuynh,
        email: 'hung@gmail.com',
        conIds: ['hs_01', 'hs_02'],
      );
      final lai = NguoiDungPg.fromMap(goc.toMap(), conIds: goc.conIds);

      expect(lai.vaiTro, VaiTro.phuHuynh);
      expect(lai.conIds, ['hs_01', 'hs_02']);
      expect(lai.hoatDong, isTrue);
      expect(lai.chuCaiDau, 'NH');
    });
  });
}
