import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/data/models/models.dart';

/// Giả lập kiểu Timestamp của Firestore: `ngayTu` đọc nó qua `dynamic` nên
/// bất cứ thứ gì có `toDate()` cũng phải chạy được.
class _TimestampGia {
  const _TimestampGia(this._d);
  final DateTime _d;
  DateTime toDate() => _d;
}

void main() {
  group('Đọc ngày từ Firestore', () {
    final moc = DateTime(2026, 9, 10, 21, 30);

    test('nhận được Timestamp, DateTime, chuỗi ISO và mili-giây', () {
      expect(ngayTu(_TimestampGia(moc)), moc);
      expect(ngayTu(moc), moc);
      expect(ngayTu(moc.toIso8601String()), moc);
      expect(ngayTu(moc.millisecondsSinceEpoch), moc);
      expect(ngayTu(null), isNull);
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

      final lai = BaoCaoFs.fromMap('bc_1', goc.toMap());

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

    test('khóa ngày dùng để lọc có dạng yyyy-MM-dd', () {
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
      expect(bc.khoaNgay, '2026-03-05');
    });

    test('giá trị enum lạ trong dữ liệu cũ rơi về mặc định thay vì làm sập app', () {
      final lai = BaoCaoFs.fromMap('bc_2', {
        'hocSinhId': 'hs_01',
        'loai': 'mot_loai_khong_con_ton_tai',
        'trangThai': null,
        'monId': 'm_toan',
        'noiDung': 'x',
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
      final lai = NguoiDungFs.fromMap('ph_01', goc.toMap());

      expect(lai.vaiTro, VaiTro.phuHuynh);
      expect(lai.conIds, ['hs_01', 'hs_02']);
      expect(lai.hoatDong, isTrue);
      expect(lai.chuCaiDau, 'NH');
    });
  });
}
