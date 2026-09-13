import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/data/app_state.dart';
import 'package:theodoi_hoctap/data/models/models.dart';
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
    test('chỉ bài lớn, đúng môn, đúng kì, đủ điểm, từ ngày treo', () {
      final q = _qua(mon: 'm_toan', ki: LoaiKiemTra.giuaKi, diem: 8);
      expect(q.khopDiem(_d('m_toan', LoaiKiemTra.giuaKi, 8)), isTrue);
      expect(q.khopDiem(_d('m_toan', LoaiKiemTra.giuaKi, 7.75)), isFalse, reason: 'thiếu điểm');
      expect(q.khopDiem(_d('m_toan', LoaiKiemTra.cuoiKi, 9)), isFalse, reason: 'sai kì');
      expect(q.khopDiem(_d('m_van', LoaiKiemTra.giuaKi, 9)), isFalse, reason: 'sai môn');
      expect(q.khopDiem(_d('m_toan', LoaiKiemTra.thuongXuyen, 10)), isFalse, reason: 'bài nhỏ');
      expect(q.khopDiem(_d('m_toan', LoaiKiemTra.giuaKi, 9, lui: 40)), isFalse, reason: 'trước ngày treo');
    });

    test('môn và kì bỏ trống là môn nào, kì nào cũng được; thường xuyên vẫn không', () {
      final q = _qua(diem: 9);
      expect(q.khopDiem(_d('m_van', LoaiKiemTra.cuoiKi, 9)), isTrue);
      expect(q.khopDiem(_d('m_anh', LoaiKiemTra.giuaKi, 9.5)), isTrue);
      expect(q.khopDiem(_d('m_anh', LoaiKiemTra.thuongXuyen, 10)), isFalse);
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
    test('thường xuyên hệ số 1, giữa kì 2, cuối kì 3, chia số bài thường xuyên + 5', () {
      final tb = diemTrungBinh([
        _d('m_toan', LoaiKiemTra.thuongXuyen, 8),
        _d('m_toan', LoaiKiemTra.thuongXuyen, 9),
        _d('m_toan', LoaiKiemTra.giuaKi, 7),
        _d('m_toan', LoaiKiemTra.cuoiKi, 8),
      ]);
      // (8 + 9 + 2·7 + 3·8) / (2 + 5) = 55 / 7
      expect(tb, closeTo(55 / 7, 1e-9));
    });

    test('thiếu giữa kì hay cuối kì thì chưa tính', () {
      expect(diemTrungBinh([_d('m_toan', LoaiKiemTra.giuaKi, 7)]), isNull);
      expect(diemTrungBinh([_d('m_toan', LoaiKiemTra.thuongXuyen, 7)]), isNull);
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
      await hs.luuDiem(moi.copyWith(diem: 9.5, ghiChu: () => 'Cô chấm lại'));
      final sua = hs.diemThi.firstWhere((d) => d.id == moi.id);
      expect(sua.diem, 9.5);
      expect(sua.ghiChu, 'Cô chấm lại');

      await hs.xoaDiem(sua);
      expect(hs.diemThi.any((d) => d.id == moi.id), isFalse);
    });
  });
}
