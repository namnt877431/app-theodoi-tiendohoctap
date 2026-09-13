import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:theodoi_hoctap/core/layout/bo_cuc.dart';
import 'package:theodoi_hoctap/core/layout/khung_dieu_huong.dart';
import 'package:theodoi_hoctap/data/app_state.dart';
import 'package:theodoi_hoctap/data/models/models.dart';

import 'tro_giup.dart';

void main() {
  group('Ngưỡng cỡ màn', () {
    test('điện thoại, máy tính bảng, máy tính', () {
      expect(BoCuc.coManTu(390), CoMan.hep);
      expect(BoCuc.coManTu(719), CoMan.hep);
      expect(BoCuc.coManTu(720), CoMan.vua);
      expect(BoCuc.coManTu(1099), CoMan.vua);
      expect(BoCuc.coManTu(1100), CoMan.rong);
    });

    test('lề canh giữa: thừa chỗ thì đẩy vào, không thì giữ lề tối thiểu', () {
      expect(BoCuc.leCanhGiua(390, 16), 16);
      expect(BoCuc.leCanhGiua(1600, 24, toiDa: 1200), 200);
      expect(BoCuc.leCanhGiua(1230, 24, toiDa: 1200), 24);
    });

    test('số cột của lưới thẻ theo bề ngang', () {
      expect(LuoiThe.soCot(390), 1);
      expect(LuoiThe.soCot(810), 2);
      expect(LuoiThe.soCot(1230), 3);
      expect(LuoiThe.soCot(2000), 3, reason: 'không quá ba cột');
      expect(LuoiThe.soCot(2000, toiDaCot: 2), 2);
    });
  });

  group('Hai cột', () {
    Future<void> dung(WidgetTester t, double rong, {Widget? hep}) async {
      t.view.physicalSize = Size(rong, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HaiCot(
            trai: const Text('trái'),
            phai: const Text('phải'),
            hep: hep,
          ),
        ),
      ));
    }

    testWidgets('rộng thì hai cột cạnh nhau, trái rộng hơn phải', (t) async {
      await dung(t, 1200);
      final trai = t.getRect(find.text('trái'));
      final phai = t.getRect(find.text('phải'));
      expect(trai.top, phai.top);
      expect(phai.left, greaterThan(trai.left));
      // Hộp của cột trái (Expanded flex 3) rộng hơn cột phải (flex 2).
      final hop = t.widgetList<Expanded>(find.byType(Expanded)).toList();
      expect(hop.map((e) => e.flex), [3, 2]);
    });

    testWidgets('hẹp thì xếp dọc', (t) async {
      await dung(t, 390);
      final trai = t.getRect(find.text('trái'));
      final phai = t.getRect(find.text('phải'));
      expect(trai.left, phai.left);
      expect(phai.top, greaterThan(trai.top));
    });

    testWidgets('hẹp mà có bố cục riêng thì dùng bố cục đó', (t) async {
      await dung(t, 390, hep: const Text('riêng cho điện thoại'));
      expect(find.text('riêng cho điện thoại'), findsOneWidget);
      expect(find.text('trái'), findsNothing);
    });
  });

  group('Lưới thẻ', () {
    testWidgets('bốn thẻ, đủ chỗ hai cột thì thành hai hàng', (t) async {
      t.view.physicalSize = const Size(900, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LuoiThe(children: [for (var i = 0; i < 4; i++) Text('thẻ $i')]),
        ),
      ));
      expect(t.getRect(find.text('thẻ 0')).top, t.getRect(find.text('thẻ 1')).top);
      expect(t.getRect(find.text('thẻ 2')).top, greaterThan(t.getRect(find.text('thẻ 0')).top));
      expect(t.getRect(find.text('thẻ 2')).left, t.getRect(find.text('thẻ 0')).left);
    });
  });

  group('Khung điều hướng', () {
    Future<AppState> dung(WidgetTester t, double rong) async {
      // Đăng nhập mẫu chạy bằng đồng hồ thật — trong testWidgets đồng hồ là
      // giả, Future.delayed không bao giờ tới.
      final s = (await t.runAsync(() => vaoVoiVaiTro(VaiTro.hocSinh)))!;
      t.view.physicalSize = Size(rong, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(ChangeNotifierProvider.value(
        value: s,
        child: MaterialApp(
          home: KhungDieuHuong(
            tab: 0,
            onChon: (_) {},
            hanhDong: HanhDongChinh(icon: Icons.edit, nhan: 'Viết báo cáo', onTap: () {}),
            diemDen: const [
              DiemDen(icon: Icons.today_outlined, iconChon: Icons.today, nhan: 'Hôm nay'),
              DiemDen(icon: Icons.person_outline, iconChon: Icons.person, nhan: 'Tài khoản'),
            ],
            man: const [Text('màn một'), Text('màn hai')],
          ),
        ),
      ));
      await t.pump();
      return s;
    }

    testWidgets('điện thoại: thanh dưới và nút nổi', (t) async {
      await dung(t, 390);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Sổ liên lạc'), findsNothing);
    });

    testWidgets('máy tính: thanh bên đủ chữ, tên người dùng, nút hành động; không có thanh dưới', (t) async {
      final s = await dung(t, 1400);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Sổ liên lạc'), findsOneWidget);
      expect(find.text('Hôm nay'), findsOneWidget);
      expect(find.text('Viết báo cáo'), findsOneWidget);
      expect(find.text(s.nguoiDung!.hoTen), findsOneWidget);
      // Nội dung đứng bên phải thanh bên.
      expect(t.getRect(find.text('màn một')).left, greaterThan(200));
    });

    testWidgets('cửa sổ vừa: thanh bên gọn, chỉ biểu tượng và nhãn nhỏ', (t) async {
      await dung(t, 800);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Sổ liên lạc'), findsNothing);
      expect(find.text('Hôm nay'), findsOneWidget);
      expect(t.getRect(find.text('màn một')).left, lessThan(120));
    });
  });
}
