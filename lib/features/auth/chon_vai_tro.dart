import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import '../admin/admin_shell.dart';
import '../parent/parent_shell.dart';
import '../student/student_shell.dart';

/// Màn hình mở app. Phần đầu là "bìa sổ" — nền mực đậm, dòng kẻ mờ và
/// đường lề đỏ chạy dọc — đặt luôn ngôn ngữ thị giác của cả app ở màn đầu tiên.
class ChonVaiTroScreen extends StatelessWidget {
  const ChonVaiTroScreen({super.key});

  Future<void> _vao(BuildContext context, VaiTro vaiTro) async {
    final state = context.read<AppState>();
    await state.dangNhap(vaiTro);
    if (!context.mounted) return;

    final Widget dich = switch (vaiTro) {
      VaiTro.phuHuynh => const ParentShell(),
      VaiTro.hocSinh => const StudentShell(),
      VaiTro.quanTri => const AdminShell(),
    };
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, a, _) => FadeTransition(opacity: a, child: dich),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dangTai = context.watch<AppState>().dangTai;

    return Scaffold(
      backgroundColor: AppColor.giay,
      body: Column(
        children: [
          const _BiaSo(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xl, Gap.xl, Gap.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Bạn vào app với vai trò nào?',
                      style: AppType.ui(15, w: FontWeight.w600)),
                  const SizedBox(height: Gap.xs),
                  Text(
                    'Mỗi vai trò thấy một màn hình khác nhau. Phụ huynh theo dõi và nhắc, học sinh nhập bài và báo cáo.',
                    style: AppType.ui(13, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.5),
                  ),
                  const SizedBox(height: Gap.lg),
                  for (final vt in VaiTro.values) ...[
                    _TheVaiTro(
                      vaiTro: vt,
                      moTa: switch (vt) {
                        VaiTro.phuHuynh => 'Xem báo cáo hằng ngày, nhập thời khóa biểu, gửi nhắc nhở',
                        VaiTro.hocSinh => 'Nhập thời khóa biểu, viết báo cáo, chụp ảnh bài làm',
                        VaiTro.quanTri => 'Quản lý tài khoản, lớp, môn học và giáo viên',
                      },
                      onTap: dangTai ? null : () => _vao(context, vt),
                    ),
                    const SizedBox(height: Gap.md),
                  ],
                  const SizedBox(height: Gap.sm),
                  Center(
                    child: Text(
                      dangTai ? 'Đang mở sổ…' : 'Bản dùng thử — dữ liệu mẫu của lớp 9A2',
                      style: AppType.ui(12, color: AppColor.mucNhat, w: FontWeight.w400),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bìa quyển sổ liên lạc: nền mực đậm, dòng kẻ mờ, lề đỏ dọc bên trái.
class _BiaSo extends StatelessWidget {
  const _BiaSo();

  @override
  Widget build(BuildContext context) {
    final tren = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(Gap.xl, tren + Gap.xxl, Gap.xl, Gap.xxl),
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
                    'THCS NGUYỄN TRÃI',
                    style: AppType.eyebrow(color: Colors.white.withValues(alpha: .75)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.xl),
            Text('Sổ liên lạc', style: AppType.display(40, color: Colors.white)),
            const SizedBox(height: Gap.sm),
            SizedBox(
              width: 260,
              child: Text(
                'Mỗi tối, bố mẹ biết hôm nay con đã học những gì — không phải hỏi.',
                style: AppType.ui(
                  14,
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

class _TheVaiTro extends StatelessWidget {
  const _TheVaiTro({required this.vaiTro, required this.moTa, this.onTap});

  final VaiTro vaiTro;
  final String moTa;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.giayTrang,
      borderRadius: BorderRadius.circular(R.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(R.lg),
        child: Ink(
          padding: const EdgeInsets.all(Gap.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(R.lg),
            border: Border.all(color: AppColor.dongKe),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColor.sky,
                  borderRadius: BorderRadius.circular(R.md),
                ),
                child: Icon(vaiTro.icon, color: AppColor.muc, size: 23),
              ),
              const SizedBox(width: Gap.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vaiTro.nhan, style: AppType.ui(16, w: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      moTa,
                      style: AppType.ui(12.5,
                          color: AppColor.mucNhat, w: FontWeight.w400, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gap.sm),
              const Icon(Icons.arrow_forward_rounded, size: 19, color: AppColor.mucNhat),
            ],
          ),
        ),
      ),
    );
  }
}
