import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

/// Bìa quyển sổ liên lạc: nền mực đậm, dòng kẻ mờ, lề đỏ chạy dọc bên trái.
/// Đặt ngôn ngữ thị giác của cả app ngay ở màn hình đầu tiên.
class BiaSo extends StatelessWidget {
  const BiaSo({super.key, required this.phuDe, this.gonGang = false});

  final String phuDe;

  /// Bản thấp hơn, dành cho màn có biểu mẫu bên dưới.
  final bool gonGang;

  @override
  Widget build(BuildContext context) {
    final tren = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        Gap.xl,
        tren + (gonGang ? Gap.xl : Gap.xxl),
        Gap.xl,
        gonGang ? Gap.xl : Gap.xxl,
      ),
      decoration: const BoxDecoration(
        color: AppColor.ink,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28)),
      ),
      child: CustomPaint(
        painter: _KeBia(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.sm + 2, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: .28)),
                    borderRadius: BorderRadius.circular(R.sm),
                  ),
                  child: Text(
                    'THEO DÕI TIẾN ĐỘ HỌC TẬP',
                    style: AppType.eyebrow(color: Colors.white.withValues(alpha: .75)),
                  ),
                ),
              ],
            ),
            SizedBox(height: gonGang ? Gap.lg : Gap.xl),
            Text('Sổ liên lạc',
                style: AppType.display(gonGang ? 34 : 40, color: Colors.white)),
            const SizedBox(height: Gap.sm),
            SizedBox(
              width: 280,
              child: Text(
                phuDe,
                style: AppType.ui(
                  13.5,
                  color: Colors.white.withValues(alpha: .72),
                  w: FontWeight.w400,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeBia extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ke = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..strokeWidth = 1;
    for (var y = lineHeight; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(-Gap.xl, y), Offset(size.width + Gap.xl, y), ke);
    }
    final le = Paint()
      ..color = AppColor.butDo.withValues(alpha: .85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-Gap.md, -Gap.xl), Offset(-Gap.md, size.height + Gap.xl), le);
  }

  @override
  bool shouldRepaint(_KeBia old) => false;
}
