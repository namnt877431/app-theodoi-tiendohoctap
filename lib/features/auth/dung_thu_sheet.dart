import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';

/// Chế độ xem thử: chạy trên dữ liệu mẫu trong bộ nhớ, không đụng tới Firebase.
/// Có để người mới cài xem được giao diện của cả ba vai trò mà chưa cần tài khoản.
Future<void> moDungThu(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: const _DungThu(),
    ),
  );
}

class _DungThu extends StatelessWidget {
  const _DungThu();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg + 4)),
      ),
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.lg),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.dongKeDam,
                  borderRadius: BorderRadius.circular(R.pill),
                ),
              ),
            ),
            const SizedBox(height: Gap.lg),
            TieuDeMuc('Xem thử vai trò nào?', eyebrow: 'Dữ liệu mẫu lớp 9A2'),
            const SizedBox(height: Gap.sm),
            Text(
              'Mọi thay đổi chỉ nằm trong bộ nhớ máy và mất khi tắt app. Đăng xuất là quay về màn đăng nhập thật.',
              style: AppType.ui(13, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.5),
            ),
            const SizedBox(height: Gap.lg),
            for (final vt in VaiTro.values) ...[
              _Hang(
                vaiTro: vt,
                moTa: switch (vt) {
                  VaiTro.phuHuynh =>
                    'Xem báo cáo hằng ngày, nhập thời khóa biểu, gửi nhắc nhở',
                  VaiTro.hocSinh =>
                    'Nhập thời khóa biểu, viết báo cáo, chụp ảnh bài làm',
                  VaiTro.quanTri => 'Quản lý tài khoản, môn học và thầy cô',
                },
                onTap: () async {
                  Navigator.of(context).pop();
                  await context.read<AppState>().dungThuVoiVaiTro(vt);
                },
              ),
              const SizedBox(height: Gap.sm + 2),
            ],
          ],
        ),
      ),
    );
  }
}

class _Hang extends StatelessWidget {
  const _Hang({required this.vaiTro, required this.moTa, required this.onTap});

  final VaiTro vaiTro;
  final String moTa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.giayTrang,
      borderRadius: BorderRadius.circular(R.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(R.md),
        child: Ink(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: AppColor.dongKe),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColor.sky,
                  borderRadius: BorderRadius.circular(R.sm),
                ),
                child: Icon(vaiTro.icon, color: AppColor.muc, size: 21),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vaiTro.nhan, style: AppType.ui(15, w: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(moTa,
                        style: AppType.ui(12,
                            color: AppColor.mucNhat, w: FontWeight.w400, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: Gap.sm),
              const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColor.mucNhat),
            ],
          ),
        ),
      ),
    );
  }
}
