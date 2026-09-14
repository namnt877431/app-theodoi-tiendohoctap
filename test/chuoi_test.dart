import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/core/huy_hieu/chuoi.dart';
import 'package:theodoi_hoctap/data/app_state.dart';
import 'package:theodoi_hoctap/data/models/models.dart';

import 'tro_giup.dart';

// Tuần mốc: Thứ Hai 2026-09-07 … Chủ nhật 2026-09-13.
final _t2 = DateTime(2026, 9, 7);
DateTime _n(int lech) => _t2.add(Duration(days: lech));

BaoCao _bc(DateTime ngay, {TrangThai tt = TrangThai.xong}) => BaoCao(
      id: 'bc_${ngay.day}_${tt.name}',
      hocSinhId: 'hs',
      ngay: ngay,
      loai: LoaiBaiTap.trenLop,
      monId: 'm_toan',
      noiDung: '',
      trangThai: tt,
      taoLuc: ngay.add(const Duration(hours: 20)),
    );

const _luatNha = LuatChuoi(thuNghi: {DateTime.sunday}, veMoiTuan: 1);

void main() {
  group('Luật thuần', () {
    test('không báo cáo thì chuỗi 0', () {
      final kq = demChuoi(const [], homNay: _n(3));
      expect(kq.hienTai, 0);
      expect(kq.daiNhat, 0);
    });

    test('ngày trống nào cũng đứt; hôm nay chưa báo thì chưa đứt', () {
      // T2, T3 xong; T4 trống; T5 xong; hôm nay T6 chưa có gì.
      final kq = demChuoi([_bc(_n(0)), _bc(_n(1)), _bc(_n(3))], homNay: _n(4));
      expect(kq.hienTai, 1);
      expect(kq.daiNhat, 2);
    });

    test('bài chưa xong vẫn tính — có báo cáo là được, không cần làm hết', () {
      // Bài để gần ngày mới làm là chuyện bình thường; chuỗi đo thói quen kể
      // lại, không đo việc xong bài.
      final kq = demChuoi(
        [_bc(_n(0)), _bc(_n(1), tt: TrangThai.dangLam), _bc(_n(2), tt: TrangThai.chuaLam)],
        homNay: _n(2),
      );
      expect(kq.hienTai, 3);
      expect(kq.daiNhat, 3);
    });

    test('báo cáo ghi ngày tương lai bỏ qua', () {
      final kq = demChuoi([_bc(_n(0)), _bc(_n(5))], homNay: _n(0));
      expect(kq.hienTai, 1);
    });
  });

  group('Ngày nghỉ theo thời khóa biểu', () {
    test('Chủ nhật trống không đứt, không tính', () {
      // T6 xong, T7 xong, CN trống, T2 tuần sau xong.
      final kq = demChuoi([_bc(_n(4)), _bc(_n(5)), _bc(_n(7))], luat: _luatNha, homNay: _n(7));
      expect(kq.hienTai, 3);
      expect(kq.veDaDungTuanNay, 0, reason: 'ngày nghỉ không tốn vé');
    });

    test('Chủ nhật có báo cáo thì vẫn tính như ngày thường', () {
      final kq = demChuoi([_bc(_n(5)), _bc(_n(6)), _bc(_n(7))], luat: _luatNha, homNay: _n(7));
      expect(kq.hienTai, 3);
    });
  });

  group('Vé nghỉ', () {
    test('bỏ một ngày học trong tuần thì xé vé, chuỗi giữ nguyên', () {
      // T2 xong, T3 trống, T4 xong, T5 xong.
      final kq = demChuoi([_bc(_n(0)), _bc(_n(2)), _bc(_n(3))], luat: _luatNha, homNay: _n(3));
      expect(kq.hienTai, 3);
      expect(kq.veDaDungTuanNay, 1);
      expect(kq.veConLaiTuanNay, 0);
      expect(kq.ngayDungVeGanNhat, _n(1));
    });

    test('bỏ hai ngày trong cùng tuần thì ngày thứ hai làm đứt', () {
      // T2 xong, T3 trống (vé), T4 xong, T5 trống (hết vé), T6 xong.
      final kq = demChuoi([_bc(_n(0)), _bc(_n(2)), _bc(_n(4))], luat: _luatNha, homNay: _n(4));
      expect(kq.hienTai, 1);
      expect(kq.daiNhat, 2);
    });

    test('sang tuần mới có vé mới', () {
      // T3 trống tuần này, T3 trống tuần sau — mỗi tuần một vé, chuỗi liền.
      final ds = [
        for (var i = 0; i < 12; i++)
          if (i != 1 && i != 6 && i != 8) _bc(_n(i)),
      ];
      final kq = demChuoi(ds, luat: _luatNha, homNay: _n(11));
      expect(kq.hienTai, 9, reason: '12 ngày trừ 1 CN trừ 2 ngày xé vé');
      expect(kq.veDaDungTuanNay, 1);
      expect(kq.veConLaiTuanNay, 0);
    });

    test('không có chuỗi thì không xé vé', () {
      // T2 trống, T3 trống, T4 xong: vé tuần này còn nguyên.
      final kq = demChuoi([_bc(_n(2))], luat: _luatNha, homNay: _n(2));
      expect(kq.hienTai, 1);
      expect(kq.veConLaiTuanNay, 1);
    });

    test('hôm nay trống không xé vé — ngày chưa hết', () {
      final kq = demChuoi([_bc(_n(0)), _bc(_n(1))], luat: _luatNha, homNay: _n(2));
      expect(kq.hienTai, 2);
      expect(kq.veConLaiTuanNay, 1);
    });
  });

  group('Đếm từ một ngày', () {
    test('tuNgay cắt bỏ phần trước, dùng cho phần thưởng treo giữa chừng', () {
      final ds = [for (var i = 0; i < 6; i++) _bc(_n(i))];
      final kq = demChuoi(ds, luat: _luatNha, tuNgay: _n(3), homNay: _n(5));
      expect(kq.hienTai, 3);
      expect(kq.daiNhat, 3);
    });
  });

  group('Tiến độ phần thưởng', () {
    PhanThuong pt({required int moc, required bool lapLai, int soLanTrao = 0}) => PhanThuong(
          id: 'p',
          hocSinhId: 'hs',
          taoBoi: 'ph',
          moc: moc,
          ten: 'Kem',
          tuNgay: _t2,
          taoLuc: _t2,
          lapLai: lapLai,
          soLanTrao: soLanTrao,
        );
    KetQuaChuoi kq(List<int> cacChuoi) => KetQuaChuoi(
          hienTai: cacChuoi.isEmpty ? 0 : cacChuoi.last,
          daiNhat: cacChuoi.isEmpty ? 0 : cacChuoi.reduce((a, b) => a > b ? a : b),
          veDaDungTuanNay: 0,
          veConLaiTuanNay: 1,
          cacChuoi: cacChuoi,
        );

    test('lặp lại: mỗi chuỗi góp dài chia mốc, bước tới lần kế là phần dư', () {
      // Chuỗi 15 rồi đứt, chuỗi mới 10 đang chạy: 2 + 1 = 3 lần, dư 3.
      final td = AppState.tinhTienDo(pt(moc: 7, lapLai: true), kq([15, 10]));
      expect(td.soLanDat, 3);
      expect(td.hienTai, 3);
      expect(td.conLai, 4);
      expect(td.dat, isTrue);
      expect(td.conNo, 3);
    });

    test('lặp lại: trao rồi thì hết nợ, thanh tiến độ về phần dư', () {
      final td = AppState.tinhTienDo(pt(moc: 7, lapLai: true, soLanTrao: 3), kq([15, 10]));
      expect(td.dat, isFalse);
      expect(td.conNo, 0);
      expect(td.tiLe, closeTo(3 / 7, 1e-9));
    });

    test('một lần: đạt khi có chuỗi chạm mốc, kể cả đã đứt; không cộng dồn', () {
      final td = AppState.tinhTienDo(pt(moc: 7, lapLai: false), kq([15, 2]));
      expect(td.soLanDat, 1);
      expect(td.dat, isTrue);
      expect(td.tiLe, 1);
      final chua = AppState.tinhTienDo(pt(moc: 7, lapLai: false), kq([5, 6]));
      expect(chua.dat, isFalse);
      expect(chua.hienTai, 6);
      expect(chua.conLai, 1);
    });

    test('demChuoi liệt kê từng chuỗi, chuỗi đang chạy ở cuối', () {
      // T2,T3 · T4,T5 trống (một vé, ngày thứ hai đứt) · T6,T7 · CN nghỉ · T2 sau.
      final ds = [
        _bc(_n(0)), _bc(_n(1)),
        _bc(_n(4)), _bc(_n(5)),
        _bc(_n(7)),
      ];
      final r = demChuoi(ds, luat: _luatNha, homNay: _n(7));
      expect(r.cacChuoi, [2, 3]);
      expect(r.hienTai, 3);
    });
  });

  group('AppState', () {
    test('luật chuỗi lấy ngày nghỉ từ thời khóa biểu — Khôi học thứ Hai tới thứ Bảy', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      expect(s.luatChuoi.thuNghi, {DateTime.sunday});
      expect(s.luatChuoi.veMoiTuan, 1);
    });

    test('phần thưởng mẫu: hai quà đã đạt xếp đầu (chuỗi trước điểm), Lego mốc 30 còn xa', () async {
      final s = await vaoVoiVaiTro(VaiTro.hocSinh);
      final ds = s.tienDoPhanThuong;
      // Khôi báo cáo bảy ngày liền (có hôm bài còn dang dở — vẫn tính) → quà kem
      // mốc 7 nợ một lần; 8,5 giữa kì Toán → quà "từ 8 trở lên" đạt.
      expect(s.chuoi.hienTai, 7);
      expect(ds.map((t) => t.phanThuong.moc), [7, 1, 30]);
      expect(ds[0].phanThuong.loai, LoaiPhanThuong.chuoi);
      expect(ds[0].soLanDat, 1);
      expect(ds[1].phanThuong.loai, LoaiPhanThuong.diem);
      expect(ds[1].baiDat.single.diem, 8.5);
      expect(ds.take(2).every((t) => t.dat), isTrue);
      expect(ds.last.dat, isFalse);
      expect(ds.every((t) => !t.phanThuong.xongHan), isTrue);
    });

    test('phụ huynh treo quà một lần, trao, treo lại, xóa; học sinh thấy y như vậy', () async {
      final ph = await vaoVoiVaiTro(VaiTro.phuHuynh);
      await ph.treoPhanThuong(moc: 3, ten: 'Đi công viên', lapLai: false);
      final moi = ph.phanThuong.firstWhere((p) => p.ten == 'Đi công viên');
      expect(moi.taoBoi, ph.nguoiDung!.id);
      expect(moi.hocSinhId, ph.hocSinhHienTai!.id);
      expect(moi.xongHan, isFalse);

      await ph.traoPhanThuong(moi);
      final daTrao = ph.phanThuong.firstWhere((p) => p.id == moi.id);
      expect(daTrao.xongHan, isTrue);
      expect(daTrao.soLanTrao, 1);
      // Đã trao xong hẳn thì xếp cuối.
      expect(ph.tienDoPhanThuong.last.phanThuong.id, moi.id);

      await ph.treoLaiPhanThuong(daTrao);
      final lai = ph.phanThuong.firstWhere((p) => p.id == moi.id);
      expect(lai.xongHan, isFalse);
      expect(lai.soLanTrao, 0);
      expect(lai.tuNgay.isAfter(moi.tuNgay.subtract(const Duration(seconds: 1))), isTrue);

      await ph.xoaPhanThuong(lai);
      expect(ph.phanThuong.any((p) => p.id == moi.id), isFalse);
    });
  });
}
