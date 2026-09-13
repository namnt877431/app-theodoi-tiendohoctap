import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/core/widgets/khung_rong.dart';

void main() {
  Future<void> dung(WidgetTester t, Size man) async {
    t.view.physicalSize = man;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      builder: (_, child) => KhungRong(child: child!),
      home: Builder(
        builder: (context) => Text('rộng ${MediaQuery.sizeOf(context).width.round()}'),
      ),
    ));
  }

  testWidgets('màn rộng: nội dung đóng khung 680 ở giữa, MediaQuery báo đúng khung', (t) async {
    await dung(t, const Size(1400, 900));
    final o = t.getRect(find.byType(Text));
    expect(o.width, 680);
    expect(o.left, (1400 - 680) / 2);
    expect(find.text('rộng 680'), findsOneWidget);
  });

  testWidgets('màn điện thoại: để nguyên, không viền không khung', (t) async {
    await dung(t, const Size(390, 844));
    expect(t.getRect(find.byType(Text)).width, 390);
    expect(find.text('rộng 390'), findsOneWidget);
  });
}
