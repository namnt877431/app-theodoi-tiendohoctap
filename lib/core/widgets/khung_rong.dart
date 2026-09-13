import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Trên màn rộng (web trên máy tính, máy tính bảng nằm ngang) app không
/// trải ra hết bề ngang — giao diện thiết kế cho một cột đọc, kéo dài ra thì
/// chữ và ô rơi hết về góc trái, nửa màn còn lại trống hoác. Thay vào đó
/// đóng khung ở giữa với bề rộng vừa tay, hai bên là nền dịu, như một tờ
/// sổ đặt trên bàn.
///
/// Bên trong khung, [MediaQuery] báo đúng kích thước của khung, nên bảng
/// chọn, hộp thoại và mọi thứ đo theo bề ngang màn hình đều nằm gọn trong đó.
class KhungRong extends StatelessWidget {
  const KhungRong({super.key, required this.child});

  final Widget child;

  /// Bề rộng tối đa của khung — đủ cho lưới thời khóa biểu bảy cột không
  /// phải cuộn ngang, mà một dòng chữ vẫn chưa quá dài để đọc.
  static const rongToiDa = 680.0;

  /// Màn hẹp hơn mức này thì để nguyên, khỏi lãng phí hai dải viền.
  static const nguong = rongToiDa + 96;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width < nguong) return child;

    return ColoredBox(
      color: AppColor.sky,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: rongToiDa),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColor.giay,
              border: Border.symmetric(
                vertical: BorderSide(color: AppColor.dongKeDam),
              ),
            ),
            child: MediaQuery(
              data: mq.copyWith(size: Size(rongToiDa, mq.size.height)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
