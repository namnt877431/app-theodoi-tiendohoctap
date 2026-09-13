import '../models/models.dart';

DateTime _ngay(int lui) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day).subtract(Duration(days: lui));
}

abstract final class Seed {
  static const tinh = <Tinh>[
    Tinh(id: 't_hn', ten: 'Hà Nội'),
  ];

  static const truong = <Truong>[
    Truong(id: 'tr_nguyen_trai', ten: 'THCS Nguyễn Trãi', tinhId: 't_hn'),
  ];

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
    GiaoVien(id: 'gv_lan', hoTen: 'Cô Nguyễn Thị Lan', monId: 'm_toan', loai: LoaiBaiTap.trenLop, noiDay: 'Lớp 9A2', truongId: 'tr_nguyen_trai'),
    GiaoVien(id: 'gv_hoa', hoTen: 'Cô Trần Thanh Hòa', monId: 'm_van', loai: LoaiBaiTap.trenLop, noiDay: 'Lớp 9A2', truongId: 'tr_nguyen_trai'),
    GiaoVien(id: 'gv_minh', hoTen: 'Thầy Lê Quang Minh', monId: 'm_anh', loai: LoaiBaiTap.trenLop, noiDay: 'Lớp 9A2', truongId: 'tr_nguyen_trai'),
    GiaoVien(id: 'gv_tuan', hoTen: 'Thầy Phạm Anh Tuấn', monId: 'm_ly', loai: LoaiBaiTap.trenLop, noiDay: 'Lớp 9A2', truongId: 'tr_nguyen_trai'),
    GiaoVien(id: 'gv_thuy', hoTen: 'Cô Đỗ Bích Thủy', monId: 'm_hoa', loai: LoaiBaiTap.trenLop, noiDay: 'Lớp 9A2', truongId: 'tr_nguyen_trai'),
    GiaoVien(id: 'gv_ht_son', hoTen: 'Thầy Vũ Ngọc Sơn', monId: 'm_toan', loai: LoaiBaiTap.hocThem, noiDay: 'Trung tâm Trí Đức', soDienThoai: '0912 334 556', tinhId: 't_hn'),
    GiaoVien(id: 'gv_ht_mai', hoTen: 'Cô Hoàng Thị Mai', monId: 'm_anh', loai: LoaiBaiTap.hocThem, noiDay: 'Nhà cô — ngõ 128 Kim Giang', soDienThoai: '0983 771 202', tinhId: 't_hn'),
    GiaoVien(id: 'gv_ht_dung', hoTen: 'Thầy Bùi Tiến Dũng', monId: 'm_ly', loai: LoaiBaiTap.hocThem, noiDay: 'Trung tâm Trí Đức', soDienThoai: '0977 240 118', tinhId: 't_hn'),
    // Thầy dạy thêm riêng của Khôi — chỉ nhà Khôi và quản trị thấy.
    GiaoVien(id: 'gv_ht_rieng_khoi', hoTen: 'Cô Phan Thu Hà', monId: 'm_van', loai: LoaiBaiTap.hocThem, noiDay: 'Nhà cô — Thanh Xuân', chuId: 'hs_01'),
  ];

  /// Vài mục danh mục bài học để xem giao diện: lớp 9 cho Khôi (9A2), lớp 8
  /// cho Bảo (8A4). Dữ liệu thật của lớp 8 nằm ở supabase/09_bai_hoc_lop8.sql.
  static const baiHoc = <BaiHoc>[
    BaiHoc(id: 'l9_toan_bai_1', monId: 'm_toan', lop: 9, hocKi: 1, thuTu: 1,
        chuong: 'Chương I: Phương trình và hệ hai phương trình bậc nhất hai ẩn',
        ten: 'Bài 1: Khái niệm phương trình và hệ hai phương trình bậc nhất hai ẩn',
        tomTat: 'Phương trình ax + by = c có vô số nghiệm, biểu diễn bằng một đường thẳng; hệ hai phương trình và nghiệm của hệ là cặp số thỏa cả hai.',
        kiemTra: ['(1; 2) có là nghiệm của x + y = 3 không? → có', 'Nghiệm của một phương trình bậc nhất hai ẩn vẽ thành hình gì? → đường thẳng']),
    BaiHoc(id: 'l9_toan_bai_2', monId: 'm_toan', lop: 9, hocKi: 1, thuTu: 2,
        chuong: 'Chương I: Phương trình và hệ hai phương trình bậc nhất hai ẩn',
        ten: 'Bài 2: Giải hệ hai phương trình bậc nhất hai ẩn',
        tomTat: 'Hai cách giải hệ: phương pháp thế (rút một ẩn rồi thay vào) và phương pháp cộng đại số (cộng/trừ hai phương trình để khử một ẩn).',
        kiemTra: ['Giải hệ x + y = 5, x − y = 1. → x = 3, y = 2', 'Kể hai phương pháp giải hệ. → thế; cộng đại số']),
    BaiHoc(id: 'l9_toan_ltc_1', monId: 'm_toan', lop: 9, hocKi: 1, thuTu: 3,
        chuong: 'Chương I: Phương trình và hệ hai phương trình bậc nhất hai ẩn',
        ten: 'Luyện tập chung (trang 19)',
        tomTat: 'Ôn Bài 1–2: nhận biết nghiệm, giải hệ bằng cả hai phương pháp.',
        kiemTra: ['Con giải hệ bằng phương pháp nào thấy nhanh hơn?']),
    BaiHoc(id: 'l9_toan_bai_3', monId: 'm_toan', lop: 9, hocKi: 1, thuTu: 4,
        chuong: 'Chương I: Phương trình và hệ hai phương trình bậc nhất hai ẩn',
        ten: 'Bài 3: Giải bài toán bằng cách lập hệ phương trình',
        tomTat: 'Chọn hai ẩn, lập hai phương trình từ đề bài, giải hệ rồi đối chiếu điều kiện.',
        kiemTra: ['Hai số có tổng 10 và hiệu 2 — con lập hệ thế nào? → x + y = 10, x − y = 2']),
    BaiHoc(id: 'l9_toan_cuoi_c1', monId: 'm_toan', lop: 9, hocKi: 1, thuTu: 5,
        chuong: 'Chương I: Phương trình và hệ hai phương trình bậc nhất hai ẩn',
        ten: 'Bài tập cuối chương I'),
    BaiHoc(id: 'l9_van_tri_thuc_1', monId: 'm_van', lop: 9, hocKi: 1, thuTu: 1,
        chuong: 'Bài 1: Thế giới kì ảo', ten: 'Tri thức ngữ văn trang 9',
        tomTat: 'Truyện truyền kì: truyện có yếu tố kì ảo, gắn với đời sống và số phận con người thời trung đại.'),
    BaiHoc(id: 'l9_van_nam_xuong', monId: 'm_van', lop: 9, hocKi: 1, thuTu: 2,
        chuong: 'Bài 1: Thế giới kì ảo', ten: 'Chuyện người con gái Nam Xương',
        tomTat: 'Nguyễn Dữ ("Truyền kì mạn lục"): Vũ Nương đức hạnh bị chồng nghi oan vì cái bóng trên vách, phải gieo mình xuống sông; nỗi oan được giải ở thủy cung. Số phận người phụ nữ trong xã hội phong kiến.',
        kiemTra: ['Vì sao Vũ Nương bị chồng nghi oan? → vì lời con trẻ về "cái bóng" là cha', 'Kết truyện Vũ Nương có trở về không? → chỉ hiện về giữa dòng sông rồi biến mất']),
    BaiHoc(id: 'l8_toan_bai_1', monId: 'm_toan', lop: 8, hocKi: 1, thuTu: 1,
        chuong: 'Chương 1: Đa thức', ten: 'Bài 1: Đơn thức',
        tomTat: 'Đơn thức là tích của một số với các biến; thu gọn, tìm hệ số, bậc, cộng trừ đơn thức đồng dạng.',
        kiemTra: ['Đơn thức 5x²y³ có bậc mấy? → 5']),
    BaiHoc(id: 'l8_toan_bai_2', monId: 'm_toan', lop: 8, hocKi: 1, thuTu: 2,
        chuong: 'Chương 1: Đa thức', ten: 'Bài 2: Đa thức',
        tomTat: 'Đa thức là tổng của nhiều đơn thức; thu gọn, tìm bậc, tính giá trị.'),
  ];

  static const nguoiDung = <NguoiDung>[
    NguoiDung(id: 'ph_01', hoTen: 'Nguyễn Văn Hùng', vaiTro: VaiTro.phuHuynh, email: 'hung.nguyen@gmail.com', soDienThoai: '0904 128 337', conIds: ['hs_01', 'hs_02']),
    NguoiDung(id: 'hs_01', hoTen: 'Nguyễn Minh Khôi', vaiTro: VaiTro.hocSinh, lop: '9A2', truongId: 'tr_nguyen_trai', email: 'khoi.nguyen@hocsinh.vn'),
    NguoiDung(id: 'hs_02', hoTen: 'Nguyễn Bảo Ngọc', vaiTro: VaiTro.hocSinh, lop: '6A1', truongId: 'tr_nguyen_trai', email: 'ngoc.nguyen@hocsinh.vn'),
    NguoiDung(id: 'qt_01', hoTen: 'Trần Quản Trị', vaiTro: VaiTro.quanTri, email: 'admin@solienlac.vn'),
    NguoiDung(id: 'ph_02', hoTen: 'Lê Thị Hồng', vaiTro: VaiTro.phuHuynh, email: 'hong.le@gmail.com', soDienThoai: '0918 442 019', conIds: ['hs_03']),
    // Bảo đăng ký từ hồi còn gõ tay tên trường — chưa gắn vào danh mục.
    NguoiDung(id: 'hs_03', hoTen: 'Lê Gia Bảo', vaiTro: VaiTro.hocSinh, lop: '8A4', truong: 'THCS Nguyễn Trãi'),
    NguoiDung(id: 'hs_04', hoTen: 'Phạm Thùy Linh', vaiTro: VaiTro.hocSinh, lop: '9A2', truongId: 'tr_nguyen_trai', email: 'linh.pham@hocsinh.vn', hoatDong: false),
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
        {int? phut, List<String> anh = const [], String? nhanXet, String? baiHoc}) {
      final n = i++;
      return BaoCao(
        id: 'bc_$n',
        hocSinhId: 'hs_01',
        ngay: _ngay(lui),
        loai: loai,
        monId: mon,
        giaoVienId: gv,
        baiHocId: baiHoc,
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
      b(0, LoaiBaiTap.trenLop, 'm_van', 'gv_hoa', 'Soạn bài "Chuyện người con gái Nam Xương", trả lời 5 câu hỏi đọc hiểu trong sách giáo khoa.', TrangThai.xong, phut: 40, baiHoc: 'l9_van_nam_xuong'),
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
      b(5, LoaiBaiTap.trenLop, 'm_toan', 'gv_lan', 'Bài 8, 9, 10 trang 41.', TrangThai.xong, phut: 40, baiHoc: 'l9_toan_bai_1'),
      b(6, LoaiBaiTap.trenLop, 'm_hoa', 'gv_thuy', 'Học thuộc hóa trị và làm bài 2–5 sách bài tập.', TrangThai.dangLam, phut: 25),
    ];
  }

  /// Hai phần thưởng bố Hùng treo cho Khôi: một mốc gần, một mốc xa.
  static List<PhanThuong> get phanThuong => [
        PhanThuong(
          id: 'pt_01',
          hocSinhId: 'hs_01',
          taoBoi: 'ph_01',
          moc: 7,
          ten: 'Đi ăn kem cả nhà',
          lapLai: true,
          tuNgay: _ngay(6),
          taoLuc: _ngay(6).add(const Duration(hours: 21)),
        ),
        PhanThuong(
          id: 'pt_02',
          hocSinhId: 'hs_01',
          taoBoi: 'ph_01',
          moc: 30,
          ten: 'Bộ Lego Technic',
          lapLai: false,
          tuNgay: _ngay(6),
          taoLuc: _ngay(6).add(const Duration(hours: 21, minutes: 2)),
        ),
        PhanThuong(
          id: 'pt_03',
          hocSinhId: 'hs_01',
          taoBoi: 'ph_01',
          loai: LoaiPhanThuong.diem,
          moc: 1,
          ten: 'Đi xem phim',
          kiThi: null,
          monId: null,
          diemToiThieu: 8,
          tuNgay: _ngay(20),
          taoLuc: _ngay(20).add(const Duration(hours: 21)),
        ),
      ];

  /// Sổ điểm của Khôi: vài bài thường xuyên và một bài giữa kì.
  static List<DiemThi> get diemThi => [
        DiemThi(id: 'dt_01', hocSinhId: 'hs_01', monId: 'm_toan', loai: LoaiKiemTra.mieng,
            hocKi: 1, diem: 9, ngay: _ngay(12), taoBoi: 'hs_01', taoLuc: _ngay(12)),
        DiemThi(id: 'dt_02', hocSinhId: 'hs_01', monId: 'm_van', loai: LoaiKiemTra.muoiLamPhut,
            hocKi: 1, diem: 7.5, ngay: _ngay(9), taoBoi: 'hs_01', taoLuc: _ngay(9)),
        DiemThi(id: 'dt_03', hocSinhId: 'hs_01', monId: 'm_anh', loai: LoaiKiemTra.mieng,
            hocKi: 1, diem: 8, ngay: _ngay(5), taoBoi: 'ph_01', taoLuc: _ngay(5)),
        DiemThi(id: 'dt_05', hocSinhId: 'hs_01', monId: 'm_toan', loai: LoaiKiemTra.muoiLamPhut,
            hocKi: 1, diem: 10, ngay: _ngay(7), taoBoi: 'hs_01', taoLuc: _ngay(7)),
        DiemThi(id: 'dt_06', hocSinhId: 'hs_01', monId: 'm_td', loai: LoaiKiemTra.mieng,
            hocKi: 1, dat: true, ngay: _ngay(8), taoBoi: 'hs_01', taoLuc: _ngay(8)),
        DiemThi(id: 'dt_04', hocSinhId: 'hs_01', monId: 'm_toan', loai: LoaiKiemTra.giuaKi,
            hocKi: 1, diem: 8.5, ngay: _ngay(3), ghiChu: 'Sai câu hình cuối', taoBoi: 'hs_01',
            taoLuc: _ngay(3)),
      ];

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
