import '../models/models.dart';

DateTime _ngay(int lui) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day).subtract(Duration(days: lui));
}

abstract final class Seed {
  static const monHoc = <MonHoc>[
    MonHoc(id: 'm_toan', ten: 'Toán', vietTat: 'Toán'),
    MonHoc(id: 'm_van', ten: 'Ngữ văn', vietTat: 'Văn'),
    MonHoc(id: 'm_anh', ten: 'Tiếng Anh', vietTat: 'Anh'),
    MonHoc(id: 'm_ly', ten: 'Vật lí', vietTat: 'Lí'),
    MonHoc(id: 'm_hoa', ten: 'Hóa học', vietTat: 'Hóa'),
    MonHoc(id: 'm_sinh', ten: 'Sinh học', vietTat: 'Sinh'),
    MonHoc(id: 'm_su', ten: 'Lịch sử', vietTat: 'Sử'),
    MonHoc(id: 'm_dia', ten: 'Địa lí', vietTat: 'Địa'),
    MonHoc(id: 'm_gdcd', ten: 'Giáo dục công dân', vietTat: 'GDCD'),
    MonHoc(id: 'm_tin', ten: 'Tin học', vietTat: 'Tin'),
    MonHoc(id: 'm_td', ten: 'Thể dục', vietTat: 'TD'),
    MonHoc(id: 'm_cn', ten: 'Công nghệ', vietTat: 'CN'),
  ];

  static const giaoVien = <GiaoVien>[
    GiaoVien(id: 'gv_lan', hoTen: 'Cô Nguyễn Thị Lan', monId: 'm_toan', loai: LoaiBaiTap.trenLop, noiDay: 'Lớp 9A2'),
    GiaoVien(id: 'gv_hoa', hoTen: 'Cô Trần Thanh Hòa', monId: 'm_van', loai: LoaiBaiTap.trenLop, noiDay: 'Lớp 9A2'),
    GiaoVien(id: 'gv_minh', hoTen: 'Thầy Lê Quang Minh', monId: 'm_anh', loai: LoaiBaiTap.trenLop, noiDay: 'Lớp 9A2'),
    GiaoVien(id: 'gv_tuan', hoTen: 'Thầy Phạm Anh Tuấn', monId: 'm_ly', loai: LoaiBaiTap.trenLop, noiDay: 'Lớp 9A2'),
    GiaoVien(id: 'gv_thuy', hoTen: 'Cô Đỗ Bích Thủy', monId: 'm_hoa', loai: LoaiBaiTap.trenLop, noiDay: 'Lớp 9A2'),
    GiaoVien(id: 'gv_ht_son', hoTen: 'Thầy Vũ Ngọc Sơn', monId: 'm_toan', loai: LoaiBaiTap.hocThem, noiDay: 'Trung tâm Trí Đức', soDienThoai: '0912 334 556'),
    GiaoVien(id: 'gv_ht_mai', hoTen: 'Cô Hoàng Thị Mai', monId: 'm_anh', loai: LoaiBaiTap.hocThem, noiDay: 'Nhà cô — ngõ 128 Kim Giang', soDienThoai: '0983 771 202'),
    GiaoVien(id: 'gv_ht_dung', hoTen: 'Thầy Bùi Tiến Dũng', monId: 'm_ly', loai: LoaiBaiTap.hocThem, noiDay: 'Trung tâm Trí Đức', soDienThoai: '0977 240 118'),
  ];

  static const nguoiDung = <NguoiDung>[
    NguoiDung(id: 'ph_01', hoTen: 'Nguyễn Văn Hùng', vaiTro: VaiTro.phuHuynh, email: 'hung.nguyen@gmail.com', soDienThoai: '0904 128 337', conIds: ['hs_01', 'hs_02']),
    NguoiDung(id: 'hs_01', hoTen: 'Nguyễn Minh Khôi', vaiTro: VaiTro.hocSinh, lop: '9A2', truong: 'THCS Nguyễn Trãi', email: 'khoi.nguyen@hocsinh.vn'),
    NguoiDung(id: 'hs_02', hoTen: 'Nguyễn Bảo Ngọc', vaiTro: VaiTro.hocSinh, lop: '6A1', truong: 'THCS Nguyễn Trãi', email: 'ngoc.nguyen@hocsinh.vn'),
    NguoiDung(id: 'qt_01', hoTen: 'Trần Quản Trị', vaiTro: VaiTro.quanTri, email: 'admin@solienlac.vn'),
    NguoiDung(id: 'ph_02', hoTen: 'Lê Thị Hồng', vaiTro: VaiTro.phuHuynh, email: 'hong.le@gmail.com', soDienThoai: '0918 442 019', conIds: ['hs_03']),
    NguoiDung(id: 'hs_03', hoTen: 'Lê Gia Bảo', vaiTro: VaiTro.hocSinh, lop: '8A4', truong: 'THCS Nguyễn Trãi'),
    NguoiDung(id: 'hs_04', hoTen: 'Phạm Thùy Linh', vaiTro: VaiTro.hocSinh, lop: '9A2', truong: 'THCS Nguyễn Trãi', email: 'linh.pham@hocsinh.vn', hoatDong: false),
  ];

