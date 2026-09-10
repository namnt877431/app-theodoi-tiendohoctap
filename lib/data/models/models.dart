import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

enum VaiTro {
  phuHuynh('Phụ huynh', Icons.family_restroom_rounded),
  hocSinh('Học sinh', Icons.backpack_rounded),
  quanTri('Quản trị', Icons.shield_moon_rounded);

  const VaiTro(this.nhan, this.icon);
  final String nhan;
  final IconData icon;
}

/// Hai hạng mục bài tập mà phụ huynh cần tách bạch khi xem báo cáo.
enum LoaiBaiTap {
  trenLop('Bài tập trên lớp', 'Trên lớp', AppColor.muc, AppColor.sky),
  hocThem('Bài tập học thêm', 'Học thêm', AppColor.hocThem, AppColor.hocThemNhat);

  const LoaiBaiTap(this.nhan, this.nhanNgan, this.mau, this.mauNen);
  final String nhan;
  final String nhanNgan;
  final Color mau;
  final Color mauNen;
}

/// Trạng thái quyết định màu của đường lề đỏ trên trang vở.
enum TrangThai {
  chuaLam('Chưa làm', AppColor.butDo, AppColor.butDoNhat, Icons.radio_button_unchecked_rounded),
  dangLam('Đang làm', AppColor.dangLam, AppColor.dangLamNhat, Icons.timelapse_rounded),
  xong('Đã xong', AppColor.xong, AppColor.xongNhat, Icons.check_circle_rounded);

  const TrangThai(this.nhan, this.mau, this.mauNen, this.icon);
  final String nhan;
  final Color mau;
  final Color mauNen;
  final IconData icon;
}

enum Buoi {
  sang('Sáng'),
  chieu('Chiều'),
  toi('Tối');

  const Buoi(this.nhan);
  final String nhan;
}

class NguoiDung {
  const NguoiDung({
    required this.id,
    required this.hoTen,
    required this.vaiTro,
    this.email,
    this.soDienThoai,
    this.lop,
    this.truong,
    this.conIds = const [],
    this.hoatDong = true,
  });

  final String id;
  final String hoTen;
  final VaiTro vaiTro;
  final String? email;
  final String? soDienThoai;

  /// Chỉ có ở học sinh.
  final String? lop;
  final String? truong;

  /// Chỉ có ở phụ huynh — danh sách id học sinh được liên kết.
  final List<String> conIds;
  final bool hoatDong;

  String get tenGoi => hoTen.split(' ').last;

  String get chuCaiDau {
    final phan = hoTen.trim().split(RegExp(r'\s+'));
    if (phan.length == 1) return phan.first.characters.first.toUpperCase();
    return (phan.first.characters.first + phan.last.characters.first).toUpperCase();
  }

  NguoiDung copyWith({
    String? hoTen,
    String? email,
    String? soDienThoai,
    String? lop,
    String? truong,
    List<String>? conIds,
    bool? hoatDong,
  }) =>
      NguoiDung(
        id: id,
        hoTen: hoTen ?? this.hoTen,
        vaiTro: vaiTro,
        email: email ?? this.email,
        soDienThoai: soDienThoai ?? this.soDienThoai,
        lop: lop ?? this.lop,
        truong: truong ?? this.truong,
        conIds: conIds ?? this.conIds,
        hoatDong: hoatDong ?? this.hoatDong,
      );
}

class MonHoc {
  const MonHoc({required this.id, required this.ten, required this.vietTat});

  final String id;
  final String ten;
  final String vietTat;
}

class GiaoVien {
  const GiaoVien({
    required this.id,
    required this.hoTen,
    required this.monId,
    required this.loai,
    this.noiDay,
    this.soDienThoai,
  });

  final String id;
  final String hoTen;
  final String monId;

  /// Thầy cô trên lớp hay thầy cô dạy thêm — báo cáo học thêm bám theo từng người.
  final LoaiBaiTap loai;
  final String? noiDay;
  final String? soDienThoai;

  String get xungHo => hoTen;
}

class TietHoc {
  const TietHoc({
    required this.id,
    required this.hocSinhId,
    required this.thu,
    required this.tiet,
    required this.buoi,
    required this.monId,
    required this.loai,
    this.giaoVienId,
    this.phong,
    this.batDau,
    this.ketThuc,
  });

  final String id;
  final String hocSinhId;

