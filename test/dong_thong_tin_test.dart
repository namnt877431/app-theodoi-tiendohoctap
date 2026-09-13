import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/core/theme/tokens.dart';
import 'package:theodoi_hoctap/core/widgets/common.dart';

/// Dựng đúng cái khung mà màn hình Tài khoản dùng: trang giấy trắng, lề
/// ngang Gap.lg, nằm trong trang có lề 20 mỗi bên.
Future<void> dung(WidgetTester t, String nhan, String giaTri,
    {double rongMan = 360}) async {
  t.view.physicalSize = Size(rongMan, 800);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);

  await t.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [DongThongTin(Icons.school_outlined, nhan, giaTri)],
          ),
        ),
      ),
    ),
  ));
}

/// Đếm số dòng chữ đã xuống. AppType.ui dùng height 1.4, nên một dòng của cỡ
/// 13.5 cao 18.9 — chia chiều cao đo được cho con số đó là ra.
int soDong(WidgetTester t, String chu) =>
    (t.getSize(find.text(chu)).height / (13.5 * 1.4)).round();

void main() {
  group('Dòng thông tin', () {
    // Lỗi thật đã gặp: Spacer và Flexible cùng flex 1 nên chia đôi chỗ trống,
    // giá trị chỉ được nửa bề ngang và xuống dòng dù còn thừa chỗ.
    //
    // Font trong test là font giả, mỗi chữ rộng đúng bằng cỡ chữ — gấp đôi
    // font thật — nên không đo "vừa một dòng" được. Đo thẳng cái bất biến:
    // giá trị phải được trọn phần còn lại sau nhãn, không phải một nửa.
    testWidgets('giá trị được trọn bề ngang còn lại sau nhãn', (t) async {
      await dung(t, 'Trường', 'THCS Phan Chu Trinh');
      final nhan = t.getRect(find.text('Trường'));
      final gia = t.getRect(find.text('THCS Phan Chu Trinh'));
      final mepPhai = 360 - 20 - Gap.lg;
      expect(gia.left, closeTo(nhan.right + Gap.md, 0.5));
      expect(gia.right, closeTo(mepPhai, 0.5));
    });

    testWidgets('nhãn và giá trị nằm trên cùng một hàng', (t) async {
      await dung(t, 'Trường', 'THCS Phan Chu Trinh');
      expect(t.getTopLeft(find.text('Trường')).dy,
          t.getTopLeft(find.text('THCS Phan Chu Trinh')).dy);
    });

    testWidgets('giá trị được căn sát mép phải', (t) async {
      await dung(t, 'Lớp', '8A');
      // Mép phải của khung nội dung: 360 - 20 lề trang - Gap.lg lề thẻ.
      expect(t.getBottomRight(find.text('8A')).dx,
          closeTo(360 - 20 - Gap.lg, 0.5));
    });

    testWidgets('giá trị quá dài thì xuống dòng, nhãn vẫn bám dòng đầu',
        (t) async {
      const dai = 'Trường Trung học cơ sở Nguyễn Thị Minh Khai, Buôn Ma Thuột';
      await dung(t, 'Trường', dai);
      expect(soDong(t, dai), greaterThan(1));
      expect(t.getTopLeft(find.text('Trường')).dy,
          t.getTopLeft(find.text(dai)).dy);
    });
  });
}
