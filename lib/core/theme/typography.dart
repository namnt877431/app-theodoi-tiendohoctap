import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Be Vietnam Pro được vẽ riêng cho tiếng Việt nên dấu đặt đúng chỗ,
/// không bị đè lên chữ hoa như phần lớn font Latin. Nó gánh toàn bộ giao diện.
/// Bricolage Grotesque chỉ dùng cho vài tiêu đề lớn để lấy cá tính.
abstract final class AppType {
  static const _fallback = ['Be Vietnam Pro', 'Roboto'];

  static TextStyle display(double size, {FontWeight w = FontWeight.w700, Color? color}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: w,
        height: 1.12,
        letterSpacing: -0.4,
        color: color ?? AppColor.ink,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle ui(
    double size, {
    FontWeight w = FontWeight.w500,
    Color? color,
    double height = 1.4,
    double spacing = 0,
  }) =>
      GoogleFonts.beVietnamPro(
        fontSize: size,
        fontWeight: w,
        height: height,
        letterSpacing: spacing,
        color: color ?? AppColor.ink,
      );

  /// Nhãn nhỏ in hoa — dùng cho "eyebrow" phía trên tiêu đề mục.
  static TextStyle eyebrow({Color? color}) => ui(
        11,
        w: FontWeight.w700,
        color: color ?? AppColor.mucNhat,
        spacing: 1.1,
      );

  /// Chữ số canh cột đều nhau — cho lưới thời khóa biểu và giờ giấc.
  static TextStyle numeric(double size, {FontWeight w = FontWeight.w600, Color? color}) =>
      GoogleFonts.beVietnamPro(
        fontSize: size,
        fontWeight: w,
        color: color ?? AppColor.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.1,
      );
}
