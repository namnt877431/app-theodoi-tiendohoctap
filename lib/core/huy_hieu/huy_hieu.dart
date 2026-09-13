import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import 'chuoi.dart';

/// Huy hiệu — con dấu khen cô đóng vào vở.
///
/// Tính hoàn toàn từ báo cáo đã có trên máy, không lưu gì thêm ở máy chủ:
/// mở app là có, đổi luật là đổi ngay cho mọi người. Mỗi con dấu có một mốc;
/// chưa tới mốc thì hiện vòng tiến độ, để đứa trẻ biết còn bao xa.
enum NhomHuyHieu {
  chuoi('Chuỗi ngày trọn vẹn', 'Ngày nào cũng có báo cáo và xong hết bài'),
  soBai('Bài đã xong', 'Đếm những bài báo cáo là đã làm xong'),
  thoiQuen('Thói quen tốt', 'Những việc nhỏ làm đều thành nếp');

  const NhomHuyHieu(this.ten, this.moTa);
  final String ten;
  final String moTa;
}

class HuyHieu {
  const HuyHieu({
    required this.id,
    required this.ten,
    required this.moTa,
    required this.icon,
    required this.nhom,
    required this.muc,
    this.donVi = '',
    this.vang = false,
  });

  final String id;
  final String ten;

  /// Cần làm gì để đạt — viết như lời cô dặn, không như điều kiện kỹ thuật.
  final String moTa;
  final IconData icon;
  final NhomHuyHieu nhom;

  /// Mốc phải đạt, cùng đơn vị với số đo của nhóm.
  final int muc;
  final String donVi;

  /// Mốc cao nhất của nhóm — đóng bằng mực vàng thay vì mực xanh.
  final bool vang;
}

/// Bộ con dấu. Thứ tự trong nhóm là thứ tự khó dần.
const danhSachHuyHieu = <HuyHieu>[
  // Chuỗi ngày — số đo: chuỗi dài nhất từng đạt.
  HuyHieu(id: 'chuoi_3', ten: 'Ba ngày liền', moTa: 'Ba ngày liên tiếp xong hết bài',
      icon: Icons.local_fire_department_rounded, nhom: NhomHuyHieu.chuoi, muc: 3, donVi: 'ngày'),
  HuyHieu(id: 'chuoi_7', ten: 'Trọn một tuần', moTa: 'Bảy ngày liên tiếp xong hết bài',
      icon: Icons.calendar_view_week_rounded, nhom: NhomHuyHieu.chuoi, muc: 7, donVi: 'ngày'),
  HuyHieu(id: 'chuoi_14', ten: 'Hai tuần bền bỉ', moTa: 'Mười bốn ngày liên tiếp xong hết bài',
      icon: Icons.date_range_rounded, nhom: NhomHuyHieu.chuoi, muc: 14, donVi: 'ngày'),
  HuyHieu(id: 'chuoi_30', ten: 'Tháng vàng', moTa: 'Ba mươi ngày liên tiếp xong hết bài',
      icon: Icons.workspace_premium_rounded, nhom: NhomHuyHieu.chuoi, muc: 30, donVi: 'ngày', vang: true),

  // Số bài — số đo: báo cáo ở trạng thái xong.
  HuyHieu(id: 'xong_10', ten: 'Mười bài đầu', moTa: 'Báo cáo xong mười bài',
      icon: Icons.menu_book_rounded, nhom: NhomHuyHieu.soBai, muc: 10, donVi: 'bài'),
  HuyHieu(id: 'xong_50', ten: 'Năm mươi bài', moTa: 'Báo cáo xong năm mươi bài',
      icon: Icons.auto_stories_rounded, nhom: NhomHuyHieu.soBai, muc: 50, donVi: 'bài'),
  HuyHieu(id: 'xong_100', ten: 'Trăm bài', moTa: 'Báo cáo xong một trăm bài',
      icon: Icons.military_tech_rounded, nhom: NhomHuyHieu.soBai, muc: 100, donVi: 'bài', vang: true),

  // Thói quen — mỗi con dấu một số đo riêng.
  HuyHieu(id: 'som_5', ten: 'Chim sớm', moTa: 'Năm lần gửi báo cáo trước 7 giờ tối',
      icon: Icons.wb_sunny_rounded, nhom: NhomHuyHieu.thoiQuen, muc: 5, donVi: 'lần'),
  HuyHieu(id: 'anh_10', ten: 'Có ảnh làm chứng', moTa: 'Mười báo cáo kèm ảnh vở',
      icon: Icons.photo_camera_rounded, nhom: NhomHuyHieu.thoiQuen, muc: 10, donVi: 'ảnh'),
  HuyHieu(id: 'mon_8', ten: 'Đủ môn', moTa: 'Có báo cáo cho tám môn khác nhau',
      icon: Icons.grid_view_rounded, nhom: NhomHuyHieu.thoiQuen, muc: 8, donVi: 'môn'),
  HuyHieu(id: 'hoc_them_10', ten: 'Ngoài giờ', moTa: 'Xong mười bài học thêm',
      icon: Icons.nightlight_round, nhom: NhomHuyHieu.thoiQuen, muc: 10, donVi: 'bài'),
  HuyHieu(id: 'gio_10', ten: 'Mười giờ học', moTa: 'Ghi lại tổng cộng mười giờ học',
      icon: Icons.hourglass_bottom_rounded, nhom: NhomHuyHieu.thoiQuen, muc: 10, donVi: 'giờ', vang: true),
];