  /// Thời khóa biểu chính khóa của Khôi (9A2) cộng bốn buổi học thêm.
  static List<TietHoc> get tietHoc {
    final ds = <TietHoc>[];
    var i = 0;
    void them(int thu, int tiet, Buoi buoi, String mon, String? gv,
        {LoaiBaiTap loai = LoaiBaiTap.trenLop, String? phong, String? bd, String? kt}) {
      ds.add(TietHoc(
        id: 'tkb_${i++}',
        hocSinhId: 'hs_01',
        thu: thu,
        tiet: tiet,
        buoi: buoi,
        monId: mon,
        loai: loai,
        giaoVienId: gv,
        phong: phong,
        batDau: bd,
        ketThuc: kt,
      ));
    }

    const gio = [
      ['07:15', '08:00'],
      ['08:05', '08:50'],
      ['09:05', '09:50'],
      ['09:55', '10:40'],
      ['10:45', '11:30'],
    ];
    void ngayHoc(int thu, List<String> mon, List<String?> gv) {
      for (var t = 0; t < mon.length; t++) {
        them(thu, t + 1, Buoi.sang, mon[t], gv[t], phong: 'P.204', bd: gio[t][0], kt: gio[t][1]);
      }
    }

    ngayHoc(2, ['m_toan', 'm_van', 'm_van', 'm_anh', 'm_su'], ['gv_lan', 'gv_hoa', 'gv_hoa', 'gv_minh', null]);
    ngayHoc(3, ['m_ly', 'm_toan', 'm_hoa', 'm_sinh', 'm_gdcd'], ['gv_tuan', 'gv_lan', 'gv_thuy', null, null]);
    ngayHoc(4, ['m_van', 'm_anh', 'm_toan', 'm_tin', 'm_td'], ['gv_hoa', 'gv_minh', 'gv_lan', null, null]);
    ngayHoc(5, ['m_toan', 'm_ly', 'm_dia', 'm_van', 'm_anh'], ['gv_lan', 'gv_tuan', null, 'gv_hoa', 'gv_minh']);
    ngayHoc(6, ['m_hoa', 'm_sinh', 'm_toan', 'm_su', 'm_cn'], ['gv_thuy', null, 'gv_lan', null, null]);
    ngayHoc(7, ['m_van', 'm_anh', 'm_td', 'm_gdcd'], ['gv_hoa', 'gv_minh', null, null]);

    them(3, 1, Buoi.toi, 'm_toan', 'gv_ht_son', loai: LoaiBaiTap.hocThem, phong: 'Trí Đức', bd: '18:30', kt: '20:00');
    them(5, 1, Buoi.toi, 'm_toan', 'gv_ht_son', loai: LoaiBaiTap.hocThem, phong: 'Trí Đức', bd: '18:30', kt: '20:00');
    them(4, 1, Buoi.toi, 'm_anh', 'gv_ht_mai', loai: LoaiBaiTap.hocThem, phong: 'Nhà cô Mai', bd: '19:00', kt: '20:30');
    them(7, 1, Buoi.chieu, 'm_ly', 'gv_ht_dung', loai: LoaiBaiTap.hocThem, phong: 'Trí Đức', bd: '14:00', kt: '15:30');

    return ds;
  }

