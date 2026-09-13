import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../huy_hieu/huy_hieu.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'common.dart';

/// Con dấu khen — huy hiệu vẽ như cái dấu cao su cô đóng vào vở: vòng ngoài
/// đậm, vòng trong răng cưa, biểu tượng ở giữa, đóng hơi nghiêng.
///
/// Đạt rồi thì mực xanh (mốc cao nhất: mực vàng), nền nhuộm nhạt. Chưa đạt
/// thì chỉ là đường viền xám nhạt, và vòng ngoài thành vòng tiến độ — đứa
/// trẻ nhìn là biết còn bao xa.
class ConDau extends StatelessWidget {
  const ConDau(
    this.tienDo, {
    super.key,
    this.kichThuoc = 72,
    this.coTen = true,
    this.coTienDo = false,
    this.onTap,
  });

  final TienDoHuyHieu tienDo;
  final double kichThuoc;
  final bool coTen;
  final bool coTienDo;
  final VoidCallback? onTap;

  static Color mauCua(HuyHieu hh) => hh.vang ? AppColor.vang : AppColor.muc;
  static Color nenCua(HuyHieu hh) => hh.vang ? AppColor.vangNhat : AppColor.sky;

  @override
  Widget build(BuildContext context) {
    final hh = tienDo.huyHieu;
    final dat = tienDo.dat;
    final mau = mauCua(hh);

    final dau = Transform.rotate(
      // Dấu đóng tay thì không bao giờ thẳng tắp.
      angle: dat ? -0.09 : 0,
      // CustomPaint có child thì lấy cỡ của child chứ không phải `size`, mà
      // Center thì nở hết chỗ trống — phải ép khung vuông từ ngoài.
      child: SizedBox.square(
        dimension: kichThuoc,
        child: CustomPaint(
          painter: _VeConDau(
            mau: dat ? mau : AppColor.dongKeDam,
            nen: dat ? nenCua(hh) : AppColor.giayTrang,
            tienDo: dat ? null : tienDo.tiLe,
            mauTienDo: mau,
          ),
          child: Center(
            child: Icon(
              hh.icon,
              size: kichThuoc * .36,
              color: dat ? mau : AppColor.mucNhat.withValues(alpha: .5),
            ),
          ),
        ),
      ),
    );

    final khoi = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dau,
        if (coTen) ...[
          const SizedBox(height: Gap.sm),
          SizedBox(
            width: kichThuoc + 20,
            child: Text(
              hh.ten,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.ui(
                11.5,
                w: FontWeight.w600,
                height: 1.25,
                color: dat ? AppColor.ink : AppColor.mucNhat,
              ),
            ),
          ),
        ],
        if (coTienDo && !dat) ...[
          const SizedBox(height: 3),
          Text(
            tienDo.nhanTienDo,
            style: AppType.numeric(10.5, color: AppColor.mucNhat, w: FontWeight.w500),
          ),
        ],
      ],
    );

    if (onTap == null) return khoi;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(R.md),
      child: Padding(padding: const EdgeInsets.all(Gap.xs), child: khoi),
    );
  }
}

class _VeConDau extends CustomPainter {
  _VeConDau({
    required this.mau,
    required this.nen,
    required this.tienDo,
    required this.mauTienDo,
  });

  final Color mau;
  final Color nen;

  /// Null là đã đạt (vòng ngoài liền). Có giá trị là phần vòng đã đi được.
  final double? tienDo;
  final Color mauTienDo;

  @override
  void paint(Canvas canvas, Size size) {
    final tam = size.center(Offset.zero);
    final r = size.width / 2 - 2;

    canvas.drawCircle(tam, r, Paint()..color = nen);

    // Vòng ngoài. Chưa đạt thì vòng xám mảnh, đè lên một cung màu tiến độ.
    final vong = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tienDo == null ? 2.4 : 1.6
      ..color = mau;
    canvas.drawCircle(tam, r, vong);

    final td = tienDo;
    if (td != null && td > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: tam, radius: r),
        -math.pi / 2,
        2 * math.pi * td,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..color = mauTienDo,
      );
    }

    // Vòng răng cưa bên trong — đặc trưng của dấu cao su.
    final rTrong = r - 7;
    final soRang = 36;
    final buoc = 2 * math.pi / soRang;
    final rang = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = mau.withValues(alpha: tienDo == null ? .75 : .9);
    for (var i = 0; i < soRang; i++) {
      final a = i * buoc;
      canvas.drawArc(
        Rect.fromCircle(center: tam, radius: rTrong),
        a,
        buoc * .55,
        false,
        rang,
      );
    }
  }

  @override
  bool shouldRepaint(_VeConDau old) =>
      old.mau != mau || old.nen != nen || old.tienDo != tienDo || old.mauTienDo != mauTienDo;
}

/// Lúc vừa đạt: con dấu lớn đóng xuống — phóng to rồi nén lại, kèm tên và
/// lời cô. Mở như một hộp thoại nhỏ giữa màn.
Future<void> moKhenHuyHieu(BuildContext context, HuyHieu hh) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColor.ink.withValues(alpha: .55),
    builder: (ctx) => Dialog(
      backgroundColor: AppColor.giayTrang,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.lg + 4)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xxl, Gap.xl, Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Eyebrow('Cô đóng dấu khen'),
            const SizedBox(height: Gap.xl),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.scale(
                // Dấu rơi từ trên xuống: to lúc đầu, nén lại khi chạm giấy.
                scale: 1.9 - 0.9 * t,
                child: Opacity(opacity: t.clamp(0, 1), child: child),
              ),
              child: ConDau(TienDoHuyHieu(hh, hh.muc), kichThuoc: 128, coTen: false),
            ),
            const SizedBox(height: Gap.xl),
            Text(hh.ten, style: AppType.display(24, color: ConDau.mauCua(hh))),
            const SizedBox(height: Gap.sm),
            Text(
              hh.moTa,
              textAlign: TextAlign.center,
              style: AppType.ui(13.5, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.5),
            ),
            const SizedBox(height: Gap.xl),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tuyệt!'),
            ),
          ],
        ),
      ),
    ),
  );
}
