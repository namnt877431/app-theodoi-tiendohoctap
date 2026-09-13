import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/bo_cuc.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../data/app_state.dart';
import '../shared/danh_sach_bao_cao.dart';

/// Toàn bộ báo cáo của con, lọc theo hạng mục, thầy cô và trạng thái.
class BaoCaoPhScreen extends StatelessWidget {
  const BaoCaoPhScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hs = context.select<AppState, String?>((s) => s.hocSinhHienTai?.hoTen);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            LeTrang(
              tren: Gap.md,
              duoi: Gap.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Báo cáo học tập', style: AppType.display(24)),
                  if (hs != null) ...[
                    const SizedBox(height: 2),
                    Text(hs,
                        style: AppType.ui(13, color: AppColor.mucNhat, w: FontWeight.w500)),
                  ],
                ],
              ),
            ),
            const Expanded(child: DanhSachBaoCao()),
          ],
        ),
      ),
    );
  }
}