  static List<BaoCao> get baoCao {
    var i = 0;
    BaoCao b(int lui, LoaiBaiTap loai, String mon, String? gv, String noiDung, TrangThai tt,
        {int? phut, List<String> anh = const [], String? nhanXet}) {
      final n = i++;
      return BaoCao(
        id: 'bc_$n',
        hocSinhId: 'hs_01',
        ngay: _ngay(lui),
        loai: loai,
        monId: mon,
        giaoVienId: gv,
        noiDung: noiDung,
        trangThai: tt,
        soPhut: phut,
        anh: anh,
        nhanXetPhuHuynh: nhanXet,
        phuHuynhDaXem: lui > 0,
        taoLuc: _ngay(lui).add(Duration(hours: 19 + (n % 3), minutes: (n * 7) % 60)),
      );
    }

    return [
      b(0, LoaiBaiTap.trenLop, 'm_toan', 'gv_lan', 'Làm bài 12, 13, 14 trang 47 — hệ thức lượng trong tam giác vuông. Bài 14 con chưa ra, để mai hỏi lại cô.', TrangThai.dangLam, phut: 45, anh: ['demo:toan_1']),
      b(0, LoaiBaiTap.trenLop, 'm_van', 'gv_hoa', 'Soạn bài "Chuyện người con gái Nam Xương", trả lời 5 câu hỏi đọc hiểu trong sách giáo khoa.', TrangThai.xong, phut: 40),
      b(0, LoaiBaiTap.trenLop, 'm_anh', 'gv_minh', 'Học 20 từ vựng Unit 4 và làm Workbook trang 28–29.', TrangThai.chuaLam),
      b(0, LoaiBaiTap.hocThem, 'm_toan', 'gv_ht_son', 'Thầy Sơn giao đề số 7 — 20 câu trắc nghiệm hàm số. Con làm đúng 16/20, sai phần đồ thị.', TrangThai.xong, phut: 60, anh: ['demo:toan_2', 'demo:toan_3']),
      b(1, LoaiBaiTap.trenLop, 'm_ly', 'gv_tuan', 'Bài tập về định luật Ôm cho toàn mạch, bài 3–7 sách bài tập.', TrangThai.xong, phut: 35, nhanXet: 'Con làm tốt lắm, giữ nhịp này nhé.'),
      b(1, LoaiBaiTap.trenLop, 'm_hoa', 'gv_thuy', 'Hoàn thành phiếu bài tập về dãy hoạt động hóa học của kim loại.', TrangThai.xong, phut: 30),
      b(1, LoaiBaiTap.hocThem, 'm_anh', 'gv_ht_mai', 'Cô Mai chữa đề thi thử số 3, về nhà viết lại bài luận 150 từ chủ đề Environment.', TrangThai.dangLam, phut: 25),
      b(2, LoaiBaiTap.trenLop, 'm_toan', 'gv_lan', 'Ôn tập chương I, làm đề cương 25 câu.', TrangThai.xong, phut: 70),
      b(2, LoaiBaiTap.trenLop, 'm_sinh', null, 'Vẽ sơ đồ tư duy chương Di truyền học.', TrangThai.xong, phut: 45, anh: ['demo:sinh_1']),
      b(2, LoaiBaiTap.hocThem, 'm_ly', 'gv_ht_dung', 'Thầy Dũng giao 10 bài về mạch điện hỗn hợp.', TrangThai.chuaLam),
      b(3, LoaiBaiTap.trenLop, 'm_van', 'gv_hoa', 'Viết đoạn văn 200 chữ nêu cảm nhận về nhân vật Vũ Nương.', TrangThai.xong, phut: 50),
      b(3, LoaiBaiTap.trenLop, 'm_su', null, 'Đọc trước bài 9 và lập niên biểu các sự kiện chính.', TrangThai.xong, phut: 20),
      b(4, LoaiBaiTap.hocThem, 'm_toan', 'gv_ht_son', 'Đề số 6 — phần hình học không gian. Con sai 5 câu, thầy dặn làm lại.', TrangThai.xong, phut: 65),
      b(4, LoaiBaiTap.trenLop, 'm_anh', 'gv_minh', 'Chuẩn bị thuyết trình nhóm chủ đề "My hometown".', TrangThai.xong, phut: 40),
      b(5, LoaiBaiTap.trenLop, 'm_toan', 'gv_lan', 'Bài 8, 9, 10 trang 41.', TrangThai.xong, phut: 40),
      b(6, LoaiBaiTap.trenLop, 'm_hoa', 'gv_thuy', 'Học thuộc hóa trị và làm bài 2–5 sách bài tập.', TrangThai.dangLam, phut: 25),
    ];
  }

  static List<NhacNho> get nhacNho => [
        NhacNho(
          id: 'nn_01',
          tuId: 'ph_01',
          denId: 'hs_01',
          noiDung: 'Tiếng Anh Unit 4 con chưa đụng tới. 8 giờ tối nay làm xong nhé, mai cô kiểm tra từ vựng.',
          taoLuc: DateTime.now().subtract(const Duration(hours: 2)),
          hanLuc: DateTime.now().add(const Duration(hours: 3)),
        ),
        NhacNho(
          id: 'nn_02',
          tuId: 'ph_01',
          denId: 'hs_01',
          noiDung: 'Bài thầy Dũng giao hôm kia vẫn còn đó. Chiều nay tranh thủ làm trước khi đi học thêm.',
          taoLuc: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
          daDoc: true,
        ),
        NhacNho(
          id: 'nn_03',
          tuId: 'ph_01',
          denId: 'hs_01',
          noiDung: 'Nhớ chụp ảnh bài Toán gửi bố xem với.',
          taoLuc: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
          daDoc: true,
        ),
      ];
}