  /// 2..7 ứng với Thứ Hai..Thứ Bảy, 8 là Chủ nhật.
  final int thu;
  final int tiet;
  final Buoi buoi;
  final String monId;
  final LoaiBaiTap loai;
  final String? giaoVienId;
  final String? phong;
  final String? batDau;
  final String? ketThuc;

  String get khungGio => (batDau != null && ketThuc != null) ? '$batDau – $ketThuc' : '';

  TietHoc copyWith({
    int? thu,
    int? tiet,
    Buoi? buoi,
    String? monId,
    LoaiBaiTap? loai,
    String? giaoVienId,
    String? phong,
    String? batDau,
    String? ketThuc,
  }) =>
      TietHoc(
        id: id,
        hocSinhId: hocSinhId,
        thu: thu ?? this.thu,
        tiet: tiet ?? this.tiet,
        buoi: buoi ?? this.buoi,
        monId: monId ?? this.monId,
        loai: loai ?? this.loai,
        giaoVienId: giaoVienId ?? this.giaoVienId,
        phong: phong ?? this.phong,
        batDau: batDau ?? this.batDau,
        ketThuc: ketThuc ?? this.ketThuc,
      );
}

class BaoCao {
  const BaoCao({
    required this.id,
    required this.hocSinhId,
    required this.ngay,
    required this.loai,
    required this.monId,
    required this.noiDung,
    required this.trangThai,
    required this.taoLuc,
    this.giaoVienId,
    this.anh = const [],
    this.soPhut,
    this.nhanXetPhuHuynh,
    this.phuHuynhDaXem = false,
  });

  final String id;
  final String hocSinhId;
  final DateTime ngay;
  final LoaiBaiTap loai;
  final String monId;
  final String? giaoVienId;
  final String noiDung;
  final TrangThai trangThai;

  /// Đường dẫn ảnh chụp bài — không bắt buộc.
  final List<String> anh;
  final int? soPhut;
  final String? nhanXetPhuHuynh;
  final bool phuHuynhDaXem;
  final DateTime taoLuc;

  BaoCao copyWith({
    DateTime? ngay,
    LoaiBaiTap? loai,
    String? monId,
    String? giaoVienId,
    String? noiDung,
    TrangThai? trangThai,
    List<String>? anh,
    int? soPhut,
    String? nhanXetPhuHuynh,
    bool? phuHuynhDaXem,
  }) =>
      BaoCao(
        id: id,
        hocSinhId: hocSinhId,
        ngay: ngay ?? this.ngay,
        loai: loai ?? this.loai,
        monId: monId ?? this.monId,
        giaoVienId: giaoVienId ?? this.giaoVienId,
        noiDung: noiDung ?? this.noiDung,
        trangThai: trangThai ?? this.trangThai,
        anh: anh ?? this.anh,
        soPhut: soPhut ?? this.soPhut,
        nhanXetPhuHuynh: nhanXetPhuHuynh ?? this.nhanXetPhuHuynh,
        phuHuynhDaXem: phuHuynhDaXem ?? this.phuHuynhDaXem,
        taoLuc: taoLuc,
      );
}

class NhacNho {
  const NhacNho({
    required this.id,
    required this.tuId,
    required this.denId,
    required this.noiDung,
    required this.taoLuc,
    this.hanLuc,
    this.daDoc = false,
    this.baoCaoId,
  });

  final String id;
  final String tuId;
  final String denId;
  final String noiDung;
  final DateTime taoLuc;
  final DateTime? hanLuc;
  final bool daDoc;
  final String? baoCaoId;

  NhacNho copyWith({bool? daDoc}) => NhacNho(
        id: id,
        tuId: tuId,
        denId: denId,
        noiDung: noiDung,
        taoLuc: taoLuc,
        hanLuc: hanLuc,
        daDoc: daDoc ?? this.daDoc,
        baoCaoId: baoCaoId,
      );
}

/// Tổng hợp một ngày để hiện nhanh trên trang chủ phụ huynh.
class TongKetNgay {
  const TongKetNgay({
    required this.xong,
    required this.dangLam,
    required this.chuaLam,
    required this.soPhut,
  });

  final int xong;
  final int dangLam;
  final int chuaLam;
  final int soPhut;

  int get tong => xong + dangLam + chuaLam;
  double get tiLeXong => tong == 0 ? 0 : xong / tong;
}
