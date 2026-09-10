import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import '../admin/admin_shell.dart';
import '../parent/parent_shell.dart';
import '../student/student_shell.dart';
import 'dang_nhap_screen.dart';

/// Cổng vào app. Nghe trạng thái phiên rồi tự đưa người dùng tới đúng chỗ —
/// nhờ vậy đăng xuất, phiên hết hạn hay tài khoản bị khóa đều xử lý một chỗ,
/// không phải rải `Navigator.pushAndRemoveUntil` khắp nơi.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    final Widget man;
    if (s.dangKhoiTao) {
      man = const _ManCho();
    } else if (s.nguoiDung case final nd?) {
      man = switch (nd.vaiTro) {
        VaiTro.phuHuynh => const ParentShell(),
        VaiTro.hocSinh => const StudentShell(),
        VaiTro.quanTri => const AdminShell(),
      };
    } else {
      man = const DangNhapScreen();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: KeyedSubtree(
        key: ValueKey(man.runtimeType),
        child: s.dungThu ? _VienDungThu(child: man) : man,
      ),
    );
  }
}

/// Dải mỏng nhắc rằng đây là dữ liệu mẫu. Nói thẳng ra để không ai nhầm số
/// liệu trong này với chuyện học thật của con mình.
class _VienDungThu extends StatelessWidget {
  const _VienDungThu({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColor.dangLamNhat,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 7),
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined, size: 14, color: AppColor.dangLam),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Đang xem thử bằng dữ liệu mẫu',
                      style: AppType.ui(11.5, w: FontWeight.w600, color: AppColor.dangLam),
                    ),
                  ),
                  GestureDetector(
                    onTap: context.read<AppState>().dangXuat,
                    child: Text(
                      'Thoát',
                      style: AppType.ui(11.5, w: FontWeight.w700, color: AppColor.dangLam)
                          .copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: child)),
      ],
    );
  }
}

/// Màn chờ trong lúc chưa biết người dùng đã đăng nhập hay chưa. Giữ đúng
/// hình bìa sổ để lúc mở app không thấy một khoảng trắng vô nghĩa.
class _ManCho extends StatelessWidget {
  const _ManCho();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sổ liên lạc', style: AppType.display(34, color: Colors.white)),
            const SizedBox(height: Gap.xl),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withValues(alpha: .6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
