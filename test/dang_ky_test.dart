import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:theodoi_hoctap/data/app_state.dart';
import 'package:theodoi_hoctap/data/repositories/mock_repository.dart';
import 'package:theodoi_hoctap/features/auth/dang_ky_screen.dart';

import 'tro_giup.dart';

void main() {
  testWidgets('tạo tài khoản xong thì màn đăng ký tự rút, có lời chào, và đã đăng nhập',
      (t) async {
    final s = AppState(MockRepository());
    await t.runAsync(() => cho(() => !s.dangKhoiTao, moTa: 'khởi tạo'));
    t.view.physicalSize = const Size(390, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(ChangeNotifierProvider.value(
      value: s,
      child: MaterialApp(
        home: Builder(
          builder: (c) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(c).push(
                  MaterialPageRoute(builder: (_) => const DangKyScreen()),
                ),
                child: const Text('màn đăng nhập'),
              ),
            ),
          ),
        ),
      ),
    ));
    await t.tap(find.text('màn đăng nhập'));
    await t.pumpAndSettle();
    expect(find.byType(DangKyScreen), findsOneWidget);

    // Phụ huynh là vai trò mặc định; điền bốn ô bắt buộc.
    Finder o(String hint) => find.widgetWithText(TextFormField, hint);
    await t.enterText(o('Nguyễn Văn Hùng'), 'Trần Thu Hà');
    await t.enterText(o('ten@email.com'), 'ha.tran@gmail.com');
    await t.enterText(o('Ít nhất 6 ký tự'), 'matkhau123');
    await t.enterText(find.byType(TextFormField).at(3), 'matkhau123');
    // "Tạo tài khoản" vừa là tiêu đề màn vừa là nhãn nút — lấy nút.
    final nut = find.widgetWithText(FilledButton, 'Tạo tài khoản');
    await t.ensureVisible(nut);
    await t.tap(nut);
    // Kho mẫu trả lời sau 180 ms giả lập, đăng ký rồi nạp dữ liệu là nhiều
    // nhịp như thế — đẩy đồng hồ giả qua hết.
    for (var i = 0; i < 12 && !s.daDangNhap; i++) {
      await t.pump(const Duration(milliseconds: 500));
    }
    await t.pumpAndSettle();

    expect(find.byType(DangKyScreen), findsNothing, reason: 'màn đăng ký phải rút đi');
    expect(find.textContaining('Chào Hà'), findsOneWidget);
    expect(s.nguoiDung?.hoTen, 'Trần Thu Hà');
  });
}
