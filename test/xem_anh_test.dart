import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:theodoi_hoctap/data/models/models.dart';
import 'package:theodoi_hoctap/features/shared/anh_bai_lam.dart';
import 'package:theodoi_hoctap/features/shared/chi_tiet_bao_cao_screen.dart';

import 'tro_giup.dart';

void main() {
  group('Xem ảnh lớn', () {
    testWidgets('chạm ô ảnh ở chi tiết là mở cả màn hình, vuốt qua tấm sau, đóng được',
        (t) async {
      final s = (await t.runAsync(() => vaoVoiVaiTro(VaiTro.phuHuynh)))!;
      // Dữ liệu mẫu có một bài học thêm Toán kèm hai ảnh.
      final bc = s.baoCao.firstWhere((b) => b.anh.length == 2);
      t.view.physicalSize = const Size(390, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(ChangeNotifierProvider.value(
        value: s,
        child: MaterialApp(home: ChiTietBaoCaoScreen(baoCaoId: bc.id)),
      ));
      await t.pump();

      await t.ensureVisible(find.byType(AnhBaiLam).first);
      await t.tap(find.byType(AnhBaiLam).first);
      await t.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);

      // Chưa phóng to thì kéo ngang là lật trang.
      await t.fling(find.byType(PageView), const Offset(-300, 0), 1200);
      await t.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);

      await t.tap(find.byTooltip('Đóng'));
      await t.pumpAndSettle();
      expect(find.byType(PageView), findsNothing);
      expect(find.byType(AnhBaiLam), findsWidgets);
    });

    testWidgets('mở thẳng tấm thứ hai thì đếm từ 2/2; một tấm thì không có bộ đếm', (t) async {
      final s = (await t.runAsync(() => vaoVoiVaiTro(VaiTro.hocSinh)))!;
      t.view.physicalSize = const Size(390, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      late BuildContext ctx;
      await t.pumpWidget(ChangeNotifierProvider.value(
        value: s,
        child: MaterialApp(
          home: Builder(builder: (c) {
            ctx = c;
            return const Scaffold(body: SizedBox());
          }),
        ),
      ));

      moXemAnh(ctx, duongDan: const ['demo:a', 'demo:b'], batDau: 1);
      await t.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);
      Navigator.of(ctx).pop();
      await t.pumpAndSettle();

      moXemAnh(ctx, duongDan: const ['demo:a']);
      await t.pumpAndSettle();
      expect(find.textContaining('/'), findsNothing);
      expect(find.byTooltip('Đóng'), findsOneWidget);
    });
  });
}
