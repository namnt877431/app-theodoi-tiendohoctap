import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/core/huy_hieu/huy_hieu.dart';
import 'package:theodoi_hoctap/core/widgets/con_dau.dart';

/// Con dấu từng bị nở ra bằng cả màn hình khi đặt trong Wrap và ListView
/// ngang — CustomPaint có child thì lấy cỡ của child, không phải `size`.
/// Test này đo cỡ thật của phần vẽ ở đúng hai chỗ đó.
void main() {
  final tienDo = [
    TienDoHuyHieu(danhSachHuyHieu[0], 0), // chưa đạt
    TienDoHuyHieu(danhSachHuyHieu[3], 30), // đạt, mực vàng
  ];

  // Material của Scaffold cũng là một CustomPaint — chỉ lấy cái nằm trong
  // con dấu thứ `thu`.
  Size coVe(WidgetTester t, int thu) => t.getSize(find
      .descendant(of: find.byType(ConDau).at(thu), matching: find.byType(CustomPaint))
      .first);

  testWidgets('trong Wrap, phần vẽ đúng bằng kích thước khai báo', (t) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Wrap(children: [for (final td in tienDo) ConDau(td, kichThuoc: 68)]),
      ),
    ));

    for (var i = 0; i < tienDo.length; i++) {
      expect(coVe(t, i), const Size(68, 68), reason: 'con dấu thứ $i');
    }
  });

  testWidgets('trong ListView ngang cũng vậy', (t) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [for (final td in tienDo) ConDau(td, kichThuoc: 66, coTienDo: true)],
          ),
        ),
      ),
    ));

    expect(coVe(t, 0), const Size(66, 66));
    // Chưa đạt thì có dòng tiến độ, đã đạt thì không.
    expect(find.text('0/3 ngày'), findsOneWidget);
    expect(find.text('30/30 ngày'), findsNothing);
  });
}