class TienDoHuyHieu {
  const TienDoHuyHieu(this.huyHieu, this.hienTai);

  final HuyHieu huyHieu;
  final int hienTai;

  bool get dat => hienTai >= huyHieu.muc;
  double get tiLe => (hienTai / huyHieu.muc).clamp(0, 1).toDouble();
  String get nhanTienDo => '${hienTai.clamp(0, huyHieu.muc)}/${huyHieu.muc} ${huyHieu.donVi}'.trim();
}

/// Tính tiến độ mọi con dấu từ danh sách báo cáo.
///
/// Chuỗi ngày đếm theo [luat] (xem [demChuoi]): lấy chuỗi dài nhất từng có.
/// Mặc định là luật thuần — ngày trống nào cũng đứt.
List<TienDoHuyHieu> tinhHuyHieu(List<BaoCao> ds, {LuatChuoi luat = const LuatChuoi()}) {
  final soDo = <String, int>{
    'chuoi': demChuoi(ds, luat: luat).daiNhat,
    'xong': ds.where((b) => b.trangThai == TrangThai.xong).length,
    'som': ds.where((b) => b.taoLuc.hour < 19).length,
    'anh': ds.where((b) => b.anh.isNotEmpty).length,
    'mon': ds.map((b) => b.monId).where((m) => m.isNotEmpty).toSet().length,
    'hoc_them': ds
        .where((b) => b.loai == LoaiBaiTap.hocThem && b.trangThai == TrangThai.xong)
        .length,
    'gio': ds.fold(0, (t, b) => t + (b.soPhut ?? 0)) ~/ 60,
  };

  return [
    for (final hh in danhSachHuyHieu)
      TienDoHuyHieu(hh, soDo[hh.id.replaceAll(RegExp(r'_\d+$'), '')] ?? 0),
  ];
}

/// Những con dấu vừa đạt được giữa hai lần tính — để reo lên đúng lúc.
List<HuyHieu> huyHieuVuaDat(List<TienDoHuyHieu> truoc, List<TienDoHuyHieu> sau) {
  final daCo = truoc.where((t) => t.dat).map((t) => t.huyHieu.id).toSet();
  return [
    for (final t in sau)
      if (t.dat && !daCo.contains(t.huyHieu.id)) t.huyHieu,
  ];
}
