import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../data/app_state.dart';
import '../shared/danh_sach_bao_cao.dart';

/// Học sinh xem lại những gì mình đã báo cáo, lọc theo hạng mục và trạng thái.
class LichSuBaoCaoScreen extends StatelessWidget {
  const LichSuBaoCaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tong = context.select<AppState, int>((s) => s.baoCao.length);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Báo cáo của tôi', style: AppType.display(24)),
                  const SizedBox(height: 2),
                  Text('$tong mục đã gửi',
                      style: AppType.ui(13, color: AppColor.mucNhat, w: FontWeight.w500)),
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
