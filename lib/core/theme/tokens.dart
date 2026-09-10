import 'package:flutter/material.dart';

/// Bảng màu "Sổ liên lạc" — lấy từ văn phòng phẩm học đường Việt Nam:
/// giấy vở hơi lạnh, mực Cửu Long, và bút đỏ chấm bài của thầy cô.
abstract final class AppColor {
  /// Mực đậm — chữ tiêu đề, nền thanh điều hướng.
  static const ink = Color(0xFF0E2E52);

  /// Mực Cửu Long — màu chủ đạo, dùng cho hành động chính.
  static const muc = Color(0xFF1D5FA8);

  /// Mực nhạt — chữ phụ, biểu tượng không nhấn.
  static const mucNhat = Color(0xFF5B7CA3);

  /// Nền xanh rất nhạt — vùng chọn, nền chip, nền thẻ phụ.
  static const sky = Color(0xFFE8F1FA);

  /// Nền xanh nhạt hơn nữa — dải nền toàn màn hình.
  static const skySoft = Color(0xFFF3F8FD);

  /// Giấy — nền thẻ, nền trang.
  static const giay = Color(0xFFFBFCFE);
  static const giayTrang = Color(0xFFFFFFFF);

  /// Dòng kẻ trên trang vở.
  static const dongKe = Color(0xFFDDE7F2);
  static const dongKeDam = Color(0xFFC3D4E6);

  /// Bút đỏ chấm bài — chỉ dùng cho việc chưa làm / quá hạn.
  static const butDo = Color(0xFFD64545);
  static const butDoNhat = Color(0xFFFDECEC);

  /// Đã xong.
  static const xong = Color(0xFF1E9E6A);
  static const xongNhat = Color(0xFFE6F5EE);

  /// Đang làm dở.
  static const dangLam = Color(0xFFE0912B);
  static const dangLamNhat = Color(0xFFFDF2E2);

  /// Bài học thêm — phân biệt với bài trên lớp.
  static const hocThem = Color(0xFF7A5AF8);
  static const hocThemNhat = Color(0xFFF0EDFE);
}

/// Nhịp giãn cách 4pt.
abstract final class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Vở không bo góc tròn — bán kính giữ nhỏ và dứt khoát.
abstract final class R {
  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 14.0;
  static const pill = 999.0;
}

/// Chiều cao một dòng kẻ trên trang vở. Mọi thứ nằm trên trang đều
/// bám theo nhịp này để trang trông thật sự có dòng kẻ.
const double lineHeight = 28.0;
