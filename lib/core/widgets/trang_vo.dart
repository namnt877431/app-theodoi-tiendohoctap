import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Một trang vở kẻ ngang: dòng kẻ mờ chạy ngang, và đường lề dọc bên trái.
///
/// Đường lề không phải trang trí. Màu của nó chính là trạng thái của mục —
/// đỏ là chưa làm, hổ phách là đang làm, xanh lá là xong — nên người đọc
/// nhận ra tình hình trước cả khi kịp đọc chữ.
class TrangVo extends StatelessWidget {
  const TrangVo({
    super.key,
    required this.child,
    this.mauLe = AppColor.dongKeDam,
    this.le,
    this.onTap,
    this.keNgang = true,
    this.padding = const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.md),
    this.rongLe = 44,
    this.nen,
    this.vienNoiBat = false,
  });

  final Widget child;

  /// Màu đường lề — mang nghĩa trạng thái.
  final Color mauLe;

  /// Nội dung nằm trong khoảng lề bên trái (biểu tượng trạng thái, số tiết…).
  final Widget? le;

  final VoidCallback? onTap;
  final bool keNgang;
  final EdgeInsets padding;
  final double rongLe;
  final Color? nen;
  final bool vienNoiBat;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: nen ?? AppColor.giayTrang,
      borderRadius: BorderRadius.circular(R.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(R.lg),
        splashColor: mauLe.withValues(alpha: .07),
        highlightColor: mauLe.withValues(alpha: .04),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(R.lg),
            border: Border.all(
              color: vienNoiBat ? mauLe.withValues(alpha: .45) : AppColor.dongKe,
              width: vienNoiBat ? 1.4 : 1,
            ),
          ),
          child: CustomPaint(
            painter: _GiayKe(mauLe: mauLe, rongLe: rongLe, keNgang: keNgang),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: rongLe,
                  child: Padding(
                    padding: EdgeInsets.only(top: padding.top + 1),
                    child: Center(child: le ?? const SizedBox.shrink()),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: Gap.md,
                      right: padding.right,
                      top: padding.top,
                      bottom: padding.bottom,
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GiayKe extends CustomPainter {
  const _GiayKe({required this.mauLe, required this.rongLe, required this.keNgang});

  final Color mauLe;
  final double rongLe;
  final bool keNgang;

  @override
  void paint(Canvas canvas, Size size) {
    if (keNgang) {
      final ke = Paint()
        ..color = AppColor.dongKe.withValues(alpha: .55)
        ..strokeWidth = 1;
      // Dòng kẻ chỉ chạy ở phần thân, chừa lề — giống trang vở thật.
      for (var y = lineHeight; y < size.height - 4; y += lineHeight) {
        canvas.drawLine(Offset(rongLe, y), Offset(size.width - Gap.md, y), ke);
      }
    }

    final le = Paint()
      ..color = mauLe
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(rongLe, Gap.sm),
      Offset(rongLe, size.height - Gap.sm),
      le,
    );
  }

  @override
  bool shouldRepaint(_GiayKe old) =>
      old.mauLe != mauLe || old.rongLe != rongLe || old.keNgang != keNgang;
}
