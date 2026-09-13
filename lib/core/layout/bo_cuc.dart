import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Ba cỡ màn hình app phân biệt. Điện thoại là [hep]; máy tính bảng và cửa
/// sổ trình duyệt vừa là [vua] — thanh điều hướng dọc bên trái, nội dung
/// giới hạn bề ngang; máy tính là [rong] — thêm cột thứ hai.
enum CoMan { hep, vua, rong }

abstract final class BoCuc {
  /// Từ bề rộng này trở lên thanh điều hướng đứng bên trái thay vì nằm dưới.
  static const vua = 720.0;

  /// Từ bề rộng này trở lên nội dung xếp hai cột.
  static const rong = 1100.0;

  /// Từ bề rộng này thanh bên hiện đủ chữ; hẹp hơn thì chỉ biểu tượng.
  static const thanhBenDayDu = 1000.0;

  /// Bề rộng lớn nhất của phần nội dung — dài hơn nữa mắt phải đảo nhiều.
  static const noiDungToiDa = 1200.0;

  static CoMan coManTu(double rong) =>
      rong >= BoCuc.rong ? CoMan.rong : rong >= vua ? CoMan.vua : CoMan.hep;

  /// Cỡ của cả cửa sổ — dùng để quyết định thanh điều hướng.
  static CoMan coMan(BuildContext context) => coManTu(MediaQuery.sizeOf(context).width);

  static bool coThanhBen(BuildContext context) => coMan(context) != CoMan.hep;

  /// Lề ngang của trang theo cỡ màn.
  static double le(BuildContext context) => coMan(context) == CoMan.hep ? Gap.lg : Gap.xl;

  /// Lề ngang để nội dung trong một danh sách cuộn được canh giữa và không
  /// rộng quá [toiDa] — dùng làm padding của ListView khi không bọc được
  /// bằng [NoiDung] (ListView cần chiều cao có giới hạn).
  static double leCanhGiua(double rongCoSan, double leToiThieu, {double toiDa = noiDungToiDa}) {
    final thua = (rongCoSan - toiDa) / 2;
    return thua > leToiThieu ? thua : leToiThieu;
  }
}

/// Giới hạn bề ngang nội dung và đặt vào giữa trên màn rộng. Trên điện thoại
/// không thay đổi gì.
class NoiDung extends StatelessWidget {
  const NoiDung({super.key, required this.child, this.toiDa = BoCuc.noiDungToiDa});

  final Widget child;
  final double toiDa;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: toiDa),
          child: child,
        ),
      );
}

/// Hai cột khi có chỗ, một cột khi không. Quyết định theo bề ngang thật
/// được cấp cho widget (không phải cả cửa sổ) — vì trong khung có thanh bên
/// thì phần nội dung hẹp hơn cửa sổ.
class HaiCot extends StatelessWidget {
  const HaiCot({
    super.key,
    required this.trai,
    required this.phai,
    this.tiLeTrai = 3,
    this.tiLePhai = 2,
    this.khe = Gap.xl,
    this.nguong = BoCuc.rong - 260,
    this.hep,
  });

  final Widget trai;
  final Widget phai;

  /// Bố cục khi không đủ chỗ. Không cho thì xếp [trai] rồi [phai] theo cột;
  /// cho khi thứ tự đọc trên điện thoại khác thứ tự hai cột.
  final Widget? hep;
  final int tiLeTrai;
  final int tiLePhai;
  final double khe;

  /// Bề ngang từ đó tách hai cột. Mặc định bằng ngưỡng màn rộng trừ đi thanh
  /// bên, để trên máy tính cột tách đúng lúc thanh bên vừa hiện đủ chữ.
  final double nguong;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, rang) {
          if (rang.maxWidth < nguong) {
            if (hep != null) return hep!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [trai, SizedBox(height: khe), phai],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: tiLeTrai, child: trai),
              SizedBox(width: khe),
              Expanded(flex: tiLePhai, child: phai),
            ],
          );
        },
      );
}

/// Xếp các thẻ thành lưới nhiều cột khi có chỗ: cột nào cũng rộng ít nhất
/// [rongToiThieu], không đủ chỗ cho hai cột thì xếp dọc như điện thoại.
/// Dùng trong ListView có sẵn (không phải GridView) nên vẫn trộn được với
/// tiêu đề ngày, chú thích… ở giữa.
class LuoiThe extends StatelessWidget {
  const LuoiThe({
    super.key,
    required this.children,
    this.rongToiThieu = 400,
    this.khe = Gap.sm + 2,
    this.toiDaCot = 3,
  });

  final List<Widget> children;
  final double rongToiThieu;
  final double khe;
  final int toiDaCot;

  static int soCot(double rong, {double rongToiThieu = 400, double khe = Gap.sm + 2, int toiDaCot = 3}) =>
      ((rong + khe) ~/ (rongToiThieu + khe)).clamp(1, toiDaCot);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, rang) {
          final cot = soCot(rang.maxWidth, rongToiThieu: rongToiThieu, khe: khe, toiDaCot: toiDaCot);
          final hang = <Widget>[];
          for (var i = 0; i < children.length; i += cot) {
            final o = <Widget>[];
            for (var j = 0; j < cot; j++) {
              if (j > 0) o.add(SizedBox(width: khe));
              o.add(Expanded(
                child: i + j < children.length ? children[i + j] : const SizedBox.shrink(),
              ));
            }
            hang.add(IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: o),
            ));
            if (i + cot < children.length) hang.add(SizedBox(height: khe));
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: hang);
        },
      );
}

/// Lề ngang cho một khối nằm ngoài danh sách cuộn (tiêu đề trang, thanh
/// lọc) — cùng lề với nội dung canh giữa bên dưới để hai thứ thẳng hàng.
class LeTrang extends StatelessWidget {
  const LeTrang({super.key, required this.child, this.tren = 0, this.duoi = 0});

  final Widget child;
  final double tren;
  final double duoi;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, rang) {
          final le = BoCuc.leCanhGiua(rang.maxWidth, BoCuc.le(context));
          return Padding(padding: EdgeInsets.fromLTRB(le, tren, le, duoi), child: child);
        },
      );
}
